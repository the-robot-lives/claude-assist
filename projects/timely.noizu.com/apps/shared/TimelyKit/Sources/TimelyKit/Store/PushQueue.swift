import Foundation

/// A mutation waiting to be pushed.
///
/// `mutationID` is minted **at enqueue time**, not at send time. That is the
/// whole idempotency story: a mutation that is sent, applied by the server, and
/// then lost to a dropped connection is retried with the *same* id, and the
/// server replays the original result instead of applying it twice. Minting the
/// id in the sender would make every retry a new write.
public struct QueuedMutation: Sendable, Hashable, Identifiable {

    /// Local queue position. Monotonic, never reused.
    public let seq: Int64

    /// The server's idempotency key. Client-minted UUIDv7.
    public let mutationID: UUID

    public let workspaceID: UUID
    public let entityKind: EntityKind
    public let entityID: UUID
    public let operation: MutationOperation

    /// The `server_revision` the client believed current when it composed this.
    /// Null for a row the server has never seen. Decisive for the closed-span
    /// reopen guard and for locked days.
    public let baseRevision: Int64?

    public let payload: JSONValue
    public let createdAt: Date
    public let attempts: Int
    public let lastAttempt: Date?
    public let lastError: String?

    /// Non-nil marks this mutation as part of an atomic group — a split or a
    /// merge, which must be sent together with `atomic: true` or not at all.
    public let batchGroup: String?

    public var id: Int64 { seq }
}

public extension TimelyLocalStore {

    // MARK: - Enqueue

    /// Record a local mutation for eventual push, and apply it to local state.
    ///
    /// This is the **only** write path a UI should use. It never touches the
    /// network and never inspects the auth state, so it works identically with
    /// a fresh token, an expired token, and no token at all.
    /// - Parameter deliberateClears: Wire keys the user genuinely emptied in
    ///   this edit — `end` for a reopen, `locked_at` for clearing an approval
    ///   lock. Those are sent as explicit nulls because the server reads
    ///   present-and-null as the *instruction* to do it; every other nil
    ///   presence-sensitive key is omitted so the server leaves the field alone.
    ///   See ``WirePresence``.
    ///
    ///   Defaulting to empty means a direct caller omits rather than asserts,
    ///   which is the safe direction: the worst case is a clear that does not
    ///   take and can be retried, instead of a reopen or an unlocked approved
    ///   day that nobody asked for. ``recordLocalChange(_:entity:deviceID:batchGroup:at:)``
    ///   computes it properly and is the path a UI should use.
    @discardableResult
    func enqueue<E: SyncEntity>(
        _ operation: MutationOperation,
        entity: E,
        batchGroup: String? = nil,
        deliberateClears: Set<String> = [],
        at now: Date = Date()
    ) throws -> QueuedMutation {
        // Append-only kinds reject `update` server-side with `immutable_entity`
        // (§8 rows 14, 15). Enqueuing one would burn a retry cycle to learn
        // something knowable here.
        if operation == .update, E.kind.isAppendOnly {
            throw SyncError.immutableEntity(kind: E.kind)
        }

        let mutationID = UUID.v7(at: now)

        // The encoder emits every key, including explicit nulls — that is
        // correct and required for `deleted_at`, `ticket_id` and
        // `origin_device_id`. `WirePresence` then removes only the two keys
        // whose absence the server reads as "leave this alone".
        //
        // DO NOT replace this with `encodeIfPresent` in the encoder. That drops
        // the nullable-and-required fields too and produces bodies that fail the
        // contract's schema. The narrowness is the whole point.
        let payload = WirePresence.apply(
            to: try JSONValue.encoding(entity),
            kind: E.kind,
            nilKeys: WirePresence.nilKeys(of: entity),
            deliberateClears: deliberateClears
        )
        // A row the server has never acknowledged has no base revision to cite.
        let baseRevision: Int64? = entity.sync.serverRevision == 0
            ? nil
            : entity.sync.serverRevision

        return try withConnection { connection in
            try connection.transaction {
                try connection.run(
                    """
                    INSERT INTO push_queue
                        (mutation_id, workspace_id, entity_kind, entity_id, operation,
                         base_revision, payload, created_at, batch_group)
                    VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
                    """,
                    [
                        .uuid(mutationID),
                        .uuid(entity.sync.workspaceID),
                        .text(E.kind.rawValue),
                        .uuid(entity.sync.id),
                        .text(operation.rawValue),
                        baseRevision.map { SQLiteValue.integer($0) } ?? .null,
                        .text(try TimelyJSON.encodeToString(payload)),
                        .date(now),
                        .text(batchGroup)
                    ]
                )

                let seq = connection.lastInsertRowID
                return QueuedMutation(
                    seq: seq,
                    mutationID: mutationID,
                    workspaceID: entity.sync.workspaceID,
                    entityKind: E.kind,
                    entityID: entity.sync.id,
                    operation: operation,
                    baseRevision: baseRevision,
                    payload: payload,
                    createdAt: now,
                    attempts: 0,
                    lastAttempt: nil,
                    lastError: nil,
                    batchGroup: batchGroup
                )
            }
        }
    }

    /// Apply a local edit and queue it, in one transaction.
    ///
    /// The two must be atomic. A local write that lands without its queue entry
    /// is a silent data loss on the next pull, which overwrites it with the
    /// server's older copy and leaves no trace that the user's edit existed.
    @discardableResult
    func recordLocalChange<E: SyncEntity>(
        _ operation: MutationOperation,
        entity: E,
        deviceID: UUID?,
        batchGroup: String? = nil,
        at now: Date = Date()
    ) throws -> (entity: E, mutation: QueuedMutation) {
        var updated = entity
        if operation == .delete {
            updated.tombstone(deviceID: deviceID, at: now)
        } else {
            updated.touch(deviceID: deviceID, at: now)
        }

        // Read the stored row *before* the upsert overwrites it. This is the
        // only moment the store can tell "the user just reopened this span"
        // apart from "this span was already open" — after the write, both look
        // identical. See ``WirePresence``.
        let prior = try fetch(E.self, id: updated.sync.id)
        let clears = WirePresence.deliberateClears(prior: prior, updated: updated)

        try upsert(updated, markDirty: true)
        let mutation = try enqueue(
            operation,
            entity: updated,
            batchGroup: batchGroup,
            deliberateClears: clears,
            at: now
        )
        return (updated, mutation)
    }

    // MARK: - Dequeue

    /// The next batch to send, in strict FIFO order.
    ///
    /// Capped at `limit`, and never larger than the contract's 200. An atomic
    /// group is never split across batches: if the head of the queue is part of
    /// one, the whole group is returned alone.
    func nextBatch(workspaceID: UUID, limit: Int = 100) throws -> [QueuedMutation] {
        let capped = min(max(limit, 1), 200)

        let head = try loadQueue(
            workspaceID: workspaceID,
            sql: "SELECT \(Self.queueColumns) FROM push_queue WHERE workspace_id = ?1 "
               + "ORDER BY seq LIMIT ?2",
            bindings: [.uuid(workspaceID), .integer(capped)]
        )

        guard let first = head.first else { return [] }

        if let group = first.batchGroup {
            // Atomic groups are all-or-nothing server-side, capped at 50.
            return try loadQueue(
                workspaceID: workspaceID,
                sql: "SELECT \(Self.queueColumns) FROM push_queue "
                   + "WHERE workspace_id = ?1 AND batch_group = ?2 ORDER BY seq LIMIT 50",
                bindings: [.uuid(workspaceID), .text(group)]
            )
        }

        // Stop the batch at the first member of an atomic group, so the group
        // gets a batch of its own on the next pass.
        return Array(head.prefix { $0.batchGroup == nil })
    }

    func queueDepth(workspaceID: UUID) throws -> Int {
        try withConnection { connection in
            try connection.query(
                "SELECT COUNT(*) FROM push_queue WHERE workspace_id = ?1",
                [.uuid(workspaceID)]
            ) { Int($0.int(0)) }.first ?? 0
        }
    }

    /// Remove terminal mutations from the queue. All three contract statuses —
    /// `applied`, `conflict`, `rejected` — are terminal; only transport
    /// failures are retried.
    func dequeue(_ mutationIDs: [UUID]) throws {
        guard !mutationIDs.isEmpty else { return }
        try withConnection { connection in
            try connection.transaction {
                for id in mutationIDs {
                    try connection.run(
                        "DELETE FROM push_queue WHERE mutation_id = ?1", [.uuid(id)]
                    )
                }
            }
        }
    }

    /// Record a transport-level failure. The mutation stays queued and keeps
    /// its id, so the retry is a replay rather than a new write.
    func recordAttemptFailure(
        _ mutationIDs: [UUID],
        error: String,
        at now: Date = Date()
    ) throws {
        guard !mutationIDs.isEmpty else { return }
        try withConnection { connection in
            try connection.transaction {
                for id in mutationIDs {
                    try connection.run(
                        """
                        UPDATE push_queue
                           SET attempts = attempts + 1, last_attempt = ?2, last_error = ?3
                         WHERE mutation_id = ?1
                        """,
                        [.uuid(id), .date(now), .text(error)]
                    )
                }
            }
        }
    }

    /// Clear the dirty flag on rows the server has now acknowledged.
    func clearDirty(kind: EntityKind, ids: [UUID]) throws {
        guard !ids.isEmpty else { return }
        try withConnection { connection in
            try connection.transaction {
                for id in ids {
                    try connection.run(
                        "UPDATE entities SET dirty = 0 WHERE kind = ?1 AND id = ?2",
                        [.text(kind.rawValue), .uuid(id)]
                    )
                }
            }
        }
    }

    // MARK: - Sync cursor

    func syncState(workspaceID: UUID) throws -> SyncCursorState {
        try withConnection { connection in
            try connection.query(
                """
                SELECT cursor, tombstone_horizon_revision, last_pull_at, last_push_at, last_server_time
                FROM sync_state WHERE workspace_id = ?1
                """,
                [.uuid(workspaceID)]
            ) { row in
                SyncCursorState(
                    workspaceID: workspaceID,
                    cursor: row.int(0),
                    tombstoneHorizonRevision: row.int(1),
                    lastPullAt: row.date(2),
                    lastPushAt: row.date(3),
                    lastServerTime: row.date(4)
                )
            }.first ?? SyncCursorState(workspaceID: workspaceID)
        }
    }

    func saveSyncState(_ state: SyncCursorState) throws {
        try withConnection { connection in
            try connection.run(
                """
                INSERT INTO sync_state
                    (workspace_id, cursor, tombstone_horizon_revision,
                     last_pull_at, last_push_at, last_server_time)
                VALUES (?1, ?2, ?3, ?4, ?5, ?6)
                ON CONFLICT(workspace_id) DO UPDATE SET
                    cursor                     = excluded.cursor,
                    tombstone_horizon_revision = excluded.tombstone_horizon_revision,
                    last_pull_at               = excluded.last_pull_at,
                    last_push_at               = excluded.last_push_at,
                    last_server_time           = excluded.last_server_time
                """,
                [
                    .uuid(state.workspaceID),
                    .integer(state.cursor),
                    .integer(state.tombstoneHorizonRevision),
                    .date(state.lastPullAt),
                    .date(state.lastPushAt),
                    .date(state.lastServerTime)
                ]
            )
        }
    }

    // MARK: - Outcomes needing a human

    /// Park a conflict or rejection for the UI.
    ///
    /// Nothing in this package resolves a `suspected_duplicate` or a
    /// `billing_overlap`. Both mean "two records claim the same time"; picking
    /// one automatically either invents or destroys billable hours, and the
    /// person who can tell which is the person who did the work.
    func recordOutcome(_ outcome: PendingOutcome) throws {
        try withConnection { connection in
            try connection.run(
                """
                INSERT INTO pending_outcomes
                    (mutation_id, workspace_id, entity_kind, entity_id, status,
                     reason, message, recorded_at, acknowledged, detail)
                VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, 0, ?9)
                ON CONFLICT(mutation_id) DO UPDATE SET
                    status       = excluded.status,
                    reason       = excluded.reason,
                    message      = excluded.message,
                    recorded_at  = excluded.recorded_at,
                    detail       = excluded.detail
                """,
                [
                    .uuid(outcome.mutationID),
                    .uuid(outcome.workspaceID),
                    .text(outcome.entityKind.rawValue),
                    .uuid(outcome.entityID),
                    .text(outcome.status.rawValue),
                    .text(outcome.reason?.rawValue),
                    .text(outcome.message),
                    .date(outcome.recordedAt),
                    .text(try TimelyJSON.encodeToString(outcome.detail))
                ]
            )
        }
    }

    /// Conflicts and rejections a human has not yet dismissed.
    func pendingOutcomes(workspaceID: UUID, includeAcknowledged: Bool = false) throws -> [PendingOutcome] {
        var sql = """
            SELECT mutation_id, workspace_id, entity_kind, entity_id, status,
                   reason, message, recorded_at, acknowledged, detail
            FROM pending_outcomes WHERE workspace_id = ?1
            """
        if !includeAcknowledged { sql += " AND acknowledged = 0" }
        sql += " ORDER BY recorded_at DESC"

        return try withConnection { connection in
            try connection.query(sql, [.uuid(workspaceID)]) { row in
                PendingOutcome(
                    mutationID: row.uuid(0) ?? UUID(),
                    workspaceID: row.uuid(1) ?? workspaceID,
                    entityKind: EntityKind(rawValue: row.string(2)) ?? .unknown,
                    entityID: row.uuid(3) ?? UUID(),
                    status: MutationStatus(rawValue: row.string(4)) ?? .rejected,
                    reason: row.optionalString(5).flatMap(MutationReason.init(rawValue:)),
                    message: row.optionalString(6),
                    recordedAt: row.date(7) ?? Date(),
                    acknowledged: row.bool(8),
                    detail: (try? TimelyJSON.decode(JSONValue.self, from: row.string(9))) ?? .null
                )
            }
        }
    }

    /// Dismiss an outcome. A user decision, never an automatic one.
    func acknowledgeOutcome(mutationID: UUID) throws {
        try withConnection { connection in
            try connection.run(
                "UPDATE pending_outcomes SET acknowledged = 1 WHERE mutation_id = ?1",
                [.uuid(mutationID)]
            )
        }
    }

    // MARK: - Queue loading

    private static let queueColumns = """
        seq, mutation_id, workspace_id, entity_kind, entity_id, operation,
        base_revision, payload, created_at, attempts, last_attempt, last_error, batch_group
        """

    private func loadQueue(
        workspaceID: UUID,
        sql: String,
        bindings: [SQLiteValue]
    ) throws -> [QueuedMutation] {
        try withConnection { connection in
            try connection.query(sql, bindings) { row in
                QueuedMutation(
                    seq: row.int(0),
                    mutationID: row.uuid(1) ?? UUID(),
                    workspaceID: row.uuid(2) ?? workspaceID,
                    entityKind: EntityKind(rawValue: row.string(3)) ?? .unknown,
                    entityID: row.uuid(4) ?? UUID(),
                    operation: MutationOperation(rawValue: row.string(5)) ?? .update,
                    baseRevision: row.isNull(6) ? nil : row.int(6),
                    payload: (try? TimelyJSON.decode(JSONValue.self, from: row.string(7))) ?? .null,
                    createdAt: row.date(8) ?? Date(),
                    attempts: Int(row.int(9)),
                    lastAttempt: row.date(10),
                    lastError: row.optionalString(11),
                    batchGroup: row.optionalString(12)
                )
            }
        }
    }
}

// MARK: - Supporting types

public struct SyncCursorState: Sendable, Hashable {
    public let workspaceID: UUID

    /// The pull watermark. Everything at or below this revision is already in
    /// the local store.
    public var cursor: Int64

    /// Below this, the server no longer guarantees tombstones are present. A
    /// client whose cursor falls under it must re-bootstrap from 0 or it will
    /// keep rows the workspace has deleted.
    public var tombstoneHorizonRevision: Int64

    public var lastPullAt: Date?
    public var lastPushAt: Date?
    public var lastServerTime: Date?

    public init(
        workspaceID: UUID,
        cursor: Int64 = 0,
        tombstoneHorizonRevision: Int64 = 0,
        lastPullAt: Date? = nil,
        lastPushAt: Date? = nil,
        lastServerTime: Date? = nil
    ) {
        self.workspaceID = workspaceID
        self.cursor = cursor
        self.tombstoneHorizonRevision = tombstoneHorizonRevision
        self.lastPullAt = lastPullAt
        self.lastPushAt = lastPushAt
        self.lastServerTime = lastServerTime
    }

    /// True when this client has fallen behind the tombstone horizon and its
    /// incremental cursor can no longer be trusted.
    public var needsRebootstrap: Bool {
        cursor > 0 && cursor < tombstoneHorizonRevision
    }
}

/// A conflict or rejection parked for a human.
public struct PendingOutcome: Sendable, Hashable, Identifiable {
    public let mutationID: UUID
    public let workspaceID: UUID
    public let entityKind: EntityKind
    public let entityID: UUID
    public let status: MutationStatus
    public let reason: MutationReason?
    public let message: String?
    public let recordedAt: Date
    public var acknowledged: Bool
    public let detail: JSONValue

    public var id: UUID { mutationID }

    public init(
        mutationID: UUID,
        workspaceID: UUID,
        entityKind: EntityKind,
        entityID: UUID,
        status: MutationStatus,
        reason: MutationReason?,
        message: String?,
        recordedAt: Date,
        acknowledged: Bool = false,
        detail: JSONValue = .null
    ) {
        self.mutationID = mutationID
        self.workspaceID = workspaceID
        self.entityKind = entityKind
        self.entityID = entityID
        self.status = status
        self.reason = reason
        self.message = message
        self.recordedAt = recordedAt
        self.acknowledged = acknowledged
        self.detail = detail
    }

    /// True when this outcome needs a person, not a retry. Both cases mean two
    /// records claim the same hours.
    public var requiresHumanJudgement: Bool {
        reason == .duplicateName
            || detail["review_reasons"] != nil
            || status == .conflict
    }
}
