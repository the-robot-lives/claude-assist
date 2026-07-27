import Foundation

/// Screenshot **metadata**. This row always syncs; the image bytes it describes
/// do not, unless both privacy gates are open.
///
/// `fileName` is a path on the originating device. It is advisory provenance
/// and a companion MUST NOT try to resolve it. It is formatted at second
/// resolution, so two captures in the same second collide — nothing may key on
/// it.
public struct Screenshot: SyncEntity {
    public static var kind: EntityKind { .screenshot }

    public var sync: SyncEnvelope

    public var spanID: UUID?
    public var capturedAt: Date
    public var fileName: String
    public var activeAppName: String

    /// Server-owned. Clients never set this through `/sync/mutations`; the
    /// server derives it from the gates and from a blob upload, and silently
    /// ignores a client that tries (conflict matrix row 17).
    public private(set) var uploadState: ScreenshotUploadState

    public private(set) var blobAvailable: Bool
    public private(set) var blobContentHash: String?
    public private(set) var blobByteSize: Int?
    public private(set) var blobUploadedAt: Date?
    public private(set) var blobURL: String?

    public init(
        sync: SyncEnvelope,
        spanID: UUID? = nil,
        capturedAt: Date,
        fileName: String,
        activeAppName: String = "",
        uploadState: ScreenshotUploadState = .localOnly
    ) {
        self.sync = sync
        self.spanID = spanID
        self.capturedAt = capturedAt
        self.fileName = fileName
        self.activeAppName = activeAppName
        self.uploadState = uploadState
        self.blobAvailable = false
        self.blobContentHash = nil
        self.blobByteSize = nil
        self.blobUploadedAt = nil
        self.blobURL = nil
    }

    /// Adopt a server-reported blob result. The only way to move the blob
    /// fields, and it is deliberately not a plain setter.
    public mutating func applyBlobUpload(_ result: BlobUploadResult) {
        uploadState = result.uploadState
        blobAvailable = result.uploadState.hasServerBytes
        blobContentHash = result.blobContentHash
        blobByteSize = result.blobByteSize
        blobUploadedAt = result.blobUploadedAt
        blobURL = result.blobURL
        sync.serverRevision = max(sync.serverRevision, result.serverRevision)
    }

    /// True when this screenshot's recall surface is metadata plus vision
    /// analysis rather than the image. This is the **normal** case, not a
    /// degraded one.
    public var isMetadataOnly: Bool { !blobAvailable }

    enum CodingKeys: String, CodingKey {
        case spanID = "span_id"
        case capturedAt = "captured_at"
        case fileName = "file_name"
        case activeAppName = "active_app_name"
        case uploadState = "upload_state"
        case blobAvailable = "blob_available"
        case blobContentHash = "blob_content_hash"
        case blobByteSize = "blob_byte_size"
        case blobUploadedAt = "blob_uploaded_at"
        case blobURL = "blob_url"
    }

    public init(from decoder: any Decoder) throws {
        sync = try SyncEnvelope(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        spanID = try c.decodeOptionalUUID(.spanID)
        capturedAt = try c.decode(Date.self, forKey: .capturedAt)
        fileName = try c.value(.fileName, or: "")
        activeAppName = try c.value(.activeAppName, or: "")
        uploadState = try c.contractEnum(.uploadState, or: .localOnly)
        blobAvailable = try c.value(.blobAvailable, or: false)
        blobContentHash = try c.optional(.blobContentHash)
        blobByteSize = try c.optional(.blobByteSize)
        blobUploadedAt = try c.optional(.blobUploadedAt)
        blobURL = try c.optional(.blobURL)
    }

    public func encode(to encoder: any Encoder) throws {
        try sync.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeNullableUUID(spanID, forKey: .spanID)
        try c.encode(capturedAt, forKey: .capturedAt)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(activeAppName, forKey: .activeAppName)
        try c.encode(uploadState, forKey: .uploadState)

        // blob_* and blob_available are server-owned and are never asserted on
        // the wire. They ARE persisted locally, so that a screenshot the server
        // holds bytes for still knows that after an app relaunch.
        //
        // `blob_url` is excluded even from storage: it is short-lived and
        // pre-signed, so a cached copy is both stale and a credential at rest.
        if encoder.includesServerOwnedFields {
            try c.encode(blobAvailable, forKey: .blobAvailable)
            try c.encode(blobContentHash, forKey: .blobContentHash)
            try c.encode(blobByteSize, forKey: .blobByteSize)
            try c.encode(blobUploadedAt, forKey: .blobUploadedAt)
        }
    }
}

/// Mirrors `VisionAnalysisRecord`. **Append-only** — an `update` is rejected
/// with `immutable_entity`; re-analysis produces a new row.
///
/// For a local-only screenshot this row *is* the recall surface. It is what
/// makes a companion app useful with zero image bytes, which is why it is a
/// first-class synced entity rather than a macOS-local nicety.
public struct VisionAnalysis: SyncEntity {
    public static var kind: EntityKind { .visionAnalysis }

    public var sync: SyncEnvelope

    public var screenshotID: UUID
    public var analyzedAt: Date
    public var model: String

    /// One concise sentence describing visible progress. Always syncs.
    public var statusUpdate: String
    public var inferredProject: String
    public var inferredTask: String
    public var projectSwitchDetected: Bool
    public var confidence: Double

    /// A short phrase naming the visible clues. Always syncs.
    public var evidence: String

    public var privacySensitive: Bool
    public var privacyCategory: PrivacyCategory

    /// The model's verbatim output describing the screen — **image-equivalent**.
    /// If image bytes stay on device but a full textual transcription of those
    /// same pixels syncs freely, the privacy promise is hollow, so this field
    /// is behind the same double gate as the bytes.
    public var rawResponse: String?

    /// True when `rawResponse` was suppressed by policy rather than absent at
    /// the source. Distinguishing the two matters: one is a privacy setting the
    /// user can change, the other is missing data.
    public private(set) var rawResponseWithheld: Bool

    public var errorMessage: String?

    public init(
        sync: SyncEnvelope,
        screenshotID: UUID,
        analyzedAt: Date,
        model: String,
        statusUpdate: String = "",
        inferredProject: String = "",
        inferredTask: String = "",
        projectSwitchDetected: Bool = false,
        confidence: Double,
        evidence: String = "",
        privacySensitive: Bool = false,
        privacyCategory: PrivacyCategory = .none,
        rawResponse: String? = nil,
        rawResponseWithheld: Bool = true,
        errorMessage: String? = nil
    ) {
        self.sync = sync
        self.screenshotID = screenshotID
        self.analyzedAt = analyzedAt
        self.model = model
        self.statusUpdate = statusUpdate
        self.inferredProject = inferredProject
        self.inferredTask = inferredTask
        self.projectSwitchDetected = projectSwitchDetected
        self.confidence = confidence
        self.evidence = evidence
        self.privacySensitive = privacySensitive
        self.privacyCategory = privacyCategory
        self.rawResponse = rawResponse
        self.rawResponseWithheld = rawResponseWithheld
        self.errorMessage = errorMessage
    }

    /// The text a companion renders for a screenshot whose bytes it will never
    /// see. Deliberately excludes `rawResponse`, which is image-equivalent.
    public var recallSummary: String {
        [statusUpdate, evidence].filter { !$0.isEmpty }.joined(separator: " — ")
    }

    enum CodingKeys: String, CodingKey {
        case screenshotID = "screenshot_id"
        case analyzedAt = "analyzed_at"
        case model
        case statusUpdate = "status_update"
        case inferredProject = "inferred_project"
        case inferredTask = "inferred_task"
        case projectSwitchDetected = "project_switch_detected"
        case confidence
        case evidence
        case privacySensitive = "privacy_sensitive"
        case privacyCategory = "privacy_category"
        case rawResponse = "raw_response"
        case rawResponseWithheld = "raw_response_withheld"
        case errorMessage = "error_message"
    }

    public init(from decoder: any Decoder) throws {
        sync = try SyncEnvelope(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        screenshotID = try c.decodeUUID(.screenshotID)
        analyzedAt = try c.decode(Date.self, forKey: .analyzedAt)
        model = try c.value(.model, or: "")
        statusUpdate = try c.value(.statusUpdate, or: "")
        inferredProject = try c.value(.inferredProject, or: "")
        inferredTask = try c.value(.inferredTask, or: "")
        projectSwitchDetected = try c.value(.projectSwitchDetected, or: false)
        confidence = try c.value(.confidence, or: 0)
        evidence = try c.value(.evidence, or: "")
        privacySensitive = try c.value(.privacySensitive, or: false)
        privacyCategory = try c.contractEnum(.privacyCategory, or: .none)
        rawResponse = try c.optional(.rawResponse)
        rawResponseWithheld = try c.value(.rawResponseWithheld, or: true)
        errorMessage = try c.optional(.errorMessage)
    }

    public func encode(to encoder: any Encoder) throws {
        try sync.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeUUID(screenshotID, forKey: .screenshotID)
        try c.encode(analyzedAt, forKey: .analyzedAt)
        try c.encode(model, forKey: .model)
        try c.encode(statusUpdate, forKey: .statusUpdate)
        try c.encode(inferredProject, forKey: .inferredProject)
        try c.encode(inferredTask, forKey: .inferredTask)
        try c.encode(projectSwitchDetected, forKey: .projectSwitchDetected)
        try c.encode(confidence, forKey: .confidence)
        try c.encode(evidence, forKey: .evidence)
        try c.encode(privacySensitive, forKey: .privacySensitive)
        try c.encode(privacyCategory, forKey: .privacyCategory)
        try c.encode(rawResponse, forKey: .rawResponse)
        try c.encode(errorMessage, forKey: .errorMessage)

        // `raw_response_withheld` is readOnly on the wire. It is persisted
        // locally so the distinction between "suppressed by policy" and "absent
        // at the source" survives a relaunch — one is a setting the user can
        // change, the other is missing data, and the UI must not conflate them.
        if encoder.includesServerOwnedFields {
            try c.encode(rawResponseWithheld, forKey: .rawResponseWithheld)
        }
    }
}

/// Mirrors `CensoredScreenshotRecord`. **Append-only.**
///
/// Creating this row is an *assertion of censorship*, and the server applies it
/// as one: the referenced screenshot is tombstoned, its analyses are
/// tombstoned, and any stored blob is deleted and set to `purged`. That cascade
/// comes back as `side_effects`. This is how the macOS agent's local hard-delete
/// is expressed in a protocol that never hard-deletes.
public struct CensoredScreenshot: SyncEntity {
    public static var kind: EntityKind { .censoredScreenshot }

    public var sync: SyncEnvelope

    public var screenshotID: UUID
    public var spanID: UUID?
    public var fileName: String
    public var activeAppName: String
    public var capturedAt: Date
    public var censoredAt: Date
    public var model: String
    public var category: PrivacyCategory
    public var reason: String
    public var confidence: Double

    /// The origin device's report about **its own disk**. It says nothing about
    /// any other device and MUST NOT be rendered as a workspace-wide claim.
    public var deletedLocalFile: Bool

    public init(
        sync: SyncEnvelope,
        screenshotID: UUID,
        spanID: UUID? = nil,
        fileName: String = "",
        activeAppName: String = "",
        capturedAt: Date,
        censoredAt: Date,
        model: String = "",
        category: PrivacyCategory,
        reason: String = "",
        confidence: Double,
        deletedLocalFile: Bool = false
    ) {
        self.sync = sync
        self.screenshotID = screenshotID
        self.spanID = spanID
        self.fileName = fileName
        self.activeAppName = activeAppName
        self.capturedAt = capturedAt
        self.censoredAt = censoredAt
        self.model = model
        self.category = category
        self.reason = reason
        self.confidence = confidence
        self.deletedLocalFile = deletedLocalFile
    }

    enum CodingKeys: String, CodingKey {
        case screenshotID = "screenshot_id"
        case spanID = "span_id"
        case fileName = "file_name"
        case activeAppName = "active_app_name"
        case capturedAt = "captured_at"
        case censoredAt = "censored_at"
        case model
        case category
        case reason
        case confidence
        case deletedLocalFile = "deleted_local_file"
    }

    public init(from decoder: any Decoder) throws {
        sync = try SyncEnvelope(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        screenshotID = try c.decodeUUID(.screenshotID)
        spanID = try c.decodeOptionalUUID(.spanID)
        fileName = try c.value(.fileName, or: "")
        activeAppName = try c.value(.activeAppName, or: "")
        capturedAt = try c.decode(Date.self, forKey: .capturedAt)
        censoredAt = try c.decode(Date.self, forKey: .censoredAt)
        model = try c.value(.model, or: "")
        category = try c.contractEnum(.category, or: .otherPrivate)
        reason = try c.value(.reason, or: "")
        confidence = try c.value(.confidence, or: 0)
        deletedLocalFile = try c.value(.deletedLocalFile, or: false)
    }

    public func encode(to encoder: any Encoder) throws {
        try sync.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeUUID(screenshotID, forKey: .screenshotID)
        try c.encodeNullableUUID(spanID, forKey: .spanID)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(activeAppName, forKey: .activeAppName)
        try c.encode(capturedAt, forKey: .capturedAt)
        try c.encode(censoredAt, forKey: .censoredAt)
        try c.encode(model, forKey: .model)
        try c.encode(category, forKey: .category)
        try c.encode(reason, forKey: .reason)
        try c.encode(confidence, forKey: .confidence)
        try c.encode(deletedLocalFile, forKey: .deletedLocalFile)
    }
}
