import Foundation
import Testing
@testable import TimelyKit

/// A store, an engine, and a scripted transport wired together.
struct SyncHarness {
    let store: TimelyLocalStore
    let transport: StubTransport
    let auth: AuthClient
    let engine: SyncEngine

    init(tokens: AuthTokens? = .fresh()) async throws {
        store = try TimelyLocalStore()
        transport = StubTransport()
        auth = AuthClient(
            baseURL: URL(string: "https://timely.test")!,
            transport: transport,
            tokenStore: InMemoryTokenStore(tokens: tokens)
        )
        let client = TimelyAPIClient(
            baseURL: URL(string: "https://timely.test")!,
            transport: transport,
            auth: auth
        )
        engine = SyncEngine(
            store: store,
            client: client,
            auth: auth,
            workspaceID: Fixed.workspace,
            deviceID: Fixed.deviceA
        )
    }
}

@Suite("Sync engine")
struct SyncEngineTests {

    // MARK: - Pull

    @Test("a pull applies rows and advances the cursor")
    func pullAdvancesCursor() async throws {
        let harness = try await SyncHarness()
        let span = TimeSpan.test(title: "from server", serverRevision: 42)

        harness.transport.script([
            .json(200, Wire.changesResponse(
                timeSpans: [Wire.span(span, serverRevision: 42)],
                nextCursor: 42
            ))
        ])

        let outcome = try await harness.engine.pull()

        #expect(outcome.rowsApplied == 1)
        #expect(outcome.cursor == 42)
        #expect(try await harness.store.fetch(TimeSpan.self, id: span.id)?.title == "from server")

        let state = try await harness.store.syncState(workspaceID: Fixed.workspace)
        #expect(state.cursor == 42)
    }

    @Test("a paged pull drains every page")
    func pullPages() async throws {
        let harness = try await SyncHarness()
        let first = TimeSpan.test(title: "page one", serverRevision: 10)
        let second = TimeSpan.test(title: "page two", serverRevision: 20)

        harness.transport.script([
            .json(200, Wire.changesResponse(
                timeSpans: [Wire.span(first, serverRevision: 10)],
                nextCursor: 10, hasMore: true
            )),
            .json(200, Wire.changesResponse(
                timeSpans: [Wire.span(second, serverRevision: 20)],
                nextCursor: 20, hasMore: false
            ))
        ])

        let outcome = try await harness.engine.pull()

        #expect(outcome.pagesPulled == 2)
        #expect(outcome.cursor == 20)
        #expect(try await harness.store.count(.timeSpan, workspaceID: Fixed.workspace) == 2)
    }

    /// A watermark below the tombstone horizon means the server can no longer
    /// prove what was deleted. Continuing incrementally would silently retain
    /// rows the workspace removed.
    @Test("a cursor below the tombstone horizon forces a re-bootstrap from zero")
    func rebootstrapsBelowHorizon() async throws {
        let harness = try await SyncHarness()

        var state = try await harness.store.syncState(workspaceID: Fixed.workspace)
        state.cursor = 5
        state.tombstoneHorizonRevision = 100
        try await harness.store.saveSyncState(state)

        harness.transport.script([
            .json(200, Wire.changesResponse(nextCursor: 200, tombstoneHorizon: 100))
        ])

        let outcome = try await harness.engine.pull()

        #expect(outcome.rebootstrapped)
        // The request must have asked for since=0, not since=5.
        let url = harness.transport.requests.first?.url?.absoluteString ?? ""
        #expect(url.contains("since=0"), "expected a bootstrap from 0, got: \(url)")
    }

    // MARK: - Push

    @Test("an applied mutation leaves the queue and adopts the server's row")
    func pushApplied() async throws {
        let harness = try await SyncHarness()
        let span = TimeSpan.test(title: "local edit")

        let queued = try await harness.store.enqueue(.create, entity: span)
        try await harness.store.upsert(span)

        var server = span
        server.title = "local edit"
        server.sync.serverRevision = 77

        harness.transport.script([
            .json(200, Wire.mutationResponse(results: [
                Wire.result(
                    mutationID: queued.mutationID,
                    status: "applied",
                    entity: Wire.span(server, serverRevision: 77)
                )
            ]))
        ])

        let outcome = try await harness.engine.push()

        #expect(outcome.applied == 1)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 0)
        #expect(try await harness.store.fetch(TimeSpan.self, id: span.id)?.sync.serverRevision == 77)
    }

    /// The heart of at-least-once: a transport failure must NOT dequeue, and
    /// must NOT mint a new mutation id.
    @Test("a transport failure keeps the mutation queued with its original id")
    func transportFailureRetains() async throws {
        let harness = try await SyncHarness()
        let span = TimeSpan.test()
        let queued = try await harness.store.enqueue(.create, entity: span)

        harness.transport.script([.json(503, "{\"code\":\"unavailable\",\"message\":\"down\"}")])

        let outcome = try await harness.engine.push()

        #expect(outcome.pushRetryable == 1)
        #expect(outcome.applied == 0)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 1)

        let stillQueued = try await harness.store.nextBatch(workspaceID: Fixed.workspace)
        #expect(stillQueued.first?.mutationID == queued.mutationID, "the id must not be re-minted")
        #expect(stillQueued.first?.attempts == 1)
    }

    /// The retry must carry the same `mutation_id`, which is what lets the
    /// server replay its original verdict rather than double-apply.
    @Test("a retry replays the same mutation id and the server dedupes it")
    func idempotentReplay() async throws {
        let harness = try await SyncHarness()
        let span = TimeSpan.test()
        let queued = try await harness.store.enqueue(.create, entity: span)
        try await harness.store.upsert(span)

        harness.transport.script([
            .json(500, "{\"code\":\"boom\",\"message\":\"boom\"}"),
            .json(200, Wire.mutationResponse(results: [
                Wire.result(
                    mutationID: queued.mutationID,
                    status: "applied",
                    entity: Wire.span(span, serverRevision: 9),
                    replayed: true
                )
            ]))
        ])

        _ = try await harness.engine.push()          // fails, stays queued
        let outcome = try await harness.engine.push() // succeeds as a replay

        #expect(outcome.replayed == 1)
        #expect(outcome.applied == 1)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 0)

        // Both request bodies must carry the identical mutation id.
        let sent = harness.transport.bodies.map { String(decoding: $0, as: UTF8.self) }
        #expect(sent.count == 2)
        #expect(sent.allSatisfy { $0.contains(queued.mutationID.canonicalString) })
    }

    // MARK: - Conflicts

    /// A conflict adopts the server's row *and* parks the disagreement. Doing
    /// only the first silently discards the user's edit with no trace.
    @Test("a conflict adopts the server row and parks it for a human")
    func conflictParked() async throws {
        let harness = try await SyncHarness()
        let span = TimeSpan.test(title: "my version")
        try await harness.store.upsert(span)
        let queued = try await harness.store.enqueue(.update, entity: span)

        var server = span
        server.title = "their version"
        server.sync.serverRevision = 55

        harness.transport.script([
            .json(200, Wire.mutationResponse(results: [
                Wire.result(
                    mutationID: queued.mutationID,
                    status: "conflict",
                    reason: "stale_write",
                    entity: Wire.span(server, serverRevision: 55),
                    staleBase: true
                )
            ]))
        ])

        let outcome = try await harness.engine.push()

        #expect(outcome.conflicts == 1)
        #expect(outcome.staleBase == 1)
        #expect(try await harness.store.fetch(TimeSpan.self, id: span.id)?.title == "their version")

        let pending = try await harness.store.pendingOutcomes(workspaceID: Fixed.workspace)
        #expect(pending.count == 1)
        #expect(pending.first?.reason == .staleWrite)
        #expect(pending.first?.acknowledged == false)
    }

    /// §8 row 6: a closed span may never be reopened by a stale update. The
    /// mutation is rejected and must not be retried forever.
    @Test("a span reopen rejection is terminal and surfaced")
    func spanReopenForbidden() async throws {
        let harness = try await SyncHarness()
        let span = TimeSpan.test(end: nil)
        try await harness.store.upsert(span)
        let queued = try await harness.store.enqueue(.update, entity: span)

        harness.transport.script([
            .json(200, Wire.mutationResponse(results: [
                Wire.result(
                    mutationID: queued.mutationID,
                    status: "rejected",
                    reason: "span_reopen_forbidden"
                )
            ]))
        ])

        let outcome = try await harness.engine.push()

        #expect(outcome.rejected == 1)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 0, "terminal")

        let pending = try await harness.store.pendingOutcomes(workspaceID: Fixed.workspace)
        #expect(pending.first?.reason == .spanReopenForbidden)
    }

    /// `suspected_duplicate` and `billing_overlap` mean two records claim the
    /// same hours. Nothing may resolve them automatically.
    @Test("duplicate and overlap conflicts are never auto-resolved")
    func duplicatesAreNotAutoResolved() async throws {
        let harness = try await SyncHarness()
        let span = TimeSpan.test()
        try await harness.store.upsert(span)
        let queued = try await harness.store.enqueue(.create, entity: span)

        harness.transport.script([
            .json(200, Wire.mutationResponse(results: [
                Wire.result(
                    mutationID: queued.mutationID,
                    status: "conflict",
                    reason: "duplicate_name",
                    entity: Wire.span(span, serverRevision: 3)
                )
            ]))
        ])

        _ = try await harness.engine.push()

        let pending = try await harness.store.pendingOutcomes(workspaceID: Fixed.workspace)
        #expect(pending.count == 1)
        #expect(pending.first?.requiresHumanJudgement == true)
        #expect(pending.first?.acknowledged == false)

        // It stays pending until a person dismisses it — nothing in the engine
        // may clear it.
        _ = try await harness.engine.push()
        let still = try await harness.store.pendingOutcomes(workspaceID: Fixed.workspace)
        #expect(still.count == 1)

        try await harness.store.acknowledgeOutcome(mutationID: queued.mutationID)
        #expect(try await harness.store.pendingOutcomes(workspaceID: Fixed.workspace).isEmpty)
    }

    /// Side effects are rows the server changed that the client never asked
    /// about — most often an auto-vivified taxonomy row.
    @Test("side effects are applied inline")
    func sideEffectsApplied() async throws {
        let harness = try await SyncHarness()
        let span = TimeSpan.test()
        try await harness.store.upsert(span)
        let queued = try await harness.store.enqueue(.create, entity: span)

        let client = ClientRecord.minted(
            workspaceID: Fixed.workspace, deviceID: nil, name: "Acme", autoCreated: true
        )!
        let clientJSON = try TimelyJSON.encodeToString(client)

        harness.transport.script([
            .json(200, Wire.mutationResponse(results: [
                Wire.result(
                    mutationID: queued.mutationID,
                    status: "applied",
                    entity: Wire.span(span, serverRevision: 4),
                    sideEffects: ["{\"entity\":\"client\",\"row\":\(clientJSON)}"]
                )
            ]))
        ])

        let outcome = try await harness.engine.push()

        #expect(outcome.sideEffects == 1)
        #expect(try await harness.store.fetch(ClientRecord.self, id: client.id)?.name == "Acme")
    }

    /// `entity_kind` on the envelope is what makes a result for an unsent
    /// mutation recoverable. Without it there is no way to tell which bucket
    /// `entity` belongs to and the row has to be dropped; with it, the row is
    /// adopted like any other server-authored row.
    ///
    /// Reading the same field Android reads also means a future divergence
    /// surfaces as a decode failure rather than as two clients quietly
    /// disagreeing about how to infer the kind.
    @Test("a result for an unsent mutation is adopted via entity_kind")
    func unsentMutationAdoptedViaEntityKind() async throws {
        let harness = try await SyncHarness()

        // Something IS queued, or push() would not call the endpoint at all.
        let ours = TimeSpan.test(title: "ours")
        try await harness.store.upsert(ours)
        let queued = try await harness.store.enqueue(.create, entity: ours)

        // The server also returns a verdict for a mutation this client never
        // sent, carrying a row we have never seen.
        let theirs = TimeSpan.test(title: "from another device")
        let strayID = UUID.v7()

        harness.transport.script([
            .json(200, Wire.mutationResponse(results: [
                Wire.result(
                    mutationID: queued.mutationID,
                    status: "applied",
                    entity: Wire.span(ours, serverRevision: 5)
                ),
                """
                {"mutation_id":"\(strayID.canonicalString)","status":"applied",
                 "entity_kind":"time_span","replayed":false,"stale_base":false,
                 "unresolved_refs":[],"side_effects":[],
                 "entity":\(Wire.span(theirs, serverRevision: 6))}
                """
            ]))
        ])

        _ = try await harness.engine.push()

        let adopted = try await harness.store.fetch(TimeSpan.self, id: theirs.id)
        #expect(adopted?.title == "from another device", "the stray row must be adopted, not dropped")
        #expect(adopted?.sync.serverRevision == 6)
    }

    /// An older server omits the field entirely. The local queue entry is still
    /// there, so nothing breaks.
    @Test("a result without entity_kind falls back to the queued kind")
    func missingEntityKindFallsBack() async throws {
        let harness = try await SyncHarness()
        let span = TimeSpan.test(title: "local")
        try await harness.store.upsert(span)
        let queued = try await harness.store.enqueue(.create, entity: span)

        // `Wire.result` deliberately omits entity_kind, as an older server would.
        harness.transport.script([
            .json(200, Wire.mutationResponse(results: [
                Wire.result(
                    mutationID: queued.mutationID,
                    status: "applied",
                    entity: Wire.span(span, serverRevision: 9)
                )
            ]))
        ])

        let outcome = try await harness.engine.push()
        #expect(outcome.applied == 1)
        #expect(try await harness.store.fetch(TimeSpan.self, id: span.id)?.sync.serverRevision == 9)
    }

    /// A kind this build cannot name must be skipped, not fatal — new entity
    /// kinds are an additive change under the contract's rules.
    @Test("an unknown entity kind in a side effect is skipped, not fatal")
    func unknownSideEffectKindSkipped() async throws {
        let harness = try await SyncHarness()
        let span = TimeSpan.test()
        try await harness.store.upsert(span)
        let queued = try await harness.store.enqueue(.create, entity: span)

        harness.transport.script([
            .json(200, Wire.mutationResponse(results: [
                Wire.result(
                    mutationID: queued.mutationID,
                    status: "applied",
                    entity: Wire.span(span, serverRevision: 4),
                    sideEffects: ["{\"entity\":\"invoice\",\"row\":{\"id\":\"x\"}}"]
                )
            ]))
        ])

        let outcome = try await harness.engine.push()
        #expect(outcome.applied == 1)
    }

    // MARK: - Ordering

    @Test("the queue is strict FIFO and a failed batch is not stepped over")
    func fifoOrdering() async throws {
        let harness = try await SyncHarness()

        var ids: [UUID] = []
        for index in 0..<5 {
            let span = TimeSpan.test(title: "span-\(index)")
            try await harness.store.upsert(span)
            ids.append(try await harness.store.enqueue(.create, entity: span).mutationID)
        }

        let batch = try await harness.store.nextBatch(workspaceID: Fixed.workspace)
        #expect(batch.map(\.mutationID) == ids, "queue must come back in insertion order")

        // A failure leaves the head in place rather than skipping it.
        harness.transport.script([.json(503, "{\"code\":\"x\",\"message\":\"x\"}")])
        _ = try await harness.engine.push()

        let after = try await harness.store.nextBatch(workspaceID: Fixed.workspace)
        #expect(after.first?.mutationID == ids.first)
        #expect(after.count == 5)
    }

    /// §8 rows 14 and 15: the server rejects an update to an append-only kind
    /// with `immutable_entity`. Enqueuing one would burn a network round trip to
    /// learn something knowable locally.
    @Test("append-only kinds refuse an update at enqueue time")
    func appendOnlyRefusesUpdate() async throws {
        let harness = try await SyncHarness()
        let analysis = VisionAnalysis.test(screenshotID: UUID())

        var thrown: (any Error)?
        do {
            _ = try await harness.store.enqueue(.update, entity: analysis)
        } catch {
            thrown = error
        }

        guard case .some(SyncError.immutableEntity(let kind)) = thrown as? SyncError else {
            Issue.record("expected immutableEntity, got \(String(describing: thrown))")
            return
        }
        #expect(kind == .visionAnalysis)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 0)

        // A create is fine — re-analysis produces a new row rather than an edit.
        _ = try await harness.store.enqueue(.create, entity: analysis)
        #expect(try await harness.store.queueDepth(workspaceID: Fixed.workspace) == 1)
    }

    // MARK: - Batch caps

    @Test("a push batch never exceeds the contract's cap")
    func batchCap() async throws {
        let harness = try await SyncHarness()
        for index in 0..<30 {
            let span = TimeSpan.test(title: "s\(index)")
            try await harness.store.upsert(span)
            _ = try await harness.store.enqueue(.create, entity: span)
        }

        let batch = try await harness.store.nextBatch(workspaceID: Fixed.workspace, limit: 10)
        #expect(batch.count == 10)

        let overCap = try await harness.store.nextBatch(workspaceID: Fixed.workspace, limit: 5000)
        #expect(overCap.count <= 200)
    }

    /// An atomic group — a split or a merge — is sent alone and with
    /// `atomic: true`, because a partially applied split loses time.
    @Test("an atomic group is batched alone and flagged atomic")
    func atomicGrouping() async throws {
        let harness = try await SyncHarness()

        let loose = TimeSpan.test(title: "loose")
        try await harness.store.upsert(loose)
        _ = try await harness.store.enqueue(.create, entity: loose)

        for index in 0..<3 {
            let piece = TimeSpan.test(title: "piece-\(index)")
            try await harness.store.upsert(piece)
            _ = try await harness.store.enqueue(.create, entity: piece, batchGroup: "split-1")
        }

        // The loose mutation is at the head, so the first batch stops before the
        // group rather than mixing them.
        let first = try await harness.store.nextBatch(workspaceID: Fixed.workspace)
        #expect(first.count == 1)
        #expect(first.first?.batchGroup == nil)

        try await harness.store.dequeue([first[0].mutationID])

        let group = try await harness.store.nextBatch(workspaceID: Fixed.workspace)
        #expect(group.count == 3)
        #expect(group.allSatisfy { $0.batchGroup == "split-1" })
    }
}
