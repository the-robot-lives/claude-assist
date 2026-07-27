import Foundation

/// The offline-first local store.
///
/// Every read a companion performs and every write a user makes goes through
/// here, and **none of it consults the network or the auth state**. That is the
/// central design commitment: a user with a dead token on a plane can start a
/// timer, edit yesterday's spans, and read their whole history. Sync is a
/// background reconciliation of this store with the server, not a precondition
/// for using it.
///
/// An `actor` rather than a lock: the store is touched by the UI, the sync
/// engine and the migration importer, and Swift 6 strict concurrency makes the
/// alternative — a class with an internal mutex and `@unchecked Sendable` —
/// an unaudited claim rather than a checked one.
public actor TimelyLocalStore {

    private let connection: SQLiteConnection
    /// The *storage* encoder, not the wire encoder — the document column
    /// remembers server-owned fields rather than discarding them.
    private let encoder = TimelyJSON.makeStorageEncoder()
    private let decoder = TimelyJSON.makeDecoder()

    /// The database file, or `nil` for an in-memory store.
    public let location: URL?

    // MARK: - Lifecycle

    public init(url: URL) throws {
        self.location = url
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        self.connection = try SQLiteConnection(path: url.path)
        try Self.migrate(connection)
    }

    /// An in-memory store. Tests, and previews.
    public init() throws {
        self.location = nil
        self.connection = try SQLiteConnection(path: ":memory:")
        try Self.migrate(connection)
    }

    /// The conventional on-disk location for a companion app.
    public static func defaultURL(appGroup: String? = nil) -> URL {
        let base: URL
        if let appGroup,
           let shared = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            base = shared
        } else {
            base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        }
        return base.appendingPathComponent("Timely", isDirectory: true)
            .appendingPathComponent("timely.sqlite3")
    }

    private static func migrate(_ connection: SQLiteConnection) throws {
        try connection.transaction {
            for statement in StoreSchema.statements {
                try connection.execute(statement)
            }

            let found = try connection.query(
                "SELECT value FROM meta WHERE key = 'schema_version'", []
            ) { Int($0.string(0)) ?? 0 }.first ?? 0

            guard found <= StoreSchema.version else {
                throw StoreError.schemaTooNew(found: found, supported: StoreSchema.version)
            }

            try connection.run(
                "INSERT INTO meta (key, value) VALUES ('schema_version', ?1) "
                + "ON CONFLICT(key) DO UPDATE SET value = excluded.value",
                [.text(String(StoreSchema.version))]
            )
        }
    }

    // MARK: - Upsert

    /// Insert or replace a row, applying the §8 last-writer-wins rule.
    ///
    /// A row arriving from the server always wins over the local copy when its
    /// `server_revision` is higher — the server has already adjudicated. Two
    /// rows the server has *not* seen are compared by effective timestamp, and
    /// ties break on the lexically greater `origin_device_id`, so every device
    /// independently computes the same winner without a round trip.
    /// - Parameter preserveUnpushedEdits: Set only on the **pull** path. It
    ///   protects content this device has edited but not yet pushed (§7.1).
    ///   It MUST stay false when adopting a row from a *push result*: a
    ///   `conflict` or `rejected` verdict is the server adjudicating the very
    ///   mutation that is still sitting in the queue, and the client's job there
    ///   is to adopt the authoritative row, not to defend the edit that lost.
    @discardableResult
    public func upsert<E: SyncEntity>(
        _ entity: E,
        markDirty: Bool = true,
        preserveUnpushedEdits: Bool = false
    ) throws -> Bool {
        try connection.transaction {
            try upsertWithinTransaction(
                entity, markDirty: markDirty, preserveUnpushedEdits: preserveUnpushedEdits
            )
        }
    }

    /// Upsert many rows in one transaction. This is the pull path — a page
    /// lands whole or not at all.
    @discardableResult
    public func upsertAll<E: SyncEntity>(
        _ entities: [E],
        markDirty: Bool = false,
        preserveUnpushedEdits: Bool = false
    ) throws -> Int {
        guard !entities.isEmpty else { return 0 }
        return try connection.transaction {
            var applied = 0
            for entity in entities where try upsertWithinTransaction(
                entity, markDirty: markDirty, preserveUnpushedEdits: preserveUnpushedEdits
            ) {
                applied += 1
            }
            return applied
        }
    }

    /// Internal rather than private so ``rebindWorkspace(from:to:deviceID:)``
    /// can write re-keyed rows inside its own single transaction.
    func upsertWithinTransaction<E: SyncEntity>(
        _ entity: E,
        markDirty: Bool,
        preserveUnpushedEdits: Bool = false
    ) throws -> Bool {
        let kind = E.kind.rawValue
        let existing = try loadEnvelope(kind: kind, id: entity.sync.id)

        if let existing, !shouldReplace(existing: existing, with: entity.sync) {
            return false
        }

        // §7.1: "the local edit wins in the UI until it is pushed and answered."
        //
        // A pulled row must not overwrite content this device has edited but not
        // yet pushed. Without this, a pull that lands before the queue drains
        // reverts the user's change **on screen** while their mutation is still
        // in the outbox — they assume it was lost, redo it, and now there are
        // two. That is the most user-visible failure in the system, and it is
        // not covered by LWW: LWW protects a local edit only when its clock is
        // newer, and says nothing about whether it has been pushed.
        var entity = entity
        var dirty = markDirty

        if preserveUnpushedEdits,
           !markDirty,
           existing != nil,
           entity.sync.deletedAt == nil,          // a tombstone is absorbing; see below
           try hasPendingMutation(kind: kind, id: entity.sync.id),
           let localDocument = try loadDocument(kind: kind, id: entity.sync.id) {
            entity = try preserveLocalContent(server: entity, localDocument: localDocument)
            // The mutation is still pending, so the row is still dirty.
            dirty = true
        }

        let index = StoreIndex(for: entity)
        try connection.run(
            """
            INSERT INTO entities
                (kind, id, workspace_id, server_revision, created_at, updated_at,
                 deleted_at, range_start, range_end, parent_id, search_text, dirty, document)
            VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13)
            ON CONFLICT(kind, id) DO UPDATE SET
                server_revision = excluded.server_revision,
                created_at      = excluded.created_at,
                updated_at      = excluded.updated_at,
                deleted_at      = excluded.deleted_at,
                range_start     = excluded.range_start,
                range_end       = excluded.range_end,
                parent_id       = excluded.parent_id,
                search_text     = excluded.search_text,
                dirty           = excluded.dirty,
                document        = excluded.document
            """,
            [
                .text(kind),
                .uuid(entity.sync.id),
                .uuid(entity.sync.workspaceID),
                .integer(entity.sync.serverRevision),
                .date(entity.sync.createdAt),
                .date(entity.sync.updatedAt),
                .date(entity.sync.deletedAt),
                .date(index.rangeStart),
                .date(index.rangeEnd),
                .uuid(index.parentID),
                .text(index.searchText),
                .bool(dirty),
                .text(try encodeDocument(entity))
            ]
        )
        return true
    }

    /// §8 LWW. Extracted so the rule is one readable expression and so the
    /// conflict tests can reason about it directly.
    private func shouldReplace(existing: StoredEnvelope, with incoming: SyncEnvelope) -> Bool {
        // The server has spoken. Its revision is authoritative over anything
        // local, including a newer local clock.
        if incoming.serverRevision != existing.serverRevision {
            return incoming.serverRevision > existing.serverRevision
        }

        // Row 2: a tombstone beats a concurrent update regardless of clocks.
        // Nothing is destroyed, so the safe direction is "stays deleted".
        switch (existing.deletedAt, incoming.deletedAt) {
        case (nil, .some): return true
        case (.some, nil): return false
        default: break
        }

        if incoming.updatedAt != existing.updatedAt {
            return incoming.updatedAt > existing.updatedAt
        }

        let incomingDevice = incoming.originDeviceID?.canonicalString ?? ""
        let existingDevice = existing.originDeviceID?.canonicalString ?? ""

        // A device rewriting its OWN row is not a conflict, so it must not reach
        // the tie-break at all.
        //
        // The tie-break asks "which of two devices wins" and answers with the
        // lexically greater id. When both sides carry the *same* id there is no
        // second device — it is one device saving twice — and a strict `>`
        // answers "neither", so the newer local edit was silently dropped while
        // its mutation still went to the server with the correct payload. The
        // UI then showed a stale value until a pull contradicted it.
        //
        // Rare against a live `Date()`, but deterministic for any caller passing
        // an explicit timestamp — batch edits, imports, and every test.
        //
        // This does not weaken the cross-device rule: when the ids differ the
        // comparison below is unchanged, so §8.2's "lexically greater
        // `origin_device_id` wins" still holds and every client still computes
        // the same winner without asking the server.
        if incomingDevice == existingDevice {
            return true
        }

        return incomingDevice > existingDevice
    }

    // MARK: - Reads

    public func fetch<E: SyncEntity>(_ type: E.Type, id: UUID) throws -> E? {
        try connection.query(
            "SELECT document FROM entities WHERE kind = ?1 AND id = ?2",
            [.text(E.kind.rawValue), .uuid(id)]
        ) { $0.string(0) }
            .first
            .map { try decodeDocument(E.self, from: $0, id: id) }
    }

    /// All live rows of a kind, newest first. Tombstones are excluded unless
    /// asked for — a caller that wants them is doing sync work, not UI work.
    public func fetchAll<E: SyncEntity>(
        _ type: E.Type,
        workspaceID: UUID,
        includeDeleted: Bool = false,
        limit: Int? = nil,
        offset: Int = 0
    ) throws -> [E] {
        var sql = """
            SELECT document, id FROM entities
            WHERE kind = ?1 AND workspace_id = ?2
            """
        if !includeDeleted { sql += " AND deleted_at IS NULL" }
        sql += " ORDER BY COALESCE(range_start, updated_at) DESC, id"
        var bindings: [SQLiteValue] = [.text(E.kind.rawValue), .uuid(workspaceID)]
        if let limit {
            sql += " LIMIT ?3 OFFSET ?4"
            bindings.append(.integer(limit))
            bindings.append(.integer(offset))
        }

        return try connection.query(sql, bindings) { ($0.string(0), $0.uuid(1)) }
            .map { try decodeDocument(E.self, from: $0.0, id: $0.1) }
    }

    /// The timeline query. Any row whose `[range_start, range_end)` overlaps the
    /// window, newest first — an open span (null `range_end`) overlaps every
    /// window that starts before it ends.
    ///
    /// This is the query the whole storage choice was made for; it is an index
    /// range scan rather than a decode of the workspace.
    public func fetchInRange<E: SyncEntity>(
        _ type: E.Type,
        workspaceID: UUID,
        from: Date,
        to: Date,
        includeDeleted: Bool = false,
        limit: Int? = nil,
        offset: Int = 0
    ) throws -> [E] {
        var sql = """
            SELECT document, id FROM entities
            WHERE kind = ?1 AND workspace_id = ?2
              AND range_start IS NOT NULL
              AND range_start < ?4
              AND (range_end IS NULL OR range_end > ?3)
            """
        if !includeDeleted { sql += " AND deleted_at IS NULL" }
        sql += " ORDER BY range_start DESC, id"

        var bindings: [SQLiteValue] = [
            .text(E.kind.rawValue), .uuid(workspaceID), .date(from), .date(to)
        ]
        if let limit {
            sql += " LIMIT ?5 OFFSET ?6"
            bindings.append(.integer(limit))
            bindings.append(.integer(offset))
        }

        return try connection.query(sql, bindings) { ($0.string(0), $0.uuid(1)) }
            .map { try decodeDocument(E.self, from: $0.0, id: $0.1) }
    }

    /// Children of a row — a span's screenshots, a screenshot's analyses.
    public func fetchChildren<E: SyncEntity>(
        _ type: E.Type,
        parentID: UUID,
        includeDeleted: Bool = false
    ) throws -> [E] {
        var sql = """
            SELECT document, id FROM entities
            WHERE kind = ?1 AND parent_id = ?2
            """
        if !includeDeleted { sql += " AND deleted_at IS NULL" }
        sql += " ORDER BY COALESCE(range_start, updated_at) DESC, id"

        return try connection.query(sql, [.text(E.kind.rawValue), .uuid(parentID)]) {
            ($0.string(0), $0.uuid(1))
        }.map { try decodeDocument(E.self, from: $0.0, id: $0.1) }
    }

    /// Substring match over the promoted `search_text` column.
    public func search<E: SyncEntity>(
        _ type: E.Type,
        workspaceID: UUID,
        matching text: String,
        limit: Int = 100
    ) throws -> [E] {
        let needle = Canon.canon(text)
        guard !needle.isEmpty else { return [] }

        return try connection.query(
            """
            SELECT document, id FROM entities
            WHERE kind = ?1 AND workspace_id = ?2 AND deleted_at IS NULL
              AND search_text LIKE ?3
            ORDER BY COALESCE(range_start, updated_at) DESC, id
            LIMIT ?4
            """,
            [
                .text(E.kind.rawValue), .uuid(workspaceID),
                .text("%\(needle)%"), .integer(limit)
            ]
        ) { ($0.string(0), $0.uuid(1)) }
            .map { try decodeDocument(E.self, from: $0.0, id: $0.1) }
    }

    /// Open spans. There may legitimately be more than one (§8 row 8).
    public func openSpans(workspaceID: UUID) throws -> [TimeSpan] {
        try connection.query(
            """
            SELECT document, id FROM entities
            WHERE kind = ?1 AND workspace_id = ?2
              AND deleted_at IS NULL AND range_end IS NULL AND range_start IS NOT NULL
            ORDER BY range_start DESC
            """,
            [.text(EntityKind.timeSpan.rawValue), .uuid(workspaceID)]
        ) { ($0.string(0), $0.uuid(1)) }
            .map { try decodeDocument(TimeSpan.self, from: $0.0, id: $0.1) }
    }

    public func count(_ kind: EntityKind, workspaceID: UUID, includeDeleted: Bool = false) throws -> Int {
        var sql = "SELECT COUNT(*) FROM entities WHERE kind = ?1 AND workspace_id = ?2"
        if !includeDeleted { sql += " AND deleted_at IS NULL" }
        return try connection.query(sql, [.text(kind.rawValue), .uuid(workspaceID)]) {
            Int($0.int(0))
        }.first ?? 0
    }

    // MARK: - Tombstones

    /// Soft-delete. There is deliberately no hard delete on this type: the
    /// protocol's fourth commitment is that nothing is destroyed, and a local
    /// hard delete would resurrect the row on the next pull anyway.
    public func tombstone<E: SyncEntity>(
        _ type: E.Type,
        id: UUID,
        deviceID: UUID?,
        at now: Date = Date()
    ) throws -> E? {
        guard var entity = try fetch(E.self, id: id) else { return nil }
        entity.tombstone(deviceID: deviceID, at: now)
        try upsert(entity, markDirty: true)
        return entity
    }

    // MARK: - Envelope access

    struct StoredEnvelope {
        let serverRevision: Int64
        let updatedAt: Date
        let deletedAt: Date?
        let originDeviceID: UUID?
    }

    // MARK: - Preserving unpushed local edits

    /// Fields the **server** owns even when local content is preserved.
    ///
    /// Two groups, and both earn their place:
    ///
    /// - **Envelope.** `server_revision` above all — without it the next push
    ///   cites a stale `base_revision`, which is decisive for the reopen guard
    ///   and for locked days, so preserving content while dropping the revision
    ///   would trade a visible bug for an invisible one. `deleted_at` because a
    ///   tombstone is absorbing (§8.2 row 2). `updated_at_effective` because it
    ///   is the value LWW actually compares.
    /// - **Server-raised state.** `review_reasons` and `review_state` because a
    ///   `suspected_duplicate` raised while the user was mid-edit must still
    ///   reach them — a local edit must not swallow a server flag, or the review
    ///   queue silently loses items. `canonical_name` and the `blob_*` family
    ///   because a client may not author them at all.
    ///
    /// **Known limitation, deliberately not solved:** this keeps the server's
    /// *revision*, not its field *values*. There is no stored "theirs" side, so
    /// a field-level conflict diff cannot be rendered from this. A real merge UI
    /// would need shadow columns holding both versions. Recorded here rather
    /// than left to be discovered.
    static let serverAuthoritativeKeys: Set<String> = [
        "server_revision",
        "deleted_at",
        "origin_device_id",
        "updated_at_effective",
        "canonical_name",
        "review_reasons",
        "review_state",
        "locked_at",
        "upload_state",
        "blob_available",
        "blob_content_hash",
        "blob_byte_size",
        "blob_uploaded_at"
    ]

    /// True when this row has a mutation waiting in the push queue.
    ///
    /// The queue rather than the `dirty` flag: "is there an unanswered mutation"
    /// is literally what the queue records, whereas `dirty` is a derived hint
    /// that a conflict or rejection path could leave stale.
    private func hasPendingMutation(kind: String, id: UUID) throws -> Bool {
        try connection.query(
            "SELECT 1 FROM push_queue WHERE entity_kind = ?1 AND entity_id = ?2 LIMIT 1",
            [.text(kind), .uuid(id)]
        ) { _ in true }.first ?? false
    }

    private func loadDocument(kind: String, id: UUID) throws -> String? {
        try connection.query(
            "SELECT document FROM entities WHERE kind = ?1 AND id = ?2",
            [.text(kind), .uuid(id)]
        ) { $0.string(0) }.first
    }

    /// Local content, server envelope underneath.
    ///
    /// Merged as JSON rather than field by field so it holds for all ten entity
    /// kinds and for any field added later, without a `switch` that someone has
    /// to remember to extend.
    private func preserveLocalContent<E: SyncEntity>(
        server: E,
        localDocument: String
    ) throws -> E {
        let serverJSON = try TimelyJSON.decode(
            JSONValue.self, from: try encodeDocument(server)
        )
        let localJSON = try TimelyJSON.decode(JSONValue.self, from: localDocument)

        guard var merged = localJSON.objectValue,
              let authoritative = serverJSON.objectValue else { return server }

        for key in Self.serverAuthoritativeKeys {
            if let value = authoritative[key] {
                merged[key] = value
            } else {
                merged.removeValue(forKey: key)
            }
        }

        return try decodeDocument(
            E.self,
            from: try TimelyJSON.encodeToString(JSONValue.object(merged)),
            id: server.sync.id
        )
    }

    private func loadEnvelope(kind: String, id: UUID) throws -> StoredEnvelope? {
        try connection.query(
            """
            SELECT server_revision, updated_at, deleted_at, json_extract(document, '$.origin_device_id')
            FROM entities WHERE kind = ?1 AND id = ?2
            """,
            [.text(kind), .uuid(id)]
        ) { row in
            StoredEnvelope(
                serverRevision: row.int(0),
                updatedAt: Date(timeIntervalSince1970: row.double(1)),
                deletedAt: row.date(2),
                originDeviceID: row.uuid(3)
            )
        }.first
    }

    // MARK: - Coding

    private func encodeDocument<E: SyncEntity>(_ entity: E) throws -> String {
        String(decoding: try encoder.encode(entity), as: UTF8.self)
    }

    private func decodeDocument<E: SyncEntity>(
        _ type: E.Type,
        from document: String,
        id: UUID?
    ) throws -> E {
        do {
            return try decoder.decode(E.self, from: Data(document.utf8))
        } catch {
            throw StoreError.corruptDocument(
                kind: E.kind.rawValue,
                id: id?.canonicalString ?? "?",
                underlying: String(describing: error)
            )
        }
    }

    // MARK: - Escape hatch

    /// Direct connection access for the sync engine and the queue, which live
    /// in this module and need statements this type does not expose publicly.
    func withConnection<T>(_ body: (SQLiteConnection) throws -> T) throws -> T {
        try body(connection)
    }
}

// MARK: - Promoted index columns

/// The per-kind mapping from an entity to the columns the store actually
/// queries on.
///
/// Kept in one place so that adding an entity kind is a single edit rather than
/// a hunt through the store for every `switch`.
struct StoreIndex {
    var rangeStart: Date?
    var rangeEnd: Date?
    var parentID: UUID?
    var searchText: String

    init<E: SyncEntity>(for entity: E) {
        switch entity {
        case let span as TimeSpan:
            rangeStart = span.start
            rangeEnd = span.end
            parentID = span.projectID
            searchText = Self.haystack(
                span.title, span.clientName, span.projectName, span.ticketName, span.notes
            )

        case let screenshot as Screenshot:
            rangeStart = screenshot.capturedAt
            rangeEnd = screenshot.capturedAt
            parentID = screenshot.spanID
            searchText = Self.haystack(screenshot.activeAppName, screenshot.fileName)

        case let analysis as VisionAnalysis:
            rangeStart = analysis.analyzedAt
            rangeEnd = analysis.analyzedAt
            parentID = analysis.screenshotID
            // `rawResponse` is image-equivalent and deliberately excluded: it
            // must not become searchable text on a device that never earned the
            // right to the pixels.
            searchText = Self.haystack(
                analysis.statusUpdate, analysis.evidence,
                analysis.inferredProject, analysis.inferredTask
            )

        case let censored as CensoredScreenshot:
            rangeStart = censored.censoredAt
            rangeEnd = censored.censoredAt
            parentID = censored.screenshotID
            // Not the reason text — a censorship reason describes what was on a
            // screen the user asked to forget.
            searchText = ""

        case let client as ClientRecord:
            rangeStart = nil
            rangeEnd = nil
            parentID = nil
            searchText = Self.haystack(client.name, client.notes)

        case let project as ProjectRecord:
            rangeStart = nil
            rangeEnd = nil
            parentID = project.clientID
            searchText = Self.haystack(project.name, project.clientName, project.notes)

        case let ticket as TicketRecord:
            rangeStart = nil
            rangeEnd = nil
            parentID = ticket.projectID
            searchText = Self.haystack(
                ticket.name, ticket.projectName, ticket.clientName, ticket.notes
            )

        default:
            rangeStart = nil
            rangeEnd = nil
            parentID = nil
            searchText = ""
        }
    }

    /// Canonicalized so the search column matches on the same rules the
    /// taxonomy does — a user searching "bob's" finds "Bob's".
    private static func haystack(_ parts: String?...) -> String {
        parts.compactMap { $0 }
            .filter { !$0.isEmpty }
            .map { Canon.canon($0) }
            .joined(separator: " ")
    }
}
