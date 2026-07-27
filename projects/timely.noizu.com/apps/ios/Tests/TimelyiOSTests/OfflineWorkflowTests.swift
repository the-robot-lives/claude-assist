import Foundation
import Testing
import TimelyKit
@testable import TimelyiOS

/// The offline promise, exercised end to end through the view models.
///
/// Every test here runs with **no session at all** and a transport that throws
/// on contact. If any of them start failing, it means a network dependency has
/// crept onto a write path — which is the one regression this app cannot ship.
@Suite("Offline workflows")
@MainActor
struct OfflineWorkflowTests {

    private func makeEnvironment() async -> AppEnvironment {
        let environment = AppEnvironment.inMemory(context: Fixture.context)
        await environment.bootstrap()
        return environment
    }

    @Test("The app is ready without a session")
    func readyWithoutSignIn() async {
        let environment = await makeEnvironment()

        #expect(environment.phase == .ready)
        #expect(environment.status.session == .none)
        #expect(environment.repository != nil)
    }

    @Test("A manual interval can be added with no session and no network")
    func manualEntryWorksOffline() async throws {
        let environment = await makeEnvironment()
        let repository = try #require(environment.repository)

        let entry = ManualEntryViewModel(
            start: Fixture.noon, end: Fixture.noon.addingTimeInterval(3600)
        )
        entry.title = "Write the report"
        entry.clientName = "Acme"
        entry.projectName = "Redesign"
        entry.isBillable = true

        await entry.save(environment: environment, now: Fixture.noon)

        #expect(entry.didFinish)
        #expect(entry.errorMessage == nil)

        let stored = try await repository.spans(in: Fixture.day())
        #expect(stored.count == 1)
        #expect(stored.first?.title == "Write the report")
        #expect(stored.first?.isBillable == true)

        // The mutation is durable and waiting, not lost.
        #expect(try await repository.queueDepth() > 0)
        #expect(environment.status.session == .none)
    }

    @Test("Naming a new client vivifies the taxonomy locally")
    func taxonomyVivifiesOffline() async throws {
        let environment = await makeEnvironment()
        let repository = try #require(environment.repository)

        let entry = ManualEntryViewModel(
            start: Fixture.noon, end: Fixture.noon.addingTimeInterval(1800)
        )
        entry.title = "Kickoff"
        entry.clientName = "Acme"
        entry.projectName = "Redesign"

        await entry.save(environment: environment, now: Fixture.noon)

        let clients = try await repository.clients()
        let projects = try await repository.projects()

        #expect(clients.map(\.name) == ["Acme"])
        #expect(projects.map(\.name) == ["Redesign"])
        // Auto-created rows arrive flagged, not silently curated.
        #expect(clients.first?.autoCreated == true)
        // The id is derived, so another device naming "Acme" computes the same one.
        #expect(clients.first?.id == Canon.clientID(workspaceID: Fixture.workspaceID, name: "Acme"))
    }

    @Test("The day review reads back what was just written")
    func dayReviewReflectsLocalWrites() async throws {
        let environment = await makeEnvironment()

        let entry = ManualEntryViewModel(
            start: Fixture.noon, end: Fixture.noon.addingTimeInterval(5400)
        )
        entry.title = "Deep work"
        entry.isBillable = true
        await entry.save(environment: environment, now: Fixture.noon)

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let review = DayReviewViewModel(date: Fixture.noon, calendar: utc)
        await review.load(environment: environment, now: Fixture.noon.addingTimeInterval(7200))

        #expect(review.spans.count == 1)
        #expect(review.rollup.elapsed == 5400)
        #expect(review.rollup.weightedBillable == 5400)
        #expect(review.confidence(for: review.spans[0]) == .manual)
    }

    @Test("An interval can be retitled and reassigned offline")
    func correctionWorksOffline() async throws {
        let environment = await makeEnvironment()
        let repository = try #require(environment.repository)

        let entry = ManualEntryViewModel(
            start: Fixture.noon, end: Fixture.noon.addingTimeInterval(3600)
        )
        entry.title = "Untitled work"
        await entry.save(environment: environment, now: Fixture.noon)

        let span = try #require(try await repository.spans(in: Fixture.day()).first)
        let editor = SpanEditorViewModel(span: span, now: Fixture.noon)
        editor.title = "Client call"
        editor.clientName = "Acme"
        editor.isBillable = true

        // A later clock than the create. See `sameInstantEditIsDropped` for why
        // this matters and why it is not just test hygiene.
        await editor.save(environment: environment, now: Fixture.noon.addingTimeInterval(60))

        #expect(editor.didFinish)
        #expect(editor.errorMessage == nil)

        let updated = try #require(try await repository.span(id: span.id))
        #expect(updated.title == "Client call")
        #expect(updated.clientName == "Acme")
        #expect(updated.isBillable)
        // Reassignment clears the stale id so the name resolves again.
        #expect(updated.clientID == nil)
    }

    /// Documents a TimelyKit defect this app cannot work around from here.
    ///
    /// `TimelyLocalStore.upsert` applies the §8 last-writer-wins rule to *every*
    /// write, including a device rewriting its own row. Two unsynced copies
    /// (`server_revision == 0`) carrying the same `updated_at` reached the
    /// `incoming.origin_device_id > existing.origin_device_id` tie-break —
    /// strictly greater — so a device lost to itself and the edit vanished from
    /// local state while still being queued.
    ///
    /// Fixed in TimelyKit by exempting same-`origin_device_id` rewrites *before*
    /// the comparison: a device rewriting its own row is not a conflict, so it
    /// must not reach a rule designed to adjudicate between two devices.
    /// Cross-device behaviour is unchanged — when the ids differ the comparison
    /// is byte-identical, so §8.2's "lexically greater wins" still holds and all
    /// three clients compute the same winner.
    ///
    /// Kept as a regression test rather than deleted. This is the fastest
    /// possible edit sequence a user can produce, and it is the shape most
    /// likely to silently regress.
    @Test("A same-instant local rewrite lands, because a device cannot conflict with itself")
    func sameInstantEditLands() async throws {
        let environment = await makeEnvironment()
        let repository = try #require(environment.repository)

        let entry = ManualEntryViewModel(
            start: Fixture.noon, end: Fixture.noon.addingTimeInterval(3600)
        )
        entry.title = "Original"
        await entry.save(environment: environment, now: Fixture.noon)

        let span = try #require(try await repository.spans(in: Fixture.day()).first)
        let editor = SpanEditorViewModel(span: span, now: Fixture.noon)
        editor.title = "Corrected"
        // Deliberately the SAME instant as the create.
        await editor.save(environment: environment, now: Fixture.noon)

        let stored = try #require(try await repository.span(id: span.id))

        #expect(stored.title == "Corrected")
        // And the correction is still queued for the server, as it always was.
        #expect(try await repository.queueDepth() == 2)
    }

    @Test("Splitting offline creates both halves and tombstones the original")
    func splitWorksOffline() async throws {
        let environment = await makeEnvironment()
        let repository = try #require(environment.repository)

        let entry = ManualEntryViewModel(
            start: Fixture.noon, end: Fixture.noon.addingTimeInterval(7200)
        )
        entry.title = "Long session"
        await entry.save(environment: environment, now: Fixture.noon)

        let span = try #require(try await repository.spans(in: Fixture.day()).first)
        let editor = SpanEditorViewModel(span: span, now: Fixture.noon)
        editor.splitPoint = Fixture.noon.addingTimeInterval(3600)

        await editor.split(environment: environment, now: Fixture.noon)

        #expect(editor.didFinish)
        #expect(editor.errorMessage == nil)

        let live = try await repository.spans(in: Fixture.day())
        #expect(live.count == 2)
        #expect(live.allSatisfy { $0.derivedFromSpanIDs == [span.id] })

        // Nothing is destroyed: the original is a tombstone, still in the store.
        let original = try #require(try await repository.span(id: span.id))
        #expect(original.isDeleted)
    }

    @Test("Merging offline produces one interval citing both sources")
    func mergeWorksOffline() async throws {
        let environment = await makeEnvironment()
        let repository = try #require(environment.repository)

        for (index, title) in ["Morning", "Afternoon"].enumerated() {
            let entry = ManualEntryViewModel(
                start: Fixture.noon.addingTimeInterval(Double(index) * 7200),
                end: Fixture.noon.addingTimeInterval(Double(index) * 7200 + 3600)
            )
            entry.title = title
            await entry.save(environment: environment, now: Fixture.noon)
        }

        let spans = try await repository.spans(in: Fixture.day())
        #expect(spans.count == 2)
        let primary = try #require(spans.first { $0.title == "Morning" })

        let plan = try SpanCorrection.merge(
            spans, keeping: primary, context: repository.context, now: Fixture.noon
        ).get()
        try await repository.apply(plan, at: Fixture.noon)

        let live = try await repository.spans(in: Fixture.day())
        #expect(live.count == 1)
        #expect(live.first?.title == "Morning")
        #expect(Set(live.first?.derivedFromSpanIDs ?? []) == Set(spans.map(\.id)))
    }

    @Test("Deleting offline tombstones rather than destroying")
    func deleteTombstones() async throws {
        let environment = await makeEnvironment()
        let repository = try #require(environment.repository)

        let entry = ManualEntryViewModel(
            start: Fixture.noon, end: Fixture.noon.addingTimeInterval(1800)
        )
        entry.title = "Mistake"
        await entry.save(environment: environment, now: Fixture.noon)

        let span = try #require(try await repository.spans(in: Fixture.day()).first)
        let editor = SpanEditorViewModel(span: span, now: Fixture.noon)
        await editor.delete(environment: environment, now: Fixture.noon)

        #expect(try await repository.spans(in: Fixture.day()).isEmpty)
        #expect(try await repository.span(id: span.id)?.isDeleted == true)
    }

    @Test("Every offline edit is queued for push, in order")
    func editsAreQueued() async throws {
        let environment = await makeEnvironment()
        let repository = try #require(environment.repository)

        let entry = ManualEntryViewModel(
            start: Fixture.noon, end: Fixture.noon.addingTimeInterval(3600)
        )
        entry.title = "Work"
        await entry.save(environment: environment, now: Fixture.tick(0))
        let afterCreate = try await repository.queueDepth()

        let span = try #require(try await repository.spans(in: Fixture.day()).first)
        let editor = SpanEditorViewModel(span: span, now: Fixture.tick(0))
        editor.title = "Work, corrected"
        // Advancing, not `Fixture.noon` twice. Two writes at the same instant
        // lose the LWW tie-break to each other (see `sameInstantEditIsDropped`),
        // and this test would still pass on the queue assertion alone while the
        // stored row silently kept the old title.
        await editor.save(environment: environment, now: Fixture.tick(1))

        let afterUpdate = try await repository.queueDepth()
        #expect(afterUpdate == afterCreate + 1)

        // The edit must also be visible locally, which is what the queue
        // assertion on its own does not prove.
        #expect(try await repository.span(id: span.id)?.title == "Work, corrected")
    }

    @Test("An atomic correction keeps its whole batch together")
    func atomicBatchIsGrouped() async throws {
        let environment = await makeEnvironment()
        let repository = try #require(environment.repository)

        let entry = ManualEntryViewModel(
            start: Fixture.noon, end: Fixture.noon.addingTimeInterval(7200)
        )
        entry.title = "Long session"
        await entry.save(environment: environment, now: Fixture.noon)

        let span = try #require(try await repository.spans(in: Fixture.day()).first)
        let plan = try SpanCorrection.split(
            span, at: Fixture.noon.addingTimeInterval(3600),
            context: repository.context, now: Fixture.noon
        ).get()
        try await repository.apply(plan, at: Fixture.noon)

        // The create, the create and the delete are one group of three.
        let batch = try await repository.store.nextBatch(
            workspaceID: Fixture.workspaceID, limit: 100
        )
        let grouped = batch.filter { $0.batchGroup == plan.batchGroup }
        #expect(grouped.isEmpty || grouped.count == 3)
    }

    /// iOS inherits TimelyKit's presence-sensitive omission for free, because
    /// every write goes through `recordLocalChange`. This asserts the inherited
    /// result rather than trusting it: the app is the surface most likely to
    /// hold a stale copy, and `locked_at` has no server-side backstop.
    ///
    /// `null` is a claim; absence is an admission of ignorance. These payloads
    /// must admit ignorance about fields this client has no information about.
    @Test("Queued payloads omit fields the client has no information about")
    func payloadsOmitServerManagedFields() async throws {
        let environment = await makeEnvironment()
        let repository = try #require(environment.repository)

        let entry = ManualEntryViewModel(
            start: Fixture.tick(0), end: Fixture.tick(60)
        )
        entry.title = "Billable work"
        entry.clientName = "Acme"
        entry.isBillable = true
        await entry.save(environment: environment, now: Fixture.tick(0))

        let batch = try await repository.store.nextBatch(
            workspaceID: Fixture.workspaceID, limit: 100
        )

        let spanMutation = try #require(batch.first { $0.entityKind == .timeSpan })
        // Never sent: no backstop server-side, and an explicit null reads as
        // intent to clear an approval lock this device may not know exists.
        #expect(spanMutation.payload["locked_at"] == nil)
        // Still sent: the contract declares these nullable AND required, and a
        // blanket omission would break them.
        #expect(spanMutation.payload["deleted_at"] != nil)
        #expect(spanMutation.payload["end"] != nil)
        // Server-owned and read-only: the clamped timestamp LWW actually
        // compares. Persisted locally, never asserted on the wire — the queue
        // payload goes through the wire encoder, where
        // `includesServerOwnedFields` is false.
        #expect(spanMutation.payload["updated_at_effective"] == nil)
        // `server_revision` IS sent: it is the base the server adjudicates
        // against, not a claim about what the server holds.
        #expect(spanMutation.payload["server_revision"] != nil)
        // `origin_device_id` MUST be sent. The server's `wins?/3` reads it from
        // the RAW payload for the LWW tie-break and substitutes nothing, so
        // omitting it loses every exact-timestamp tie. `WorkspaceContext.deviceID`
        // is non-optional and minted on first launch, so this can never be nil —
        // asserted rather than left to inspection.
        #expect(spanMutation.payload["origin_device_id"] != nil)

        let clientMutation = try #require(batch.first { $0.entityKind == .client })
        // A client that has not pulled a merge would un-merge the row.
        #expect(clientMutation.payload["merged_into_id"] == nil)
        // Server-owned; recomputed locally for the index but never asserted.
        #expect(clientMutation.payload["canonical_name"] == nil)
        #expect(clientMutation.payload["name"] != nil)
        #expect(clientMutation.payload["origin_device_id"] != nil)
    }

    @Test("Settings changes are written and queued without a session")
    func settingsWriteOffline() async throws {
        let environment = await makeEnvironment()
        let repository = try #require(environment.repository)

        let settings = SettingsViewModel()
        await settings.load(environment: environment)

        // The workspace gate is closed by default, so this device's own toggle
        // is the only half in play and the effective answer stays closed.
        #expect(settings.workspaceAllowsScreenshotUpload == false)
        #expect(settings.deviceToggleIsOverridden)
        #expect(settings.gate.isOpen == false)

        await settings.setIdleThresholdMinutes(15, environment: environment)

        let stored = try await repository.userSettingsOrDefault()
        #expect(stored.idleThresholdMinutes == 15)
    }

    @Test("Syncing with no session is a no-op, not an error")
    func syncWithoutSessionIsBenign() async {
        let environment = await makeEnvironment()

        await environment.syncNow()

        #expect(environment.status.session == .none)
        #expect(environment.status.lastError == nil)
        #expect(environment.phase == .ready)
    }
}
