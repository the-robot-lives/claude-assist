import Foundation

/// Moving a local store from a provisional workspace to the real one.
///
/// The macOS capture agent has always worked without an account, and it must
/// keep working that way — a user can install it, track a week of time, and
/// only then sign in. Those rows have to exist under *some* workspace id in the
/// meantime, so the app mints a provisional one on first launch.
///
/// Signing in is therefore a re-key, not a no-op, and it is not a simple column
/// update. Taxonomy ids are `uuidv5(workspace_id, key)` (§3.2), so every client,
/// project and ticket id is a function of the workspace it was minted under.
/// Rewriting `workspace_id` without re-deriving them would leave rows whose
/// primary key no longer matches their own name — they would never merge with
/// the same client created on a phone, which is the entire point of the
/// deterministic id.
///
/// This is the one operation in the package that rewrites primary keys, so it
/// runs in a single transaction and is idempotent: rebinding to the workspace a
/// row is already in is a no-op.
public extension TimelyLocalStore {

    /// Re-key every local row from `oldWorkspaceID` to `newWorkspaceID`.
    ///
    /// Returns a summary of what moved. Safe to call when the two ids are equal
    /// (returns zeros without touching the database).
    @discardableResult
    func rebindWorkspace(
        from oldWorkspaceID: UUID,
        to newWorkspaceID: UUID,
        deviceID: UUID?
    ) throws -> WorkspaceRebindReport {
        guard oldWorkspaceID != newWorkspaceID else { return WorkspaceRebindReport() }

        var report = WorkspaceRebindReport()

        // Taxonomy first: spans need the new ids to link against, and the map
        // from old id to new id is built here and consumed below.
        var clientRemap: [UUID: UUID] = [:]
        var projectRemap: [UUID: UUID] = [:]
        var ticketRemap: [UUID: UUID] = [:]

        let clients = try fetchAll(ClientRecord.self, workspaceID: oldWorkspaceID, includeDeleted: true)
        let projects = try fetchAll(ProjectRecord.self, workspaceID: oldWorkspaceID, includeDeleted: true)
        let tickets = try fetchAll(TicketRecord.self, workspaceID: oldWorkspaceID, includeDeleted: true)
        let spans = try fetchAll(TimeSpan.self, workspaceID: oldWorkspaceID, includeDeleted: true)
        let screenshots = try fetchAll(Screenshot.self, workspaceID: oldWorkspaceID, includeDeleted: true)
        let analyses = try fetchAll(VisionAnalysis.self, workspaceID: oldWorkspaceID, includeDeleted: true)
        let censored = try fetchAll(CensoredScreenshot.self, workspaceID: oldWorkspaceID, includeDeleted: true)

        for old in clients {
            guard let newID = Canon.clientID(workspaceID: newWorkspaceID, name: old.name) else { continue }
            clientRemap[old.id] = newID
        }
        for old in projects {
            guard let newID = Canon.projectID(
                workspaceID: newWorkspaceID, clientName: old.clientName, name: old.name
            ) else { continue }
            projectRemap[old.id] = newID
        }
        for old in tickets {
            guard let newID = Canon.ticketID(
                workspaceID: newWorkspaceID,
                clientName: old.clientName,
                projectName: old.projectName,
                name: old.name
            ) else { continue }
            ticketRemap[old.id] = newID
        }

        try withConnection { connection in
            try connection.transaction {
                // Everything under the provisional workspace goes; the rebound
                // copies are written fresh below. A delete-then-insert rather
                // than an update because the primary key itself is changing.
                try connection.run(
                    "DELETE FROM entities WHERE workspace_id = ?1", [.uuid(oldWorkspaceID)]
                )

                for var row in clients {
                    guard let newID = clientRemap[row.id] else { continue }
                    row.sync.id = newID
                    row.sync.workspaceID = newWorkspaceID
                    row.sync.serverRevision = 0
                    row.sync.originDeviceID = deviceID
                    _ = try upsertWithinTransaction(row, markDirty: true)
                    report.clients += 1
                }
                for var row in projects {
                    guard let newID = projectRemap[row.id] else { continue }
                    row.sync.id = newID
                    row.sync.workspaceID = newWorkspaceID
                    row.sync.serverRevision = 0
                    row.sync.originDeviceID = deviceID
                    row.clientID = row.clientID.flatMap { clientRemap[$0] }
                    _ = try upsertWithinTransaction(row, markDirty: true)
                    report.projects += 1
                }
                for var row in tickets {
                    guard let newID = ticketRemap[row.id] else { continue }
                    row.sync.id = newID
                    row.sync.workspaceID = newWorkspaceID
                    row.sync.serverRevision = 0
                    row.sync.originDeviceID = deviceID
                    row.clientID = row.clientID.flatMap { clientRemap[$0] }
                    row.projectID = row.projectID.flatMap { projectRemap[$0] }
                    _ = try upsertWithinTransaction(row, markDirty: true)
                    report.tickets += 1
                }

                // Event-like rows keep their own ids — those were minted
                // locally and are not workspace-derived — but must be relinked
                // to the re-keyed taxonomy.
                for var row in spans {
                    row.sync.workspaceID = newWorkspaceID
                    row.sync.serverRevision = 0
                    row.sync.originDeviceID = deviceID
                    row.clientID = row.clientID.flatMap { clientRemap[$0] }
                    row.projectID = row.projectID.flatMap { projectRemap[$0] }
                    row.ticketID = row.ticketID.flatMap { ticketRemap[$0] }
                    _ = try upsertWithinTransaction(row, markDirty: true)
                    report.spans += 1
                }
                for var row in screenshots {
                    row.sync.workspaceID = newWorkspaceID
                    row.sync.serverRevision = 0
                    _ = try upsertWithinTransaction(row, markDirty: true)
                    report.screenshots += 1
                }
                for var row in analyses {
                    row.sync.workspaceID = newWorkspaceID
                    row.sync.serverRevision = 0
                    _ = try upsertWithinTransaction(row, markDirty: true)
                    report.visionAnalyses += 1
                }
                for var row in censored {
                    row.sync.workspaceID = newWorkspaceID
                    row.sync.serverRevision = 0
                    _ = try upsertWithinTransaction(row, markDirty: true)
                    report.censoredScreenshots += 1
                }

                // A queued mutation's payload embeds the old workspace id and,
                // for taxonomy, the old primary key. Replaying it against the
                // real workspace would be rejected with `workspace_mismatch`, so
                // the queue is dropped and rebuilt from the rebound rows.
                //
                // Nothing is lost: every rebound row is at server_revision 0, so
                // the bootstrap push re-sends all of it. The mutation ids change,
                // which is correct — these are genuinely different writes now.
                try connection.run(
                    "DELETE FROM push_queue WHERE workspace_id = ?1", [.uuid(oldWorkspaceID)]
                )
                try connection.run(
                    "DELETE FROM sync_state WHERE workspace_id = ?1", [.uuid(oldWorkspaceID)]
                )
                try connection.run(
                    "DELETE FROM pending_outcomes WHERE workspace_id = ?1", [.uuid(oldWorkspaceID)]
                )
            }
        }

        // Re-enqueue outside the rebind transaction so the queue's own ordering
        // and id minting go through the normal path rather than being forged.
        for row in try fetchAll(ClientRecord.self, workspaceID: newWorkspaceID, includeDeleted: true) {
            _ = try enqueue(.create, entity: row)
        }
        for row in try fetchAll(ProjectRecord.self, workspaceID: newWorkspaceID, includeDeleted: true) {
            _ = try enqueue(.create, entity: row)
        }
        for row in try fetchAll(TicketRecord.self, workspaceID: newWorkspaceID, includeDeleted: true) {
            _ = try enqueue(.create, entity: row)
        }
        for row in try fetchAll(TimeSpan.self, workspaceID: newWorkspaceID, includeDeleted: true) {
            _ = try enqueue(.create, entity: row)
        }
        for row in try fetchAll(Screenshot.self, workspaceID: newWorkspaceID, includeDeleted: true) {
            _ = try enqueue(.create, entity: row)
        }
        for row in try fetchAll(VisionAnalysis.self, workspaceID: newWorkspaceID, includeDeleted: true) {
            _ = try enqueue(.create, entity: row)
        }
        for row in try fetchAll(CensoredScreenshot.self, workspaceID: newWorkspaceID, includeDeleted: true) {
            _ = try enqueue(.create, entity: row)
        }

        return report
    }
}

/// What a rebind moved.
public struct WorkspaceRebindReport: Sendable, Hashable {
    public var clients = 0
    public var projects = 0
    public var tickets = 0
    public var spans = 0
    public var screenshots = 0
    public var visionAnalyses = 0
    public var censoredScreenshots = 0

    public var totalRows: Int {
        clients + projects + tickets + spans
            + screenshots + visionAnalyses + censoredScreenshots
    }

    public var isEmpty: Bool { totalRows == 0 }

    public init() {}
}
