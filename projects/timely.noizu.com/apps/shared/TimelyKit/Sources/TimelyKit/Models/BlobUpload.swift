import Foundation

/// The server's report about a screenshot's image bytes.
///
/// Only the server may author these fields. A client constructs one solely by
/// decoding a server response — which is why there is no public memberwise
/// initializer, only ``init(from:)`` and a test-facing factory that is
/// deliberately named for what it is.
///
/// `Screenshot.applyBlobUpload(_:)` is the only path that moves a screenshot's
/// blob fields, so a client cannot talk itself into believing bytes exist.
public struct BlobUploadResult: Sendable, Hashable, Decodable {

    /// The screenshot these bytes belong to.
    public let screenshotID: UUID

    /// The state the server has moved the screenshot to. `.uploaded` is the
    /// only value that means bytes are retrievable.
    public let uploadState: ScreenshotUploadState

    public let blobContentHash: String?
    public let blobByteSize: Int?
    public let blobUploadedAt: Date?

    /// Pre-signed and short-lived. Never persisted to the local store — a URL
    /// cached past its expiry is a support ticket, and a URL cached in a
    /// database is a credential at rest.
    public let blobURL: String?

    /// The revision the server assigned to the screenshot row as a result.
    public let serverRevision: Int64

    enum CodingKeys: String, CodingKey {
        case screenshotID = "screenshot_id"
        case uploadState = "upload_state"
        case blobContentHash = "blob_content_hash"
        case blobByteSize = "blob_byte_size"
        case blobUploadedAt = "blob_uploaded_at"
        case blobURL = "blob_url"
        case serverRevision = "server_revision"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        screenshotID = try c.decodeUUID(.screenshotID)
        uploadState = try c.contractEnum(.uploadState, or: .localOnly)
        blobContentHash = try c.optional(.blobContentHash)
        blobByteSize = try c.optional(.blobByteSize)
        blobUploadedAt = try c.optional(.blobUploadedAt)
        blobURL = try c.optional(.blobURL)
        serverRevision = try c.value(.serverRevision, or: 0)
    }

    /// Construct a result without a server round trip. **Tests and migration
    /// only** — production code must decode one from a response body.
    public static func unverified(
        screenshotID: UUID,
        uploadState: ScreenshotUploadState,
        blobContentHash: String? = nil,
        blobByteSize: Int? = nil,
        blobUploadedAt: Date? = nil,
        blobURL: String? = nil,
        serverRevision: Int64 = 0
    ) -> BlobUploadResult {
        BlobUploadResult(
            screenshotID: screenshotID,
            uploadState: uploadState,
            blobContentHash: blobContentHash,
            blobByteSize: blobByteSize,
            blobUploadedAt: blobUploadedAt,
            blobURL: blobURL,
            serverRevision: serverRevision
        )
    }

    private init(
        screenshotID: UUID,
        uploadState: ScreenshotUploadState,
        blobContentHash: String?,
        blobByteSize: Int?,
        blobUploadedAt: Date?,
        blobURL: String?,
        serverRevision: Int64
    ) {
        self.screenshotID = screenshotID
        self.uploadState = uploadState
        self.blobContentHash = blobContentHash
        self.blobByteSize = blobByteSize
        self.blobUploadedAt = blobUploadedAt
        self.blobURL = blobURL
        self.serverRevision = serverRevision
    }
}

// MARK: - The client half of the double gate

/// Why a screenshot's bytes may not leave the device.
///
/// Ordered by how much explaining they need in the UI: the first case is a
/// setting the user can change, the rest are policy or content decisions.
public enum BlobUploadRefusal: Error, Sendable, Hashable {
    /// The workspace policy forbids blob upload. No device setting overrides it.
    case workspacePolicyDisallows

    /// This device has not opted in to uploading image bytes.
    case deviceNotOptedIn

    /// The vision model flagged the screenshot's contents as sensitive.
    case privacyCategory(PrivacyCategory)

    /// The screenshot has already been censored; its bytes are being purged.
    case censored

    /// The server has already moved this screenshot to a terminal state.
    case notEligible(ScreenshotUploadState)

    public var isUserResolvable: Bool {
        if case .deviceNotOptedIn = self { return true }
        return false
    }

    public var explanation: String {
        switch self {
        case .workspacePolicyDisallows:
            return "This workspace does not allow screenshots to be uploaded."
        case .deviceNotOptedIn:
            return "This device is set to keep screenshots local. "
                 + "You can change this in Settings."
        case .privacyCategory(let category):
            return "This screenshot was flagged as \(category.rawValue) and stays on this device."
        case .censored:
            return "This screenshot was censored; its image is being deleted everywhere."
        case .notEligible(let state):
            return "This screenshot is \(state.rawValue) and cannot be uploaded."
        }
    }
}

/// The client half of the §7 double gate.
///
/// **Both** the workspace policy and the originating device must permit upload.
/// The gate is evaluated locally before any byte leaves the device, and again
/// by the server on arrival; neither side trusts the other. This type exists so
/// that the local half is a single auditable expression rather than an `if`
/// scattered across an upload call site.
///
/// There is deliberately **no** API on this package that uploads an image
/// without consulting this gate. `ScreenshotBlobUploader` takes a
/// ``BlobUploadDecision`` it cannot construct itself, so "just upload this
/// image" is not a call a caller can spell.
public struct PrivacyGate: Sendable, Hashable {

    /// From `workspace_policy`. Server-owned.
    public let workspaceAllowsBlobUpload: Bool

    /// From this device's own settings. User-owned.
    public let deviceOptedInToBlobUpload: Bool

    public init(workspaceAllowsBlobUpload: Bool, deviceOptedInToBlobUpload: Bool) {
        self.workspaceAllowsBlobUpload = workspaceAllowsBlobUpload
        self.deviceOptedInToBlobUpload = deviceOptedInToBlobUpload
    }

    /// The closed gate. The default everywhere a gate is not yet known — an
    /// unknown policy must never be read as permission.
    public static let closed = PrivacyGate(
        workspaceAllowsBlobUpload: false,
        deviceOptedInToBlobUpload: false
    )

    public var isOpen: Bool {
        workspaceAllowsBlobUpload && deviceOptedInToBlobUpload
    }

    /// Evaluate the gate for one screenshot and its analysis.
    ///
    /// Returns a ``BlobUploadDecision`` on success — an unforgeable token that
    /// the uploader requires. The refusal reasons are ordered so that the least
    /// negotiable one wins: workspace policy before device opt-in before
    /// content.
    public func evaluate(
        screenshot: Screenshot,
        analysis: VisionAnalysis? = nil,
        censored: Bool = false
    ) -> Result<BlobUploadDecision, BlobUploadRefusal> {
        guard workspaceAllowsBlobUpload else { return .failure(.workspacePolicyDisallows) }
        guard deviceOptedInToBlobUpload else { return .failure(.deviceNotOptedIn) }
        guard !censored else { return .failure(.censored) }

        if let analysis, analysis.privacySensitive || analysis.privacyCategory.isSensitive {
            return .failure(.privacyCategory(analysis.privacyCategory))
        }

        switch screenshot.uploadState {
        case .eligible, .pending, .localOnly:
            return .success(BlobUploadDecision(screenshotID: screenshot.id))
        case .uploaded, .refused, .purgePending, .purged:
            return .failure(.notEligible(screenshot.uploadState))
        }
    }

    /// Whether a vision analysis's `raw_response` may be sent.
    ///
    /// A verbatim model transcription of the screen is image-equivalent: if the
    /// bytes stay home but the transcription syncs freely, the promise is
    /// hollow. Same gate, same answer.
    public var mayTransmitRawResponse: Bool { isOpen }
}

/// Proof that ``PrivacyGate/evaluate(screenshot:analysis:censored:)`` returned
/// success for a specific screenshot.
///
/// The initializer is private to this file, so the only way to obtain one is to
/// pass the gate. This is what makes "upload this image" unspellable without a
/// gate check — the compiler enforces it rather than a code review.
public struct BlobUploadDecision: Sendable, Hashable {
    public let screenshotID: UUID

    fileprivate init(screenshotID: UUID) {
        self.screenshotID = screenshotID
    }
}
