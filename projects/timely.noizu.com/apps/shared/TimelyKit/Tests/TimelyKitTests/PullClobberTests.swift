import Foundation
import Testing
@testable import TimelyKit

/// §7.1: "the local edit wins in the UI until it is pushed and answered."
///
/// The failure this guards against is the most user-visible one in the system:
/// a user edits a span offline, a pull lands before the queue drains carrying
/// the server's older copy, and their change reverts **on screen** while their
/// mutation is still sitting in the outbox. They assume it was lost and redo it
/// — and now there are two.
///
/// Written as a sequence rather than reasoned about, because the LWW rule looks
/// like it should cover this and does not: it protects a local edit only when
/// the local `updated_at` is newer, and says nothing about whether the edit has
/// been pushed.
@Suite("Pull must not clobber unpushed local edits")
struct PullClobberTests {

    /// The exact sequence, with the server row at a HIGHER revision — which is
    /// the ordinary case, since any concurrent server-side activity bumps it.
    @Test("a pulled row does not overwrite an edit still in the queue")
    func pullDoesNotClobberQueuedEdit() async throws {
        let store = try TimelyLocalStore()

        // 1. A span the server has already acknowledged.
        var span = TimeSpan.test(title: "original", serverRevision: 40)
        try await store.upsert(span, markDirty: false)

        // 2. The user edits it offline. Mutation queued; not yet pushed.
        span.title = "my offline edit"
        let (_, mutation) = try await store.recordLocalChange(
            .update, entity: span, deviceID: Fixed.deviceA, at: Fixed.date(10_000)
        )
        #expect(try await store.queueDepth(workspaceID: Fixed.workspace) == 1)

        // 3. A pull lands first, carrying the server's copy — same row, older
        //    content, higher revision.
        var serverCopy = TimeSpan.test(id: span.id, title: "original", serverRevision: 41)
        serverCopy.sync.updatedAt = Fixed.date(5_000)      // older than the local edit
        try await store.upsertAll([serverCopy], preserveUnpushedEdits: true)

        // 4. What does the user see?
        let onScreen = try await store.fetch(TimeSpan.self, id: span.id)

        #expect(
            onScreen?.title == "my offline edit",
            """
            §7.1 violated: the pull reverted the user's edit while their mutation \
            was still queued. They will redo it and create a duplicate.
            """
        )

        // The mutation must still be pending — it was never answered.
        #expect(try await store.queueDepth(workspaceID: Fixed.workspace) == 1)
        let stillQueued = try await store.nextBatch(workspaceID: Fixed.workspace)
        #expect(stillQueued.first?.mutationID == mutation.mutationID)
    }

    /// The half of the server's row that DOES have a job: the envelope.
    ///
    /// `server_revision` must be adopted even while local content is preserved,
    /// or the next push cites a stale `base_revision` — which is decisive for the
    /// reopen guard and for locked days.
    @Test("the server envelope is adopted underneath the local content")
    func serverEnvelopeIsAdopted() async throws {
        let store = try TimelyLocalStore()

        var span = TimeSpan.test(title: "original", serverRevision: 40)
        try await store.upsert(span, markDirty: false)

        span.title = "my offline edit"
        try await store.recordLocalChange(
            .update, entity: span, deviceID: Fixed.deviceA, at: Fixed.date(10_000)
        )

        var serverCopy = TimeSpan.test(id: span.id, title: "original", serverRevision: 41)
        serverCopy.sync.updatedAt = Fixed.date(5_000)
        try await store.upsertAll([serverCopy], preserveUnpushedEdits: true)

        let row = try await store.fetch(TimeSpan.self, id: span.id)
        #expect(row?.title == "my offline edit", "content stays local")
        #expect(row?.sync.serverRevision == 41, "revision comes from the server")
    }

    /// Exception 1 — a tombstone is absorbing (matrix row 2). A row deleted on
    /// the server must disappear even if this device has an unpushed edit.
    @Test("a server tombstone still wins over an unpushed edit")
    func tombstoneWinsOverLocalEdit() async throws {
        let store = try TimelyLocalStore()

        var span = TimeSpan.test(title: "original", serverRevision: 40)
        try await store.upsert(span, markDirty: false)

        span.title = "my offline edit"
        try await store.recordLocalChange(
            .update, entity: span, deviceID: Fixed.deviceA, at: Fixed.date(10_000)
        )

        var deleted = TimeSpan.test(id: span.id, title: "original", serverRevision: 41)
        deleted.sync.deletedAt = Fixed.date(6_000)
        deleted.sync.updatedAt = Fixed.date(6_000)
        try await store.upsertAll([deleted], preserveUnpushedEdits: true)

        #expect(
            try await store.fetch(TimeSpan.self, id: span.id)?.isDeleted == true,
            "a tombstone is absorbing regardless of local edits"
        )
    }

    /// Exception 2 — review reasons. A `suspected_duplicate` raised while the
    /// user was mid-edit must still reach them; a local edit must not swallow a
    /// server flag, or the review queue silently loses items.
    @Test("server review reasons survive an unpushed local edit")
    func reviewReasonsSurvive() async throws {
        let store = try TimelyLocalStore()

        var span = TimeSpan.test(title: "original", serverRevision: 40)
        try await store.upsert(span, markDirty: false)

        span.title = "my offline edit"
        try await store.recordLocalChange(
            .update, entity: span, deviceID: Fixed.deviceA, at: Fixed.date(10_000)
        )

        var flagged = TimeSpan.test(id: span.id, title: "original", serverRevision: 41)
        flagged.sync.updatedAt = Fixed.date(5_000)
        flagged.reviewState = .needsReview
        flagged.reviewReasons = [
            ReviewReason(code: .suspectedDuplicate, raisedAt: Fixed.date(5_000), raisedBy: .server)
        ]
        try await store.upsertAll([flagged], preserveUnpushedEdits: true)

        let row = try await store.fetch(TimeSpan.self, id: span.id)
        #expect(row?.title == "my offline edit", "content stays local")
        #expect(
            row?.reviewReasons.contains { $0.code == .suspectedDuplicate } == true,
            "a server-raised flag must reach the user even mid-edit"
        )
    }

    /// The store-level tests above pass `preserveUnpushedEdits: true` themselves,
    /// which proves the store honours it but NOT that the engine asks for it.
    /// This drives a real pull through `SyncEngine` so a future refactor that
    /// drops the flag fails here rather than in a user's hands.
    @Test("a real pull through SyncEngine preserves the unpushed edit")
    func enginePullPreservesLocalEdit() async throws {
        let harness = try await SyncHarness()

        var span = TimeSpan.test(title: "original", serverRevision: 40)
        try await harness.store.upsert(span, markDirty: false)

        span.title = "my offline edit"
        try await harness.store.recordLocalChange(
            .update, entity: span, deviceID: Fixed.deviceA, at: Fixed.date(10_000)
        )

        // The server's page carries its own older copy at a higher revision.
        var serverCopy = TimeSpan.test(id: span.id, title: "original", serverRevision: 41)
        serverCopy.sync.updatedAt = Fixed.date(5_000)

        harness.transport.script([
            .json(200, Wire.changesResponse(
                timeSpans: [Wire.span(serverCopy, serverRevision: 41)],
                nextCursor: 41
            ))
        ])

        _ = try await harness.engine.pull()

        let row = try await harness.store.fetch(TimeSpan.self, id: span.id)
        #expect(row?.title == "my offline edit", "the engine must request preservation on pull")
        #expect(row?.sync.serverRevision == 41, "and still adopt the server's revision")
    }

    /// A row with NO pending mutation is ordinary LWW — the preservation rule
    /// must not turn into "local always wins", which would strand this device.
    @Test("a pulled row overwrites a clean local row normally")
    func cleanRowIsOverwritten() async throws {
        let store = try TimelyLocalStore()

        let span = TimeSpan.test(title: "original", serverRevision: 40)
        try await store.upsert(span, markDirty: false)

        var serverCopy = TimeSpan.test(id: span.id, title: "from the server", serverRevision: 41)
        serverCopy.sync.updatedAt = Fixed.date(9_000)
        try await store.upsertAll([serverCopy], preserveUnpushedEdits: true)

        #expect(
            try await store.fetch(TimeSpan.self, id: span.id)?.title == "from the server",
            "with nothing queued, the server's newer row is simply adopted"
        )
    }

    /// And once the mutation is answered, the row is no longer protected.
    @Test("preservation ends when the mutation leaves the queue")
    func preservationEndsAfterPush() async throws {
        let store = try TimelyLocalStore()

        var span = TimeSpan.test(title: "original", serverRevision: 40)
        try await store.upsert(span, markDirty: false)

        span.title = "my offline edit"
        let (_, mutation) = try await store.recordLocalChange(
            .update, entity: span, deviceID: Fixed.deviceA, at: Fixed.date(10_000)
        )

        // The push succeeds and the mutation is dequeued.
        try await store.dequeue([mutation.mutationID])
        try await store.clearDirty(kind: .timeSpan, ids: [span.id])

        var serverCopy = TimeSpan.test(id: span.id, title: "server wins now", serverRevision: 42)
        serverCopy.sync.updatedAt = Fixed.date(20_000)
        try await store.upsertAll([serverCopy], preserveUnpushedEdits: true)

        #expect(
            try await store.fetch(TimeSpan.self, id: span.id)?.title == "server wins now",
            "nothing pending, so ordinary LWW resumes"
        )
    }
}
