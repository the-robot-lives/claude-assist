import Foundation

/// The reconciliation loop between ``TimelyLocalStore`` and the server.
///
/// Four properties this type is responsible for, in the order they matter:
///
/// 1. **The local store is never blocked.** Nothing here is on the path of a
///    user edit. If the engine is offline, mid-refresh, or holding a dead
///    session, writes keep landing in the queue and reads keep serving from
///    SQLite.
/// 2. **At-least-once, never at-most-once.** A mutation leaves the queue only
///    on a *terminal* server verdict. Transport failures keep it, with its
///    original `mutation_id`, so the retry is a replay the server deduplicates.
/// 3. **Ordered.** The queue is strict FIFO by `seq`. A batch that fails is not
///    stepped over — later mutations may depend on it (a span's close after its
///    open, a taxonomy row before the span citing it).
/// 4. **Conflicts are surfaced, not resolved.** `suspected_duplicate` and
///    `billing_overlap` are parked for a human. Both mean two records claim the
///    same hours, and choosing between them automatically either invents or
///    destroys billable time.
public actor SyncEngine {

    private let store: TimelyLocalStore
    private let client: TimelyAPIClient
    private let auth: AuthClient

    public let workspaceID: UUID
    public let deviceID: UUID

    /// Rows per pull page. The contract caps this at 2000.
    public var pageLimit: Int = 500

    /// Mutations per push batch. The contract caps this at 200.
    public var batchLimit: Int = 100

    /// Pages consumed in one `pull()` before yielding, so a bootstrap of a large
    /// workspace cannot monopolize the engine forever.
    public var maxPagesPerPull: Int = 50

    private var isSyncing = false

    public init(
        store: TimelyLocalStore,
        client: TimelyAPIClient,
        auth: AuthClient,
        workspaceID: UUID,
        deviceID: UUID
    ) {
        self.store = store
        self.client = client
        self.auth = auth
        self.workspaceID = workspaceID
        self.deviceID = deviceID
    }

    // MARK: - Entry point

    /// Push everything queued, then pull everything new.
    ///
    /// Push precedes pull so that a locally minted row and the server's view of
    /// it converge in one cycle rather than two, and so the pull picks up any
    /// side effects the push produced.
    @discardableResult
    public func sync() async throws -> SyncOutcome {
        guard !isSyncing else { return .init(skipped: true) }
        isSyncing = true
        defer { isSyncing = false }

        var outcome = SyncOutcome()

        // No session at all is not an error worth throwing. The user is working
        // offline; the queue keeps growing and this call is a no-op.
        guard await auth.hasSession else {
            outcome.skipped = true
            outcome.reason = .noSession
            return outcome
        }

        do {
            let pushed = try await push()
            outcome.merge(pushed)
        } catch let error as AuthError where error.requiresReauthentication {
            outcome.skipped = true
            outcome.reason = .sessionExpired
            return outcome
        }

        do {
            let pulled = try await pull()
            outcome.merge(pulled)
        } catch let error as AuthError where error.requiresReauthentication {
            outcome.skipped = true
            outcome.reason = .sessionExpired
            return outcome
        }

        return outcome
    }

    // MARK: - Pull

    /// Drain pages from the server's change feed, newest cursor last.
    ///
    /// The cursor and the page it describes are written in the same transaction
    /// inside the store, so a crash between them cannot skip rows.
    @discardableResult
    public func pull() async throws -> SyncOutcome {
        var outcome = SyncOutcome()
        var state = try await store.syncState(workspaceID: workspaceID)

        // A watermark below the tombstone horizon means the server can no longer
        // prove what was deleted. Continuing incrementally would silently retain
        // rows the workspace removed, so start over from 0.
        if state.needsRebootstrap {
            outcome.rebootstrapped = true
            state.cursor = 0
        }

        var pages = 0
        while pages < maxPagesPerPull {
            pages += 1

            let response = try await client.pullChanges(
                workspaceID: workspaceID,
                since: state.cursor,
                limit: pageLimit
            )

            // Re-check on every page: the horizon can advance mid-drain during a
            // long bootstrap.
            if state.cursor > 0, state.cursor < response.tombstoneHorizonRevision {
                outcome.rebootstrapped = true
                state.cursor = 0
                continue
            }

            let applied = try await apply(response.changes)
            outcome.rowsApplied += applied
            outcome.rowsReceived += response.changes.totalCount
            outcome.pagesPulled += 1

            state.cursor = max(state.cursor, response.nextCursor)
            state.tombstoneHorizonRevision = response.tombstoneHorizonRevision
            state.lastPullAt = Date()
            state.lastServerTime = response.serverTime
            try await store.saveSyncState(state)

            guard response.hasMore else { break }
        }

        outcome.cursor = state.cursor
        return outcome
    }

    /// Write one page into the store.
    ///
    /// Each bucket is upserted with `markDirty: false` — these rows came *from*
    /// the server, so they are by definition not pending upload. The store's LWW
    /// rule decides whether each one actually replaces the local copy.
    private func apply(_ changes: ChangeSet) async throws -> Int {
        // `preserveUnpushedEdits: true` is what makes this the pull path rather
        // than a blind overwrite: a row this device has edited but not yet
        // pushed keeps its local content and takes only the server's envelope
        // underneath (§7.1). Push-result adoption deliberately does NOT set it.
        var applied = 0
        applied += try await store.upsertAll(changes.clients, preserveUnpushedEdits: true)
        applied += try await store.upsertAll(changes.projects, preserveUnpushedEdits: true)
        applied += try await store.upsertAll(changes.tickets, preserveUnpushedEdits: true)
        applied += try await store.upsertAll(changes.timeSpans, preserveUnpushedEdits: true)
        applied += try await store.upsertAll(changes.screenshots, preserveUnpushedEdits: true)
        applied += try await store.upsertAll(changes.visionAnalyses, preserveUnpushedEdits: true)
        applied += try await store.upsertAll(changes.censoredScreenshots, preserveUnpushedEdits: true)
        applied += try await store.upsertAll(changes.devices, preserveUnpushedEdits: true)
        applied += try await store.upsertAll(changes.settings, preserveUnpushedEdits: true)
        return applied
    }

    // MARK: - Push

    /// Drain the push queue in FIFO order until it is empty or a batch fails.
    @discardableResult
    public func push() async throws -> SyncOutcome {
        var outcome = SyncOutcome()

        while true {
            let batch = try await store.nextBatch(workspaceID: workspaceID, limit: batchLimit)
            guard !batch.isEmpty else { break }

            let isAtomic = batch.first?.batchGroup != nil
            let request = MutationRequest(
                workspaceID: workspaceID,
                deviceID: deviceID,
                atomic: isAtomic,
                mutations: batch.map(MutationEnvelope.init)
            )

            let response: MutationResponse
            do {
                response = try await client.pushMutations(request)
            } catch let error as SyncError where error.isRetryable {
                // Keep the batch, keep the ids. The next attempt is a replay.
                try await store.recordAttemptFailure(
                    batch.map(\.mutationID),
                    error: error.description
                )
                outcome.pushRetryable += batch.count
                outcome.lastPushError = error.description
                break
            } catch let error as SyncError {
                if case .http(409, _) = error, isAtomic {
                    // An atomic batch that the server refused wholesale. It
                    // wrote nothing, so the mutations stay queued — but they
                    // will fail identically until the conflict is resolved, so
                    // park them for a human rather than spin.
                    try await parkAtomicRejection(batch, error: error)
                    outcome.conflicts += batch.count
                    break
                }
                throw error
            }

            let digest = try await applyResults(response.results, for: batch)
            outcome.merge(digest)

            // The response's cursor is a hint only. Side effects can touch rows
            // this batch never mentioned, so a real pull still has to run — but
            // advancing nothing here is also wrong, so record it as a floor.
            var state = try await store.syncState(workspaceID: workspaceID)
            state.lastPushAt = Date()
            state.lastServerTime = response.serverTime
            try await store.saveSyncState(state)

            // A short batch means the queue is drained.
            if batch.count < batchLimit && !isAtomic { break }
        }

        return outcome
    }

    /// Apply one batch's verdicts.
    private func applyResults(
        _ results: [MutationResult],
        for batch: [QueuedMutation]
    ) async throws -> SyncOutcome {
        var outcome = SyncOutcome()
        let queued = Dictionary(uniqueKeysWithValues: batch.map { ($0.mutationID, $0) })

        var terminal: [UUID] = []

        for result in results {
            guard let mutation = queued[result.mutationID] else {
                // A verdict for a mutation this client did not send — a replay
                // of another device's work under a shared queue, or a server
                // echoing something we have already dequeued.
                //
                // The envelope's `entity_kind` is what makes this recoverable:
                // without it there is no way to tell which bucket `entity`
                // belongs to, and the row has to be dropped. With it, the row is
                // adopted like any other server-authored row. Android reads the
                // same field, so both clients now behave identically here.
                if let kind = result.entityKind {
                    try await adoptServerRow(result.entity, kind: kind)
                    outcome.sideEffects += result.sideEffects.count
                    for effect in result.sideEffects {
                        try await adoptServerRow(effect.row, kind: effect.entity)
                    }
                }
                continue
            }

            // Prefer the envelope over the local queue entry. They agree in
            // practice, but the server is authoritative about what it wrote,
            // and reading the same source as the other clients means a
            // divergence shows up as a decode failure rather than as two
            // implementations quietly disagreeing.
            let kind = result.entityKind ?? mutation.entityKind

            if result.replayed { outcome.replayed += 1 }
            if result.staleBase { outcome.staleBase += 1 }

            switch result.status {
            case .applied:
                outcome.applied += 1
                try await adoptServerRow(result.entity, kind: kind)
                try await store.clearDirty(kind: kind, ids: [mutation.entityID])

            case .conflict:
                outcome.conflicts += 1
                // The server's row is authoritative. Adopt it, then park the
                // disagreement so a person can see what happened to their edit.
                try await adoptServerRow(result.entity, kind: kind)
                try await park(result, mutation: mutation)

            case .rejected:
                outcome.rejected += 1
                // A rejection may still carry the authoritative row (a stale
                // write against a newer server copy), and adopting it is how the
                // client stops re-sending a doomed mutation.
                try await adoptServerRow(result.entity, kind: kind)
                try await park(result, mutation: mutation)
            }

            // Side effects are rows the server changed that we never asked
            // about — auto-vivified taxonomy, or a censorship cascade. Applying
            // them inline means the UI is correct before the next pull.
            for effect in result.sideEffects {
                try await adoptServerRow(effect.row, kind: effect.entity)
                outcome.sideEffects += 1
            }

            // All three statuses are terminal. Only transport keeps a mutation.
            terminal.append(result.mutationID)
        }

        try await store.dequeue(terminal)
        return outcome
    }

    /// Decode a server-authored row of a runtime-determined kind into the store.
    ///
    /// The `switch` is unavoidable: `EntityKind` is a wire string and the store
    /// is generic over a static type. Keeping it in one function means adding a
    /// kind is one edit.
    private func adoptServerRow(_ row: JSONValue?, kind: EntityKind) async throws {
        guard let row, !row.isNull else { return }

        switch kind {
        case .client:
            try await store.upsert(row.decoded(as: ClientRecord.self), markDirty: false)
        case .project:
            try await store.upsert(row.decoded(as: ProjectRecord.self), markDirty: false)
        case .ticket:
            try await store.upsert(row.decoded(as: TicketRecord.self), markDirty: false)
        case .timeSpan:
            try await store.upsert(row.decoded(as: TimeSpan.self), markDirty: false)
        case .screenshot:
            try await store.upsert(row.decoded(as: Screenshot.self), markDirty: false)
        case .visionAnalysis:
            try await store.upsert(row.decoded(as: VisionAnalysis.self), markDirty: false)
        case .censoredScreenshot:
            try await store.upsert(row.decoded(as: CensoredScreenshot.self), markDirty: false)
        case .device:
            try await store.upsert(row.decoded(as: Device.self), markDirty: false)
        case .userSettings:
            try await store.upsert(row.decoded(as: UserSettings.self), markDirty: false)
        case .workspacePolicy:
            try await store.upsert(row.decoded(as: WorkspacePolicy.self), markDirty: false)
        case .unknown:
            // A kind this build cannot name is a bucket it cannot store. Skipped
            // deliberately rather than crashing the sync loop — the contract's
            // change rules make new kinds an additive change.
            return
        }
    }

    private func park(_ result: MutationResult, mutation: QueuedMutation) async throws {
        try await store.recordOutcome(
            PendingOutcome(
                mutationID: result.mutationID,
                workspaceID: mutation.workspaceID,
                entityKind: mutation.entityKind,
                entityID: mutation.entityID,
                status: result.status,
                reason: result.reason,
                message: result.message,
                recordedAt: Date(),
                detail: result.entity ?? .null
            )
        )
    }

    private func parkAtomicRejection(_ batch: [QueuedMutation], error: SyncError) async throws {
        for mutation in batch {
            try await store.recordOutcome(
                PendingOutcome(
                    mutationID: mutation.mutationID,
                    workspaceID: mutation.workspaceID,
                    entityKind: mutation.entityKind,
                    entityID: mutation.entityID,
                    status: .conflict,
                    reason: .batchRolledBack,
                    message: error.description,
                    recordedAt: Date(),
                    detail: mutation.payload
                )
            )
        }
    }
}

// MARK: - Outcome

/// What one sync cycle did. Returned rather than logged so a UI can show
/// "3 changes uploaded, 1 needs your attention" without parsing a log.
public struct SyncOutcome: Sendable, Hashable {
    public var pagesPulled = 0
    public var rowsReceived = 0
    public var rowsApplied = 0
    public var cursor: Int64 = 0

    public var applied = 0
    public var conflicts = 0
    public var rejected = 0
    public var replayed = 0
    public var staleBase = 0
    public var sideEffects = 0
    public var pushRetryable = 0

    /// True when the client's watermark had fallen below the tombstone horizon
    /// and the pull restarted from zero.
    public var rebootstrapped = false

    public var skipped = false
    public var reason: SkipReason?
    public var lastPushError: String?

    public enum SkipReason: Sendable, Hashable {
        /// No credentials at all. Expected and benign — the user has not signed
        /// in yet, and the app is fully usable.
        case noSession

        /// The refresh token was rejected. The user must sign in again to
        /// resume syncing; local work is unaffected.
        case sessionExpired
    }

    public init(skipped: Bool = false) {
        self.skipped = skipped
    }

    /// True when anything needs a person's attention.
    public var needsAttention: Bool { conflicts > 0 || rejected > 0 }

    mutating func merge(_ other: SyncOutcome) {
        pagesPulled += other.pagesPulled
        rowsReceived += other.rowsReceived
        rowsApplied += other.rowsApplied
        applied += other.applied
        conflicts += other.conflicts
        rejected += other.rejected
        replayed += other.replayed
        staleBase += other.staleBase
        sideEffects += other.sideEffects
        pushRetryable += other.pushRetryable
        rebootstrapped = rebootstrapped || other.rebootstrapped
        if other.cursor > cursor { cursor = other.cursor }
        if let error = other.lastPushError { lastPushError = error }
    }
}
