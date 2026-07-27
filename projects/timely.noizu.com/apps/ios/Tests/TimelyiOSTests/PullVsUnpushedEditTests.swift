import Foundation
import Testing
import TimelyKit
@testable import TimelyiOS

/// Does a pull clobber an edit that has not been pushed yet?
///
/// `SYNC-PROTOCOL.md` §7.1: "the local edit wins in the UI until it is pushed
/// and answered." If a pull overwrites a queued edit, the user watches their
/// change revert on screen while the mutation is still in the outbox, concludes
/// it was lost, and redoes it — producing exactly the duplicate the protocol
/// spends §8.3 detecting.
///
/// This is an **independent, app-level** answer: a real `TimelyLocalStore`, a
/// real `SyncEngine`, a real `TimelyAPIClient`, and a scripted HTTP body decoded
/// by the real wire types. Nothing is stubbed below the transport, so the thing
/// under test is the whole pull path as the app actually runs it.
///
/// Deliberately NOT relying on last-writer-wins. LWW protects a local edit only
/// when its clock is newer; it says nothing about whether the edit was pushed.
/// Every scenario here gives the incoming row a **higher `server_revision`**,
/// which is how a real change feed behaves and which makes `shouldReplace`
/// return true before any timestamp is compared.
@Suite("Pull vs unpushed local edits")
@MainActor
struct PullVsUnpushedEditTests {

    // MARK: - Harness

    /// A signed-in environment whose transport replays one scripted page.
    private func makeEnvironment(
        pageJSON: String
    ) async -> (AppEnvironment, StubTransport) {
        let transport = StubTransport()
        transport.script([.json(200, pageJSON)])

        let environment = AppEnvironment.inMemory(
            context: Fixture.context, transport: transport
        )
        await environment.bootstrap()

        // A live session, so the pull runs the authenticated path rather than
        // being skipped.
        try? await environment.auth?.adopt(
            AuthTokens(
                accessToken: "test-access",
                refreshToken: "test-refresh",
                expiresAt: Date().addingTimeInterval(3600),
                userID: Fixture.userID,
                workspaceID: Fixture.workspaceID
            )
        )
        return (environment, transport)
    }

    /// One page of the change feed carrying `spans`.
    private func page(_ spans: [TimeSpan], nextCursor: Int64) throws -> String {
        let encoded = try spans.map { try TimelyJSON.encodeToString($0) }
        return """
        {
          "changes": { "time_spans": [\(encoded.joined(separator: ","))] },
          "next_cursor": \(nextCursor),
          "has_more": false,
          "tombstone_horizon_revision": 0,
          "server_time": "2025-06-15T15:06:40Z"
        }
        """
    }

    /// Apply an edit and **prove it landed locally** before the pull runs.
    ///
    /// This precondition is not ceremony. `recordLocalChange` queues the
    /// mutation whether or not the local upsert wins, so a seed whose
    /// `updated_at` is newer than the edit produces a test that queues a
    /// mutation, never changes the row, and then "passes" its queue assertion
    /// while measuring a row the edit never reached. That is the append-only
    /// blind spot in miniature, and it bit this very file on the first run.
    private func applyUnpushedEdit(
        _ repository: TimelyRepository,
        id: UUID,
        expecting title: String,
        _ mutate: (inout TimeSpan) -> Void
    ) async throws {
        var edited = try #require(try await repository.span(id: id))
        mutate(&edited)
        try await repository.apply(
            SpanCorrectionPlan(updates: [edited]), at: Fixture.tick(2)
        )

        #expect(
            try await repository.span(id: id)?.title == title,
            "precondition: the unpushed edit must land locally before the pull, or this test measures nothing"
        )
        #expect(try await repository.queueDepth() == 1)
    }

    /// Seed the local copy of a server row at an older revision.
    ///
    /// `updated_at` is pinned strictly **older** than the edit that follows, so
    /// the edit itself is not dropped by LWW before the pull is even involved.
    private func seedLocal(
        _ environment: AppEnvironment,
        from serverRow: TimeSpan,
        revision: Int64,
        _ adjust: (inout TimeSpan) -> Void = { _ in }
    ) async throws {
        var local = serverRow
        local.sync.serverRevision = revision
        local.sync.updatedAt = Fixture.tick(1)
        local.sync.deletedAt = nil
        adjust(&local)
        try await environment.store?.upsert(local, markDirty: false)
    }

    /// A row the server has already acknowledged, seeded without dirtying it.
    private func seedServerRow(
        _ environment: AppEnvironment,
        title: String,
        billable: Bool = false,
        revision: Int64,
        updatedAt: Date
    ) async throws -> TimeSpan {
        let span = TimeSpan(
            sync: SyncEnvelope(
                id: UUID.v7(at: Fixture.tick(0)),
                workspaceID: Fixture.workspaceID,
                createdAt: Fixture.tick(0),
                updatedAt: updatedAt,
                serverRevision: revision,
                originDeviceID: Fixture.deviceID
            ),
            title: title,
            start: Fixture.tick(0),
            end: Fixture.tick(60),
            source: .timer,
            isBillable: billable,
            reviewState: .unreviewed
        )
        try await environment.store?.upsert(span, markDirty: false)
        return span
    }

    // MARK: - The question

    @Test("A pull does NOT overwrite an edit still waiting in the outbox")
    func pullPreservesUnpushedEdit() async throws {
        // Build the server's *newer-revision but older-content* copy first, so
        // it can be scripted into the page.
        let id = UUID.v7(at: Fixture.tick(0))
        var serverCopy = TimeSpan(
            sync: SyncEnvelope(
                id: id,
                workspaceID: Fixture.workspaceID,
                createdAt: Fixture.tick(0),
                updatedAt: Fixture.tick(1),
                serverRevision: 6,
                originDeviceID: Fixture.deviceID
            ),
            title: "Server title",
            start: Fixture.tick(0),
            end: Fixture.tick(60),
            source: .timer,
            isBillable: false
        )
        serverCopy.notes = "server notes"

        let (environment, transport) = await makeEnvironment(
            pageJSON: try page([serverCopy], nextCursor: 6)
        )
        let repository = try #require(environment.repository)

        // Seed the local copy at the older revision the client already had.
        try await seedLocal(environment, from: serverCopy, revision: 5) {
            $0.title = "Server title"
            $0.notes = ""
        }

        // The user edits it. Queued, not pushed.
        try await applyUnpushedEdit(repository, id: id, expecting: "MY EDIT") {
            $0.title = "MY EDIT"
            $0.isBillable = true
        }

        // A pull lands before the queue drains.
        _ = try await environment.syncEngine?.pull()
        #expect(transport.requestCount >= 1)

        let after = try #require(try await repository.span(id: id))

        // The user's edit survives. This is the whole question.
        #expect(after.title == "MY EDIT")
        #expect(after.isBillable == true)

        // And the server's envelope is adopted underneath it, so the client is
        // not stuck re-fetching the same revision forever.
        #expect(after.sync.serverRevision == 6)

        // The mutation is still queued — preservation must not swallow it.
        #expect(try await repository.queueDepth() == 1)
    }

    @Test("A pulled tombstone still wins over an unpushed edit")
    func tombstoneIsAbsorbing() async throws {
        let id = UUID.v7(at: Fixture.tick(0))
        var serverTombstone = TimeSpan(
            sync: SyncEnvelope(
                id: id,
                workspaceID: Fixture.workspaceID,
                createdAt: Fixture.tick(0),
                updatedAt: Fixture.tick(3),
                serverRevision: 7,
                deletedAt: Fixture.tick(3),
                originDeviceID: Fixture.deviceID
            ),
            title: "Server title",
            start: Fixture.tick(0),
            end: Fixture.tick(60),
            source: .timer
        )
        serverTombstone.sync.deletedAt = Fixture.tick(3)

        let (environment, _) = await makeEnvironment(
            pageJSON: try page([serverTombstone], nextCursor: 7)
        )
        let repository = try #require(environment.repository)

        try await seedLocal(environment, from: serverTombstone, revision: 5)
        try await applyUnpushedEdit(repository, id: id, expecting: "MY EDIT") {
            $0.title = "MY EDIT"
        }

        _ = try await environment.syncEngine?.pull()

        // Conflict matrix row 2: a tombstone is absorbing. Deleting something
        // another device deleted is not a change the user can be asked to
        // reconcile, and resurrecting it would be worse than losing the edit.
        // The tombstone is present in the store …
        let after = try await environment.store?.fetch(TimeSpan.self, id: id)
        #expect(after?.isDeleted == true)

        // … and the row has left the live timeline the user reads.
        let live = try await repository.spans(in: Fixture.day())
        #expect(live.contains { $0.id == id } == false)
    }

    @Test("A flag raised while the user was editing still reaches them")
    func serverReviewFlagsSurvivePreservation() async throws {
        let id = UUID.v7(at: Fixture.tick(0))
        let otherID = UUID.v7(at: Fixture.tick(1))

        var flagged = TimeSpan(
            sync: SyncEnvelope(
                id: id,
                workspaceID: Fixture.workspaceID,
                createdAt: Fixture.tick(0),
                updatedAt: Fixture.tick(3),
                serverRevision: 8,
                originDeviceID: Fixture.deviceID
            ),
            title: "Server title",
            start: Fixture.tick(0),
            end: Fixture.tick(60),
            source: .timer,
            reviewState: .needsReview,
            reviewReasons: [Fixture.reason(.suspectedDuplicate, related: otherID)]
        )
        flagged.notes = "server notes"

        let (environment, _) = await makeEnvironment(
            pageJSON: try page([flagged], nextCursor: 8)
        )
        let repository = try #require(environment.repository)

        try await seedLocal(environment, from: flagged, revision: 5) {
            $0.reviewState = .unreviewed
            $0.reviewReasons = []
        }
        try await applyUnpushedEdit(repository, id: id, expecting: "MY EDIT") {
            $0.title = "MY EDIT"
        }

        _ = try await environment.syncEngine?.pull()

        let after = try #require(try await repository.span(id: id))

        // The edit survives …
        #expect(after.title == "MY EDIT")
        // … AND the server's flag reaches the user. A local edit must not
        // swallow a `suspected_duplicate` raised while they were typing, or the
        // duplicate is never surfaced at all.
        #expect(after.reviewState == .needsReview)
        #expect(after.pendingReviewReasons.count == 1)
        #expect(after.pendingReviewReasons.first?.code == .suspectedDuplicate)
        #expect(after.needsReview)

        // And it reaches the review queue the user actually looks at.
        let queue = ReviewItemBuilder.items(spans: [after])
        #expect(queue.contains { $0.requiresUserJudgement })
    }

    @Test("A row with nothing queued takes the server's content, as it should")
    func cleanRowIsOverwritten() async throws {
        let id = UUID.v7(at: Fixture.tick(0))
        let serverCopy = TimeSpan(
            sync: SyncEnvelope(
                id: id,
                workspaceID: Fixture.workspaceID,
                createdAt: Fixture.tick(0),
                updatedAt: Fixture.tick(3),
                serverRevision: 9,
                originDeviceID: Fixture.deviceID
            ),
            title: "Renamed on another device",
            start: Fixture.tick(0),
            end: Fixture.tick(60),
            source: .timer
        )

        let (environment, _) = await makeEnvironment(
            pageJSON: try page([serverCopy], nextCursor: 9)
        )
        let repository = try #require(environment.repository)

        try await seedLocal(environment, from: serverCopy, revision: 5) {
            $0.title = "Old title"
        }

        // No local edit, so nothing to protect.
        #expect(try await repository.queueDepth() == 0)
        #expect(try await repository.span(id: id)?.title == "Old title")

        _ = try await environment.syncEngine?.pull()

        let after = try #require(try await repository.span(id: id))
        // Preservation must be narrow: it protects unpushed edits, not every
        // local row. A device that made no change takes the server's content.
        #expect(after.title == "Renamed on another device")
        #expect(after.sync.serverRevision == 9)
    }

    /// The other direction, and the subtle one.
    ///
    /// A pull and a push *result* both touch a row with a pending mutation, and
    /// they must behave **oppositely**. On a `conflict` or `rejected` result the
    /// server is adjudicating the very mutation still in the queue, so the
    /// client must adopt the authoritative row — defending the edit there would
    /// leave a rejected change on screen looking as though it had succeeded,
    /// and the user would never learn it was refused.
    ///
    /// So "the row has a pending mutation" is not a sufficient condition for
    /// preservation. The scope is the *path*, which is why `SyncEngine.apply`
    /// sets `preserveUnpushedEdits: true` on the pull and push-result adoption
    /// deliberately does not.
    @Test("A push result ADOPTS the authoritative row instead of defending the edit")
    func pushResultAdoptsAuthoritativeRow() async throws {
        let id = UUID.v7(at: Fixture.tick(0))
        let localSeed = TimeSpan(
            sync: SyncEnvelope(
                id: id,
                workspaceID: Fixture.workspaceID,
                createdAt: Fixture.tick(0),
                updatedAt: Fixture.tick(1),
                serverRevision: 5,
                originDeviceID: Fixture.deviceID
            ),
            title: "Server title",
            start: Fixture.tick(0),
            end: Fixture.tick(60),
            source: .timer
        )

        let transport = StubTransport()
        let environment = AppEnvironment.inMemory(
            context: Fixture.context, transport: transport
        )
        await environment.bootstrap()
        try? await environment.auth?.adopt(
            AuthTokens(
                accessToken: "a", refreshToken: "r",
                expiresAt: Date().addingTimeInterval(3600),
                userID: Fixture.userID, workspaceID: Fixture.workspaceID
            )
        )
        let repository = try #require(environment.repository)
        let store = try #require(environment.store)

        try await store.upsert(localSeed, markDirty: false)
        try await applyUnpushedEdit(repository, id: id, expecting: "MY EDIT") {
            $0.title = "MY EDIT"
        }

        // The server refuses the edit and returns ITS authoritative row.
        let queued = try await store.nextBatch(workspaceID: Fixture.workspaceID, limit: 10)
        let mutationID = try #require(queued.first?.mutationID)

        var authoritative = localSeed
        authoritative.sync.serverRevision = 9
        authoritative.title = "AUTHORITATIVE"

        transport.script([
            .json(200, """
            {
              "results": [{
                "mutation_id": "\(mutationID.canonicalString)",
                "status": "rejected",
                "reason": "stale_write",
                "entity_kind": "time_span",
                "entity": \(try TimelyJSON.encodeToString(authoritative)),
                "side_effects": [],
                "replayed": false,
                "stale_base": true,
                "unresolved_refs": []
              }],
              "next_cursor": 9,
              "server_time": "2025-06-15T15:06:40Z"
            }
            """)
        ])

        _ = try await environment.syncEngine?.push()

        let after = try #require(try await repository.span(id: id))

        // The local edit is REPLACED. It lost, and the user must see that.
        #expect(after.title == "AUTHORITATIVE")
        #expect(after.sync.serverRevision == 9)

        // The mutation is terminal, so it leaves the queue …
        #expect(try await repository.queueDepth() == 0)
        // … and is parked for a human rather than silently dropped.
        let outcomes = try await repository.pendingOutcomes()
        #expect(outcomes.contains { $0.mutationID == mutationID })
        #expect(outcomes.first?.status == .rejected)
    }

    /// Negative control: name the observation that would differ if the guard
    /// were absent.
    ///
    /// Without this, "the edit survived" is only evidence that *something*
    /// preserved it — LWW, luck, or a seed that happened to win. This drives the
    /// same store with `preserveUnpushedEdits` at its default of `false`, which
    /// is exactly what `SyncEngine.apply` would do if the flag were ever
    /// dropped, and shows the edit IS destroyed. So the flag is load-bearing and
    /// the four tests above are measuring it rather than an accident.
    ///
    /// Deliberately reaches past `SyncEngine` to the store instead of editing
    /// TimelyKit to flip the flag — that package is off limits, and other agents
    /// are working in it.
    @Test("Negative control: without the preservation flag the edit IS clobbered")
    func negativeControlWithoutPreservation() async throws {
        let id = UUID.v7(at: Fixture.tick(0))
        let serverCopy = TimeSpan(
            sync: SyncEnvelope(
                id: id,
                workspaceID: Fixture.workspaceID,
                createdAt: Fixture.tick(0),
                updatedAt: Fixture.tick(3),
                serverRevision: 6,
                originDeviceID: Fixture.deviceID
            ),
            title: "Server title",
            start: Fixture.tick(0),
            end: Fixture.tick(60),
            source: .timer
        )

        let (environment, _) = await makeEnvironment(
            pageJSON: try page([serverCopy], nextCursor: 6)
        )
        let repository = try #require(environment.repository)
        let store = try #require(environment.store)

        try await seedLocal(environment, from: serverCopy, revision: 5)
        try await applyUnpushedEdit(repository, id: id, expecting: "MY EDIT") {
            $0.title = "MY EDIT"
        }

        // The pull path's write, minus the one flag that protects it.
        try await store.upsertAll([serverCopy])

        let after = try #require(try await repository.span(id: id))
        #expect(after.title == "Server title")   // the user's edit is gone
        // …while their mutation still sits in the outbox. This is precisely the
        // sequence that makes a user redo work and create a duplicate.
        #expect(try await repository.queueDepth() == 1)
    }

    @Test("Preservation survives a second pull while the edit is still queued")
    func repeatedPullsKeepPreserving() async throws {
        let id = UUID.v7(at: Fixture.tick(0))
        let serverCopy = TimeSpan(
            sync: SyncEnvelope(
                id: id,
                workspaceID: Fixture.workspaceID,
                createdAt: Fixture.tick(0),
                updatedAt: Fixture.tick(3),
                serverRevision: 6,
                originDeviceID: Fixture.deviceID
            ),
            title: "Server title",
            start: Fixture.tick(0),
            end: Fixture.tick(60),
            source: .timer
        )

        let transport = StubTransport()
        // Two pages: revision 6, then revision 7. The queue never drains.
        var second = serverCopy
        second.sync.serverRevision = 7
        transport.script([
            .json(200, try page([serverCopy], nextCursor: 6)),
            .json(200, try page([second], nextCursor: 7))
        ])

        let environment = AppEnvironment.inMemory(
            context: Fixture.context, transport: transport
        )
        await environment.bootstrap()
        try? await environment.auth?.adopt(
            AuthTokens(
                accessToken: "a", refreshToken: "r",
                expiresAt: Date().addingTimeInterval(3600),
                userID: Fixture.userID, workspaceID: Fixture.workspaceID
            )
        )
        let repository = try #require(environment.repository)

        try await seedLocal(environment, from: serverCopy, revision: 5)
        try await applyUnpushedEdit(repository, id: id, expecting: "MY EDIT") {
            $0.title = "MY EDIT"
        }

        _ = try await environment.syncEngine?.pull()
        #expect(try await repository.span(id: id)?.title == "MY EDIT")

        _ = try await environment.syncEngine?.pull()
        // Still preserved. A user with a long-lived outbox — the offline case
        // this app is built for — must not lose the edit on the third pull.
        #expect(try await repository.span(id: id)?.title == "MY EDIT")
        #expect(try await repository.queueDepth() == 1)
    }
}
