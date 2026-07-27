import Foundation
import Testing
@testable import TimelyKit

/// Why the macOS capture agent must tombstone a censored screenshot rather than
/// delete it.
///
/// The agent used to hard-delete the screenshot row and its analyses when the
/// vision model flagged private content. That is not merely untidy in a protocol
/// that never hard-deletes — it is a privacy failure with a specific mechanism,
/// pinned by ``hardDeleteResurrectsOnNextPull()`` below: the server was never
/// told, so the very next pull hands the row back and the app re-materializes
/// the record of a screenshot the user asked it to forget.
///
/// These tests exercise the store-level semantics the macOS fix depends on.
@Suite("Censorship cascade")
struct CensorshipCascadeTests {

    /// Stand in for what the capture agent does when the model flags a
    /// screenshot: drop the bytes, tombstone the rows, assert the censorship.
    private func censor(
        screenshot: Screenshot,
        analyses: [VisionAnalysis],
        in store: TimelyLocalStore
    ) async throws -> CensoredScreenshot {
        _ = try await store.tombstone(
            Screenshot.self, id: screenshot.id, deviceID: Fixed.deviceA
        )
        for analysis in analyses {
            _ = try await store.tombstone(
                VisionAnalysis.self, id: analysis.id, deviceID: Fixed.deviceA
            )
        }

        let assertion = CensoredScreenshot(
            sync: .local(id: UUID.v7(), workspaceID: Fixed.workspace, deviceID: Fixed.deviceA),
            screenshotID: screenshot.id,
            spanID: screenshot.spanID,
            fileName: screenshot.fileName,
            activeAppName: screenshot.activeAppName,
            capturedAt: screenshot.capturedAt,
            censoredAt: Fixed.date(1000),
            model: "test-vision",
            category: .secret,
            reason: "password manager visible",
            confidence: 0.99,
            deletedLocalFile: true
        )
        try await store.upsert(assertion)
        _ = try await store.enqueue(.create, entity: assertion)
        return assertion
    }

    // MARK: - The bug

    /// The old behaviour, reproduced. A hard-deleted row is simply absent, and
    /// the server — which was never told — sends it again.
    @Test("a hard-deleted screenshot comes back on the next pull")
    func hardDeleteResurrectsOnNextPull() async throws {
        let store = try TimelyLocalStore()
        let screenshot = Screenshot.test(uploadState: .localOnly)
        // Server-acknowledged, as any screenshot that has synced once would be.
        var acknowledged = screenshot
        acknowledged.sync.serverRevision = 40
        try await store.upsert(acknowledged)

        // What the app used to do: remove it from local state entirely. There is
        // no store API for this, which is itself the point — the closest thing
        // is simply never having written it.
        let fresh = try TimelyLocalStore()

        // Next pull delivers the row the server still holds.
        try await fresh.upsertAll([acknowledged])

        let resurrected = try await fresh.fetch(Screenshot.self, id: screenshot.id)
        #expect(resurrected != nil, "this is the bug: the row is back")
        #expect(resurrected?.isDeleted == false, "and it is not even marked deleted")
    }

    // MARK: - The fix

    @Test("a censored screenshot is tombstoned, not removed")
    func censorTombstones() async throws {
        let store = try TimelyLocalStore()
        let screenshot = Screenshot.test()
        let analysis = VisionAnalysis.test(
            screenshotID: screenshot.id, privacySensitive: true, privacyCategory: .secret
        )
        try await store.upsert(screenshot)
        try await store.upsert(analysis)

        _ = try await censor(screenshot: screenshot, analyses: [analysis], in: store)

        // Gone from the UI's view.
        #expect(try await store.fetchAll(Screenshot.self, workspaceID: Fixed.workspace).isEmpty)
        #expect(try await store.fetchAll(VisionAnalysis.self, workspaceID: Fixed.workspace).isEmpty)

        // But present and marked deleted, which is what makes it expressible.
        #expect(try await store.fetch(Screenshot.self, id: screenshot.id)?.isDeleted == true)
        #expect(try await store.fetch(VisionAnalysis.self, id: analysis.id)?.isDeleted == true)
    }

    /// The property the whole fix exists for.
    @Test("a tombstoned screenshot is NOT resurrected by a stale pull")
    func tombstoneSurvivesStalePull() async throws {
        let store = try TimelyLocalStore()
        var screenshot = Screenshot.test()
        screenshot.sync.serverRevision = 40
        try await store.upsert(screenshot)

        _ = try await censor(screenshot: screenshot, analyses: [], in: store)
        #expect(try await store.fetch(Screenshot.self, id: screenshot.id)?.isDeleted == true)

        // A pull page carrying the server's pre-censorship copy. The local
        // tombstone is at the same revision, and a tombstone beats a concurrent
        // update (§8 row 2), so it holds.
        try await store.upsertAll([screenshot])

        let after = try await store.fetch(Screenshot.self, id: screenshot.id)
        #expect(after?.isDeleted == true, "the censored screenshot must stay censored")
        #expect(try await store.fetchAll(Screenshot.self, workspaceID: Fixed.workspace).isEmpty)
    }

    /// The assertion is what tells the server to run its own cascade. Without it
    /// queued, the tombstone is local-only and every other device keeps the row.
    @Test("censorship queues an assertion for the server")
    func assertionIsQueued() async throws {
        let store = try TimelyLocalStore()
        let screenshot = Screenshot.test()
        try await store.upsert(screenshot)

        let assertion = try await censor(screenshot: screenshot, analyses: [], in: store)

        let queued = try await store.nextBatch(workspaceID: Fixed.workspace, limit: 50)
        let censorship = queued.first { $0.entityKind == .censoredScreenshot }

        #expect(censorship != nil, "the server must be told")
        #expect(censorship?.operation == .create, "censorship is asserted by creating a row")
        #expect(censorship?.entityID == assertion.id)
    }

    /// `censored_screenshot` is append-only (§8 row 15). A client that queued an
    /// update would be rejected with `immutable_entity`.
    @Test("a censorship assertion can never be updated")
    func assertionIsAppendOnly() async throws {
        let store = try TimelyLocalStore()
        let screenshot = Screenshot.test()
        let assertion = try await censor(screenshot: screenshot, analyses: [], in: store)

        #expect(EntityKind.censoredScreenshot.isAppendOnly)

        var thrown: (any Error)?
        do {
            _ = try await store.enqueue(.update, entity: assertion)
        } catch {
            thrown = error
        }
        guard case .some(SyncError.immutableEntity) = thrown as? SyncError else {
            Issue.record("expected immutableEntity, got \(String(describing: thrown))")
            return
        }
    }

    /// The server's cascade arrives as side effects. Applying them must not
    /// un-delete anything the client already tombstoned.
    @Test("the server's cascade agrees with the local tombstone")
    func serverCascadeAgrees() async throws {
        let store = try TimelyLocalStore()
        var screenshot = Screenshot.test()
        screenshot.sync.serverRevision = 40
        try await store.upsert(screenshot)
        _ = try await censor(screenshot: screenshot, analyses: [], in: store)

        // The server applies its half and returns the row at a higher revision,
        // now tombstoned on its side too.
        var serverCopy = screenshot
        serverCopy.sync.serverRevision = 61
        serverCopy.sync.deletedAt = Fixed.date(1001)
        try await store.upsertAll([serverCopy])

        let final = try await store.fetch(Screenshot.self, id: screenshot.id)
        #expect(final?.isDeleted == true)
        #expect(final?.sync.serverRevision == 61)
    }

    /// A censored screenshot must never be offered for upload, whatever the
    /// gates say — the bytes are exactly what the user asked to destroy.
    @Test("a censored screenshot cannot pass the privacy gate")
    func censoredCannotUpload() {
        let bothOpen = PrivacyGate(
            workspaceAllowsBlobUpload: true, deviceOptedInToBlobUpload: true
        )
        let screenshot = Screenshot.test(uploadState: .eligible)

        guard case .failure(let refusal) = bothOpen.evaluate(
            screenshot: screenshot, censored: true
        ) else {
            Issue.record("a censored screenshot must not be uploadable")
            return
        }
        #expect(refusal == .censored)
    }
}
