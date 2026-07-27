import Foundation
import Testing
@testable import TimelyKit

/// Signing in after tracking time offline is a re-key, not a column update.
///
/// The macOS agent works without an account, so rows exist under a provisional
/// workspace before the real one is known. Taxonomy ids are
/// `uuidv5(workspace_id, key)`, so they must be re-derived — otherwise the
/// re-keyed rows would never merge with the same client created on a phone.
@Suite("Workspace rebinding")
struct WorkspaceRebindingTests {

    static let provisional = UUID(uuidString: "0192aaaa-0000-7000-8000-000000000001")!
    static let real = Fixed.workspace

    /// Build a store holding a taxonomy and a span that references it.
    private func seeded() async throws -> TimelyLocalStore {
        let store = try TimelyLocalStore()
        let workspace = Self.provisional

        let client = ClientRecord.minted(
            workspaceID: workspace, deviceID: Fixed.deviceA, name: "Acme"
        )!
        let project = ProjectRecord.minted(
            workspaceID: workspace, deviceID: Fixed.deviceA, clientName: "Acme", name: "Redesign"
        )!
        let ticket = TicketRecord.minted(
            workspaceID: workspace, deviceID: Fixed.deviceA,
            clientName: "Acme", projectName: "Redesign", name: "TL-14"
        )!
        try await store.upsertAll([client])
        try await store.upsertAll([project])
        try await store.upsertAll([ticket])

        let span = TimeSpan(
            sync: .local(id: UUID(), workspaceID: workspace, deviceID: Fixed.deviceA),
            title: "Offline work",
            clientID: client.id,
            projectID: project.id,
            ticketID: ticket.id,
            clientName: "Acme",
            projectName: "Redesign",
            ticketName: "TL-14",
            start: Fixed.date(0),
            end: Fixed.date(3600),
            source: .timer
        )
        try await store.upsert(span)
        _ = try await store.enqueue(.create, entity: span)
        return store
    }

    @Test("rebinding to the same workspace is a no-op")
    func sameWorkspaceIsNoOp() async throws {
        let store = try await seeded()
        let report = try await store.rebindWorkspace(
            from: Self.provisional, to: Self.provisional, deviceID: Fixed.deviceA
        )
        #expect(report.isEmpty)
        #expect(try await store.count(.timeSpan, workspaceID: Self.provisional) == 1)
    }

    @Test("every row moves to the new workspace")
    func rowsMove() async throws {
        let store = try await seeded()
        let report = try await store.rebindWorkspace(
            from: Self.provisional, to: Self.real, deviceID: Fixed.deviceA
        )

        #expect(report.clients == 1)
        #expect(report.projects == 1)
        #expect(report.tickets == 1)
        #expect(report.spans == 1)

        #expect(try await store.count(.timeSpan, workspaceID: Self.provisional) == 0)
        #expect(try await store.count(.timeSpan, workspaceID: Self.real) == 1)
        #expect(try await store.count(.client, workspaceID: Self.real) == 1)
    }

    /// The heart of it: a client re-keyed into the real workspace must land on
    /// the id a phone would independently compute for the same name.
    @Test("taxonomy ids are re-derived under the new workspace")
    func taxonomyIsRederived() async throws {
        let store = try await seeded()
        try await store.rebindWorkspace(
            from: Self.provisional, to: Self.real, deviceID: Fixed.deviceA
        )

        let expectedClientID = Canon.clientID(workspaceID: Self.real, name: "Acme")!
        let rebound = try await store.fetch(ClientRecord.self, id: expectedClientID)
        #expect(rebound?.name == "Acme", "the client must be findable at its deterministic id")

        // The provisional id must be gone, not merely duplicated.
        let oldID = Canon.clientID(workspaceID: Self.provisional, name: "Acme")!
        #expect(oldID != expectedClientID)
        #expect(try await store.fetch(ClientRecord.self, id: oldID) == nil)
    }

    /// A span whose taxonomy was re-keyed must follow it, or it points at rows
    /// that no longer exist.
    @Test("spans are relinked to the re-derived taxonomy")
    func spansRelinked() async throws {
        let store = try await seeded()
        try await store.rebindWorkspace(
            from: Self.provisional, to: Self.real, deviceID: Fixed.deviceA
        )

        let spans = try await store.fetchAll(TimeSpan.self, workspaceID: Self.real)
        #expect(spans.count == 1)

        let span = spans[0]
        #expect(span.clientID == Canon.clientID(workspaceID: Self.real, name: "Acme"))
        #expect(span.projectID == Canon.projectID(
            workspaceID: Self.real, clientName: "Acme", name: "Redesign"
        ))
        #expect(span.ticketID == Canon.ticketID(
            workspaceID: Self.real, clientName: "Acme", projectName: "Redesign", name: "TL-14"
        ))

        // And those rows actually exist.
        #expect(try await store.fetch(ClientRecord.self, id: span.clientID!) != nil)
        #expect(try await store.fetch(ProjectRecord.self, id: span.projectID!) != nil)
        #expect(try await store.fetch(TicketRecord.self, id: span.ticketID!) != nil)
    }

    /// The old queue embedded the provisional workspace id in every payload;
    /// replaying it would earn `workspace_mismatch`. It is rebuilt instead.
    @Test("the push queue is rebuilt against the new workspace")
    func queueRebuilt() async throws {
        let store = try await seeded()
        let before = try await store.nextBatch(workspaceID: Self.provisional)
        #expect(before.count == 1)

        try await store.rebindWorkspace(
            from: Self.provisional, to: Self.real, deviceID: Fixed.deviceA
        )

        #expect(try await store.queueDepth(workspaceID: Self.provisional) == 0)

        let after = try await store.nextBatch(workspaceID: Self.real, limit: 200)
        #expect(after.count == 4, "one mutation per rebound row: client, project, ticket, span")
        #expect(after.allSatisfy { $0.workspaceID == Self.real })
        #expect(after.allSatisfy { $0.baseRevision == nil }, "nothing is server-acknowledged yet")

        // Fresh mutation ids — these are genuinely different writes.
        let oldIDs = Set(before.map(\.mutationID))
        #expect(Set(after.map(\.mutationID)).isDisjoint(with: oldIDs))
    }

    @Test("rebound rows are unacknowledged so the bootstrap push re-sends them")
    func reboundRowsAreLocalOnly() async throws {
        let store = try await seeded()
        try await store.rebindWorkspace(
            from: Self.provisional, to: Self.real, deviceID: Fixed.deviceA
        )

        let spans = try await store.fetchAll(TimeSpan.self, workspaceID: Self.real)
        #expect(spans.allSatisfy { $0.sync.isLocalOnly })
    }

    /// Tombstones must survive the move — a row the user deleted offline must
    /// not come back to life under the real workspace.
    @Test("tombstones survive the rebind")
    func tombstonesSurvive() async throws {
        let store = try await seeded()

        let doomed = TimeSpan(
            sync: .local(id: UUID(), workspaceID: Self.provisional, deviceID: Fixed.deviceA),
            title: "Deleted offline",
            clientName: "Acme",
            projectName: "Redesign",
            start: Fixed.date(0),
            end: Fixed.date(60),
            source: .manual
        )
        try await store.upsert(doomed)
        _ = try await store.tombstone(
            TimeSpan.self, id: doomed.id, deviceID: Fixed.deviceA
        )

        try await store.rebindWorkspace(
            from: Self.provisional, to: Self.real, deviceID: Fixed.deviceA
        )

        let moved = try await store.fetch(TimeSpan.self, id: doomed.id)
        #expect(moved?.isDeleted == true, "a row deleted offline must stay deleted")
        #expect(moved?.sync.workspaceID == Self.real)

        // Live rows are unaffected.
        let live = try await store.fetchAll(TimeSpan.self, workspaceID: Self.real)
        #expect(live.count == 1)
    }

    @Test("a second rebind to the same target is idempotent")
    func idempotent() async throws {
        let store = try await seeded()
        try await store.rebindWorkspace(
            from: Self.provisional, to: Self.real, deviceID: Fixed.deviceA
        )
        let countAfterFirst = try await store.count(.timeSpan, workspaceID: Self.real)

        // Nothing is left under the provisional id, so this moves nothing.
        let second = try await store.rebindWorkspace(
            from: Self.provisional, to: Self.real, deviceID: Fixed.deviceA
        )
        #expect(second.isEmpty)
        #expect(try await store.count(.timeSpan, workspaceID: Self.real) == countAfterFirst)
    }
}
