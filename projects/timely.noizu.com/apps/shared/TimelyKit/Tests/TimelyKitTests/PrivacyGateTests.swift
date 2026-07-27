import Foundation
import Testing
@testable import TimelyKit

/// The client half of the §7 double gate.
///
/// The structural guarantee this suite protects is not any single assertion
/// below — it is that `TimelyAPIClient.uploadScreenshotBlob` takes a
/// ``BlobUploadDecision`` whose initializer is `fileprivate` to
/// `BlobUpload.swift`. The only way to obtain one is for `PrivacyGate.evaluate`
/// to return `.success`. A call site cannot spell "upload this image" without
/// having passed the gate, and that is enforced by the compiler rather than by
/// a code review.
@Suite("Privacy double gate")
struct PrivacyGateTests {

    static let bothOpen = PrivacyGate(
        workspaceAllowsBlobUpload: true, deviceOptedInToBlobUpload: true
    )

    // MARK: - Both halves required

    @Test("the gate is closed by default")
    func closedByDefault() {
        #expect(!PrivacyGate.closed.isOpen)
        #expect(!PrivacyGate.closed.mayTransmitRawResponse)
    }

    @Test("both halves must be open")
    func bothHalvesRequired() {
        let combinations: [(Bool, Bool, Bool)] = [
            // workspace, device, expected
            (false, false, false),
            (true,  false, false),
            (false, true,  false),
            (true,  true,  true)
        ]
        for (workspace, device, expected) in combinations {
            let gate = PrivacyGate(
                workspaceAllowsBlobUpload: workspace, deviceOptedInToBlobUpload: device
            )
            #expect(gate.isOpen == expected, "workspace=\(workspace) device=\(device)")
        }
    }

    /// Workspace policy is checked first: it is the least negotiable, and a user
    /// told "turn on uploads in Settings" when the workspace forbids them
    /// entirely would be sent on a pointless errand.
    @Test("workspace policy refusal outranks device opt-in")
    func workspacePolicyOutranks() {
        let gate = PrivacyGate(
            workspaceAllowsBlobUpload: false, deviceOptedInToBlobUpload: false
        )
        let result = gate.evaluate(screenshot: Screenshot.test())

        guard case .failure(let refusal) = result else {
            Issue.record("expected refusal")
            return
        }
        #expect(refusal == .workspacePolicyDisallows)
        #expect(!refusal.isUserResolvable)
    }

    @Test("device opt-out is the one refusal a user can fix themselves")
    func deviceOptOutIsResolvable() {
        let gate = PrivacyGate(
            workspaceAllowsBlobUpload: true, deviceOptedInToBlobUpload: false
        )
        guard case .failure(let refusal) = gate.evaluate(screenshot: Screenshot.test()) else {
            Issue.record("expected refusal")
            return
        }
        #expect(refusal == .deviceNotOptedIn)
        #expect(refusal.isUserResolvable)
    }

    // MARK: - Content gates

    @Test("a privacy-flagged screenshot is refused even with both halves open")
    func privacyFlaggedRefused() {
        let screenshot = Screenshot.test()
        let analysis = VisionAnalysis.test(
            screenshotID: screenshot.id, privacySensitive: true, privacyCategory: .financial
        )

        guard case .failure(let refusal) = Self.bothOpen.evaluate(
            screenshot: screenshot, analysis: analysis
        ) else {
            Issue.record("a sensitive screenshot must not pass the gate")
            return
        }
        #expect(refusal == .privacyCategory(.financial))
    }

    /// `privacySensitive` false but a sensitive category is still sensitive —
    /// the two fields must not be able to disagree their way to an upload.
    @Test("a sensitive category alone is enough to refuse")
    func sensitiveCategoryAloneRefuses() {
        let screenshot = Screenshot.test()
        let analysis = VisionAnalysis.test(
            screenshotID: screenshot.id, privacySensitive: false, privacyCategory: .medical
        )

        guard case .failure = Self.bothOpen.evaluate(screenshot: screenshot, analysis: analysis)
        else {
            Issue.record("a medical category must refuse regardless of the boolean")
            return
        }
    }

    @Test("a censored screenshot is refused")
    func censoredRefused() {
        guard case .failure(let refusal) = Self.bothOpen.evaluate(
            screenshot: Screenshot.test(), censored: true
        ) else {
            Issue.record("expected refusal")
            return
        }
        #expect(refusal == .censored)
    }

    @Test("an already-terminal upload state is refused")
    func terminalStatesRefused() {
        for state in [ScreenshotUploadState.uploaded, .refused, .purgePending, .purged] {
            let result = Self.bothOpen.evaluate(screenshot: Screenshot.test(uploadState: state))
            guard case .failure(let refusal) = result else {
                Issue.record("\(state.rawValue) must not be re-uploaded")
                continue
            }
            #expect(refusal == .notEligible(state))
        }
    }

    // MARK: - Success

    @Test("an eligible screenshot with both halves open produces a decision")
    func eligiblePasses() {
        let screenshot = Screenshot.test(uploadState: .eligible)
        let analysis = VisionAnalysis.test(screenshotID: screenshot.id)

        guard case .success(let decision) = Self.bothOpen.evaluate(
            screenshot: screenshot, analysis: analysis
        ) else {
            Issue.record("an eligible, non-sensitive screenshot should pass")
            return
        }
        #expect(decision.screenshotID == screenshot.id)
    }

    /// A decision names one specific screenshot, so it cannot be reused to
    /// smuggle a different image past the gate.
    @Test("a decision is bound to one screenshot")
    func decisionIsBound() {
        let allowed = Screenshot.test(uploadState: .eligible)
        let other = Screenshot.test(uploadState: .eligible)

        guard case .success(let decision) = Self.bothOpen.evaluate(screenshot: allowed) else {
            Issue.record("expected success")
            return
        }
        #expect(decision.screenshotID == allowed.id)
        #expect(decision.screenshotID != other.id)
    }

    // MARK: - Image-equivalent text

    /// If the bytes stay home but a verbatim transcription of those same pixels
    /// syncs freely, the privacy promise is hollow. Same gate, same answer.
    @Test("raw vision response is behind the same gate as the bytes")
    func rawResponseSharesTheGate() {
        #expect(Self.bothOpen.mayTransmitRawResponse)
        #expect(!PrivacyGate(
            workspaceAllowsBlobUpload: true, deviceOptedInToBlobUpload: false
        ).mayTransmitRawResponse)
        #expect(!PrivacyGate(
            workspaceAllowsBlobUpload: false, deviceOptedInToBlobUpload: true
        ).mayTransmitRawResponse)
    }

    /// A metadata-only screenshot is the **normal** case. The recall surface is
    /// the analysis summary, and it must be useful with zero image bytes.
    @Test("a metadata-only screenshot still has a recall surface")
    func metadataOnlyIsUseful() {
        let screenshot = Screenshot.test()
        #expect(screenshot.isMetadataOnly)

        let analysis = VisionAnalysis.test(screenshotID: screenshot.id)
        #expect(!analysis.recallSummary.isEmpty)
        // And the summary must not leak the image-equivalent text.
        #expect(!analysis.recallSummary.contains(analysis.rawResponse ?? "\u{0}"))
    }

    // MARK: - Blob field custody

    /// A client cannot talk itself into believing bytes exist: the blob fields
    /// are `private(set)` and move only through a server-authored result.
    @Test("blob fields move only via a server-reported result")
    func blobFieldsAreServerOwned() throws {
        var screenshot = Screenshot.test(uploadState: .eligible)
        #expect(!screenshot.blobAvailable)

        let result = BlobUploadResult.unverified(
            screenshotID: screenshot.id,
            uploadState: .uploaded,
            blobContentHash: String(repeating: "a", count: 64),
            blobByteSize: 2048,
            blobUploadedAt: Fixed.date(500),
            blobURL: "https://blobs.test/x",
            serverRevision: 91
        )
        screenshot.applyBlobUpload(result)

        #expect(screenshot.uploadState == .uploaded)
        #expect(screenshot.blobAvailable)
        #expect(screenshot.blobByteSize == 2048)
        #expect(screenshot.sync.serverRevision == 91)
        #expect(!screenshot.isMetadataOnly)
    }

    /// A `refused` result must not set `blobAvailable`, even though it came from
    /// the server.
    @Test("a refusal result does not mark bytes available")
    func refusedResultKeepsBytesUnavailable() {
        var screenshot = Screenshot.test(uploadState: .pending)
        screenshot.applyBlobUpload(
            .unverified(screenshotID: screenshot.id, uploadState: .refused, serverRevision: 5)
        )

        #expect(screenshot.uploadState == .refused)
        #expect(!screenshot.blobAvailable)
        #expect(screenshot.isMetadataOnly)
    }

    /// A pre-signed URL is short-lived and is a credential. It must not be
    /// persisted — the store's document column would keep it long past expiry.
    /// The rest of the blob metadata **must** persist, or a screenshot the
    /// server holds bytes for looks metadata-only after every app relaunch.
    @Test("blob metadata persists but the pre-signed URL does not")
    func blobMetadataPersistsButURLDoesNot() async throws {
        let store = try TimelyLocalStore()
        var screenshot = Screenshot.test(uploadState: .eligible)
        screenshot.applyBlobUpload(
            .unverified(
                screenshotID: screenshot.id,
                uploadState: .uploaded,
                blobContentHash: String(repeating: "b", count: 64),
                blobByteSize: 4096,
                blobUploadedAt: Fixed.date(700),
                blobURL: "https://blobs.test/signed?token=SECRET",
                serverRevision: 12
            )
        )
        try await store.upsert(screenshot)

        let reloaded = try await store.fetch(Screenshot.self, id: screenshot.id)
        #expect(reloaded?.uploadState == .uploaded)
        #expect(reloaded?.blobAvailable == true)
        #expect(reloaded?.isMetadataOnly == false)
        #expect(reloaded?.blobContentHash == String(repeating: "b", count: 64))
        #expect(reloaded?.blobByteSize == 4096)
        #expect(reloaded?.blobUploadedAt == Fixed.date(700))

        #expect(reloaded?.blobURL == nil, "a pre-signed URL must not survive a store round trip")
    }

    /// The other half of the same rule: server-owned fields persist locally but
    /// are still never asserted on the wire.
    @Test("server-owned fields are still omitted from the wire encoding")
    func serverOwnedFieldsStayOffTheWire() throws {
        var screenshot = Screenshot.test(uploadState: .eligible)
        screenshot.applyBlobUpload(
            .unverified(
                screenshotID: screenshot.id,
                uploadState: .uploaded,
                blobContentHash: String(repeating: "c", count: 64),
                blobByteSize: 128,
                serverRevision: 3
            )
        )

        let wire = try TimelyJSON.encodeToString(screenshot)
        #expect(!wire.contains("blob_content_hash"))
        #expect(!wire.contains("blob_available"))
        #expect(!wire.contains("blob_byte_size"))

        let stored = String(
            decoding: try TimelyJSON.makeStorageEncoder().encode(screenshot), as: UTF8.self
        )
        #expect(stored.contains("blob_content_hash"))
        #expect(stored.contains("blob_available"))
        #expect(!stored.contains("blob_url"), "the signed URL is excluded even from storage")
    }

    // MARK: - Server refusal decoding

    @Test("a server 403 decodes into the specific gate that closed")
    func serverRefusalDecodes() throws {
        let body = """
        {"code":"blob_upload_forbidden","message":"nope",
         "gates":{"workspace_screenshot_upload_allowed":false,
                  "device_local_only_screenshots":true,
                  "screenshot_censored":false}}
        """
        let decoded = try TimelyJSON.decode(BlobForbiddenError.self, from: body)
        #expect(decoded.code == "blob_upload_forbidden")
        #expect(decoded.gates.workspaceScreenshotUploadAllowed == false)
        #expect(decoded.gates.screenshotCensored == false)
    }

    @Test("every refusal explains itself in words a user can act on")
    func refusalsExplainThemselves() {
        let refusals: [BlobUploadRefusal] = [
            .workspacePolicyDisallows,
            .deviceNotOptedIn,
            .privacyCategory(.financial),
            .censored,
            .notEligible(.purged)
        ]
        for refusal in refusals {
            #expect(!refusal.explanation.isEmpty)
            #expect(refusal.explanation.first?.isUppercase == true)
        }
    }
}
