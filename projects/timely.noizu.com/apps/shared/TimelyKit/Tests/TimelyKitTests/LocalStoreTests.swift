import Foundation
import Testing
@testable import TimelyKit

@Suite("Local store")
struct LocalStoreTests {

    // MARK: - CRUD

    @Test("a written row reads back identically")
    func roundTrip() async throws {
        let store = try TimelyLocalStore()
        let span = TimeSpan.test(title: "Keyboard pass")

        try await store.upsert(span)
        let loaded = try await store.fetch(TimeSpan.self, id: span.id)

        #expect(loaded?.title == "Keyboard pass")
        #expect(loaded?.start == span.start)
        #expect(loaded?.end == span.end)
        #expect(loaded?.clientName == "Acme")
        #expect(loaded?.sync == span.sync)
    }

    @Test("a missing row reads back as nil rather than throwing")
    func missingRow() async throws {
        let store = try TimelyLocalStore()
        #expect(try await store.fetch(TimeSpan.self, id: UUID()) == nil)
    }

    @Test("rows of different kinds with the same id do not collide")
    func kindsAreSeparate() async throws {
        let store = try TimelyLocalStore()
        let shared = UUID()

        try await store.upsert(TimeSpan.test(id: shared, title: "span"))
        try await store.upsert(Screenshot.test(id: shared))

        #expect(try await store.fetch(TimeSpan.self, id: shared)?.title == "span")
        #expect(try await store.fetch(Screenshot.self, id: shared)?.fileName == "shot.png")
    }

    // MARK: - Tombstones

    @Test("a tombstoned row is hidden from ordinary reads but never destroyed")
    func tombstoneHidesButKeeps() async throws {
        let store = try TimelyLocalStore()
        let span = TimeSpan.test()
        try await store.upsert(span)

        let deleted = try await store.tombstone(
            TimeSpan.self, id: span.id, deviceID: Fixed.deviceA
        )
        #expect(deleted?.isDeleted == true)

        let live = try await store.fetchAll(TimeSpan.self, workspaceID: Fixed.workspace)
        #expect(live.isEmpty)

        let all = try await store.fetchAll(
            TimeSpan.self, workspaceID: Fixed.workspace, includeDeleted: true
        )
        #expect(all.count == 1)
        #expect(all.first?.isDeleted == true)

        // Still addressable by id — the protocol never hard-deletes.
        #expect(try await store.fetch(TimeSpan.self, id: span.id)?.isDeleted == true)
    }

    @Test("a tombstone beats a concurrent update at the same revision")
    func tombstoneWinsConcurrentUpdate() async throws {
        let store = try TimelyLocalStore()
        let id = UUID()

        // Both sides at revision 7. One deletes; one edits later on the clock.
        let deletedRow = TimeSpan.test(
            id: id, serverRevision: 7,
            updatedAt: Fixed.date(100), deletedAt: Fixed.date(100)
        )
        let editedRow = TimeSpan.test(
            id: id, title: "Edited", serverRevision: 7,
            updatedAt: Fixed.date(200)
        )

        try await store.upsert(deletedRow)
        try await store.upsert(editedRow)

        // Conflict matrix row 2: the tombstone stands, despite the later clock.
        let loaded = try await store.fetch(TimeSpan.self, id: id)
        #expect(loaded?.isDeleted == true)
    }

    // MARK: - LWW

    @Test("a higher server revision always wins")
    func higherRevisionWins() async throws {
        let store = try TimelyLocalStore()
        let id = UUID()

        // The local row has a much newer clock but no server acknowledgement.
        try await store.upsert(TimeSpan.test(
            id: id, title: "local", serverRevision: 0, updatedAt: Fixed.date(9999)
        ))
        try await store.upsert(TimeSpan.test(
            id: id, title: "server", serverRevision: 12, updatedAt: Fixed.date(1)
        ))

        #expect(try await store.fetch(TimeSpan.self, id: id)?.title == "server")
    }

    @Test("a lower server revision is rejected")
    func lowerRevisionLoses() async throws {
        let store = try TimelyLocalStore()
        let id = UUID()

        try await store.upsert(TimeSpan.test(id: id, title: "newer", serverRevision: 20))
        let applied = try await store.upsert(
            TimeSpan.test(id: id, title: "older", serverRevision: 5)
        )

        #expect(applied == false)
        #expect(try await store.fetch(TimeSpan.self, id: id)?.title == "newer")
    }

    /// A device rewriting its own row is not a conflict and must not lose the
    /// tie-break to itself. Found by the iOS agent: with equal timestamps the
    /// strict `>` comparison answered "neither wins", so the local edit was
    /// silently dropped while its mutation still went to the server — the UI
    /// showed a stale value until a pull contradicted it.
    ///
    /// Deterministic for any caller passing an explicit timestamp, which is
    /// every test, batch edit, and import path.
    @Test("a device rewriting its own row always wins")
    func sameDeviceRewriteWins() async throws {
        let store = try TimelyLocalStore()
        let id = UUID()
        let instant = Fixed.date(500)

        try await store.upsert(TimeSpan.test(
            id: id, title: "first", serverRevision: 0,
            updatedAt: instant, deviceID: Fixed.deviceA
        ))
        let applied = try await store.upsert(TimeSpan.test(
            id: id, title: "second", serverRevision: 0,
            updatedAt: instant, deviceID: Fixed.deviceA
        ))

        #expect(applied, "the same device's rewrite must land")
        #expect(try await store.fetch(TimeSpan.self, id: id)?.title == "second")
    }

    /// Two properties the same-device exemption must not disturb, flagged by
    /// the iOS agent as structurally load-bearing — several of their tests
    /// depend on them, and both are safe by *ordering* rather than by luck.
    @Test("the same-device exemption leaves tombstones and creates alone")
    func exemptionDoesNotDisturbStructuralPaths() async throws {
        let store = try TimelyLocalStore()
        let instant = Fixed.date(500)

        // 1. A tombstone wins unconditionally, from the SAME device, at the same
        //    instant. The `(nil, .some)` deletedAt check sits above the device
        //    comparison, so the exemption is never consulted.
        let id = UUID()
        try await store.upsert(TimeSpan.test(
            id: id, title: "live", updatedAt: instant, deviceID: Fixed.deviceA
        ))
        try await store.upsert(TimeSpan.test(
            id: id, title: "live", updatedAt: instant,
            deletedAt: instant, deviceID: Fixed.deviceA
        ))
        #expect(try await store.fetch(TimeSpan.self, id: id)?.isDeleted == true)

        // ...and a live row does NOT resurrect it, same device, same instant.
        try await store.upsert(TimeSpan.test(
            id: id, title: "resurrect?", updatedAt: instant, deviceID: Fixed.deviceA
        ))
        #expect(
            try await store.fetch(TimeSpan.self, id: id)?.isDeleted == true,
            "the tombstone must still be absorbing"
        )

        // 2. A create with a fresh id never reaches the tie-break at all — there
        //    is no existing row to compare against.
        let fresh = TimeSpan.test(title: "brand new", updatedAt: instant)
        #expect(try await store.upsert(fresh))
        #expect(try await store.fetch(TimeSpan.self, id: fresh.id)?.title == "brand new")
    }

    /// The same-device exemption must not weaken the cross-device rule: when the
    /// ids differ, §8.2's "lexically greater wins" still decides, identically on
    /// every client.
    @Test("equal revision and clock breaks the tie on device id, deterministically")
    func deviceIDBreaksTies() async throws {
        #expect(Fixed.deviceBWinsTies, "test assumes deviceB sorts above deviceA")

        let store = try TimelyLocalStore()
        let id = UUID()
        let instant = Fixed.date(500)

        try await store.upsert(TimeSpan.test(
            id: id, title: "from A", serverRevision: 3,
            updatedAt: instant, deviceID: Fixed.deviceA
        ))
        try await store.upsert(TimeSpan.test(
            id: id, title: "from B", serverRevision: 3,
            updatedAt: instant, deviceID: Fixed.deviceB
        ))
        #expect(try await store.fetch(TimeSpan.self, id: id)?.title == "from B")

        // And the reverse order must reach the same answer — that is the whole
        // point of a deterministic tie-break.
        let mirror = try TimelyLocalStore()
        try await mirror.upsert(TimeSpan.test(
            id: id, title: "from B", serverRevision: 3,
            updatedAt: instant, deviceID: Fixed.deviceB
        ))
        try await mirror.upsert(TimeSpan.test(
            id: id, title: "from A", serverRevision: 3,
            updatedAt: instant, deviceID: Fixed.deviceA
        ))
        #expect(try await mirror.fetch(TimeSpan.self, id: id)?.title == "from B")
    }

    // MARK: - Range queries

    @Test("a date-range query returns only overlapping spans")
    func rangeQuery() async throws {
        let store = try TimelyLocalStore()

        let before = TimeSpan.test(title: "before", start: Fixed.date(0), end: Fixed.date(100))
        let inside = TimeSpan.test(title: "inside", start: Fixed.date(200), end: Fixed.date(300))
        let straddling = TimeSpan.test(
            title: "straddling", start: Fixed.date(150), end: Fixed.date(600)
        )
        let after = TimeSpan.test(title: "after", start: Fixed.date(900), end: Fixed.date(1000))

        try await store.upsertAll([before, inside, straddling, after])

        let window = try await store.fetchInRange(
            TimeSpan.self,
            workspaceID: Fixed.workspace,
            from: Fixed.date(180),
            to: Fixed.date(700)
        )
        let titles = Set(window.map(\.title))

        #expect(titles == ["inside", "straddling"])
    }

    /// An open span has no end, so it overlaps every window that starts after it.
    @Test("an open span overlaps every later window")
    func openSpanOverlaps() async throws {
        let store = try TimelyLocalStore()
        try await store.upsert(TimeSpan.test(title: "running", start: Fixed.date(0), end: nil))

        let window = try await store.fetchInRange(
            TimeSpan.self,
            workspaceID: Fixed.workspace,
            from: Fixed.date(5000),
            to: Fixed.date(6000)
        )
        #expect(window.count == 1)
    }

    /// Two live spans at the same instant are legal (§8 row 8). Any code that
    /// assumes a single active timer is wrong.
    @Test("multiple open spans are legal and all are returned")
    func multipleOpenSpans() async throws {
        let store = try TimelyLocalStore()
        try await store.upsert(TimeSpan.test(title: "one", start: Fixed.date(0), end: nil))
        try await store.upsert(TimeSpan.test(title: "two", start: Fixed.date(10), end: nil))

        let open = try await store.openSpans(workspaceID: Fixed.workspace)
        #expect(open.count == 2)
    }

    @Test("range queries page")
    func rangePaging() async throws {
        let store = try TimelyLocalStore()
        let spans = (0..<25).map {
            TimeSpan.test(
                title: "span-\($0)",
                start: Fixed.date(Double($0) * 100),
                end: Fixed.date(Double($0) * 100 + 50)
            )
        }
        try await store.upsertAll(spans)

        let first = try await store.fetchInRange(
            TimeSpan.self, workspaceID: Fixed.workspace,
            from: Fixed.date(-1), to: Fixed.date(100_000), limit: 10, offset: 0
        )
        let second = try await store.fetchInRange(
            TimeSpan.self, workspaceID: Fixed.workspace,
            from: Fixed.date(-1), to: Fixed.date(100_000), limit: 10, offset: 10
        )

        #expect(first.count == 10)
        #expect(second.count == 10)
        #expect(Set(first.map(\.id)).isDisjoint(with: Set(second.map(\.id))))
        // Newest first.
        #expect(first.first?.title == "span-24")
    }

    // MARK: - Children and search

    @Test("children resolve through the promoted parent column")
    func children() async throws {
        let store = try TimelyLocalStore()
        let span = TimeSpan.test()
        try await store.upsert(span)

        let shotA = Screenshot.test(spanID: span.id)
        let shotB = Screenshot.test(spanID: span.id)
        let unrelated = Screenshot.test(spanID: UUID())
        try await store.upsertAll([shotA, shotB, unrelated])

        let found = try await store.fetchChildren(Screenshot.self, parentID: span.id)
        #expect(found.count == 2)
    }

    /// Search runs on canonicalized text, so it matches on the same rules the
    /// taxonomy does — including the smart-apostrophe fold.
    @Test("search is canonicalized")
    func searchIsCanonicalized() async throws {
        let store = try TimelyLocalStore()
        try await store.upsert(TimeSpan.test(title: "Bob\u{2019}s Diner rollout", clientName: "Bob\u{2019}s Diner"))

        let byAscii = try await store.search(
            TimeSpan.self, workspaceID: Fixed.workspace, matching: "bob's diner"
        )
        let byCase = try await store.search(
            TimeSpan.self, workspaceID: Fixed.workspace, matching: "BOB'S"
        )

        #expect(byAscii.count == 1)
        #expect(byCase.count == 1)
    }

    /// A vision analysis's `rawResponse` is image-equivalent. It must not become
    /// searchable text on a device that never earned the pixels.
    @Test("raw vision response is excluded from the search index")
    func rawResponseIsNotSearchable() async throws {
        let store = try TimelyLocalStore()
        var analysis = VisionAnalysis.test(screenshotID: UUID())
        analysis.rawResponse = "SUPERSECRETTRANSCRIPTION of the entire screen"
        try await store.upsert(analysis)

        let hits = try await store.search(
            VisionAnalysis.self, workspaceID: Fixed.workspace, matching: "supersecrettranscription"
        )
        #expect(hits.isEmpty)

        // The visible summary is still searchable.
        let visible = try await store.search(
            VisionAnalysis.self, workspaceID: Fixed.workspace, matching: "timeline canvas"
        )
        #expect(visible.count == 1)
    }

    // MARK: - Counting and persistence

    @Test("counts exclude tombstones by default")
    func counts() async throws {
        let store = try TimelyLocalStore()
        let live = TimeSpan.test()
        let dead = TimeSpan.test(deletedAt: Fixed.date(10))
        try await store.upsertAll([live, dead])

        #expect(try await store.count(.timeSpan, workspaceID: Fixed.workspace) == 1)
        #expect(
            try await store.count(.timeSpan, workspaceID: Fixed.workspace, includeDeleted: true) == 2
        )
    }

    @Test("an on-disk store survives being closed and reopened")
    func persistence() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("timely.sqlite3")
        defer { try? FileManager.default.removeItem(at: directory) }

        let span = TimeSpan.test(title: "durable")
        do {
            let store = try TimelyLocalStore(url: url)
            try await store.upsert(span)
        }

        let reopened = try TimelyLocalStore(url: url)
        #expect(try await reopened.fetch(TimeSpan.self, id: span.id)?.title == "durable")
    }

    @Test("workspaces are isolated")
    func workspaceIsolation() async throws {
        let store = try TimelyLocalStore()
        let other = UUID()

        try await store.upsert(TimeSpan.test(title: "ours"))
        try await store.upsert(TimeSpan.test(title: "theirs", workspaceID: other))

        let ours = try await store.fetchAll(TimeSpan.self, workspaceID: Fixed.workspace)
        #expect(ours.count == 1)
        #expect(ours.first?.title == "ours")
    }
}
