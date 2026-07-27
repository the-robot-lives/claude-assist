import Foundation

/// Mirrors the macOS `VisionLLMSettings` **minus `apiKey`**.
///
/// The API key is a device secret and is deliberately absent from the contract.
/// It lives in the device keychain and is never transmitted; the macOS model's
/// `env:` indirection is a device-local convenience, not a wire concept. There
/// is no property here to put it in, which is the point.
public struct VisionSyncSettings: Hashable, Sendable, Codable {
    public var analysisEnabled: Bool
    public var notifyOnProjectSwitch: Bool
    public var privacyRedactionEnabled: Bool
    public var notifyOnCensoredScreenshot: Bool
    public var provider: VisionProvider
    public var model: String
    public var baseURL: String?
    public var prompt: String?
    public var confidenceThreshold: Double

    public static let defaults = VisionSyncSettings()

    public init(
        analysisEnabled: Bool = false,
        notifyOnProjectSwitch: Bool = true,
        privacyRedactionEnabled: Bool = true,
        notifyOnCensoredScreenshot: Bool = true,
        provider: VisionProvider = .openai,
        model: String = "gpt-4o",
        baseURL: String? = nil,
        prompt: String? = nil,
        confidenceThreshold: Double = 0.72
    ) {
        self.analysisEnabled = analysisEnabled
        self.notifyOnProjectSwitch = notifyOnProjectSwitch
        self.privacyRedactionEnabled = privacyRedactionEnabled
        self.notifyOnCensoredScreenshot = notifyOnCensoredScreenshot
        self.provider = provider
        self.model = model
        self.baseURL = baseURL
        self.prompt = prompt
        self.confidenceThreshold = confidenceThreshold
    }

    enum CodingKeys: String, CodingKey {
        case analysisEnabled = "analysis_enabled"
        case notifyOnProjectSwitch = "notify_on_project_switch"
        case privacyRedactionEnabled = "privacy_redaction_enabled"
        case notifyOnCensoredScreenshot = "notify_on_censored_screenshot"
        case provider
        case model
        case baseURL = "base_url"
        case prompt
        case confidenceThreshold = "confidence_threshold"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        analysisEnabled = try c.value(.analysisEnabled, or: false)
        notifyOnProjectSwitch = try c.value(.notifyOnProjectSwitch, or: true)
        privacyRedactionEnabled = try c.value(.privacyRedactionEnabled, or: true)
        notifyOnCensoredScreenshot = try c.value(.notifyOnCensoredScreenshot, or: true)
        provider = try c.contractEnum(.provider, or: .openai)
        model = try c.value(.model, or: "gpt-4o")
        baseURL = try c.optional(.baseURL)
        prompt = try c.optional(.prompt)
        confidenceThreshold = try c.value(.confidenceThreshold, or: 0.72)
    }
}

/// Per-user, per-workspace preferences. Derived from macOS `AppSettings` with
/// two classes of field removed: device-local runtime state (pomodoro, capture
/// mode, screenshot paths, the vision API key) and workspace-governed values
/// that ``WorkspacePolicy`` sets a floor for.
///
/// `id` is deterministic: `uuidv5(workspace_id, "user_settings:" + user_id)`.
public struct UserSettings: SyncEntity {
    public static var kind: EntityKind { .userSettings }

    public var sync: SyncEnvelope
    public var userID: UUID

    public var screenshotIntervalMinutes: Double
    public var screenshotCaptureEnabled: Bool
    public var pomodoroWorkMinutes: Double
    public var pomodoroBreakMinutes: Double

    /// User preference. The **effective** value is the most restrictive of
    /// policy, user, and device — see ``PrivacyGate``.
    public var localOnlyScreenshots: Bool

    /// 0 means forever. Clamped down by the workspace policy when that is
    /// non-zero; a user may only be more restrictive than their workspace.
    public var retentionDays: Int

    public var idleThresholdMinutes: Double
    public var vision: VisionSyncSettings

    public init(
        sync: SyncEnvelope,
        userID: UUID,
        screenshotIntervalMinutes: Double = 5,
        screenshotCaptureEnabled: Bool = true,
        pomodoroWorkMinutes: Double = 25,
        pomodoroBreakMinutes: Double = 5,
        localOnlyScreenshots: Bool = true,
        retentionDays: Int = 0,
        idleThresholdMinutes: Double = 5,
        vision: VisionSyncSettings = .defaults
    ) {
        self.sync = sync
        self.userID = userID
        self.screenshotIntervalMinutes = screenshotIntervalMinutes
        self.screenshotCaptureEnabled = screenshotCaptureEnabled
        self.pomodoroWorkMinutes = pomodoroWorkMinutes
        self.pomodoroBreakMinutes = pomodoroBreakMinutes
        self.localOnlyScreenshots = localOnlyScreenshots
        self.retentionDays = retentionDays
        self.idleThresholdMinutes = idleThresholdMinutes
        self.vision = vision
    }

    public static func minted(
        workspaceID: UUID,
        userID: UUID,
        deviceID: UUID?,
        at now: Date = Date()
    ) -> UserSettings {
        UserSettings(
            sync: .local(
                id: Canon.userSettingsID(workspaceID: workspaceID, userID: userID),
                workspaceID: workspaceID,
                deviceID: deviceID,
                at: now
            ),
            userID: userID
        )
    }

    /// Retention actually in force, given the workspace floor. A non-zero
    /// policy value caps a user's "forever".
    public func effectiveRetentionDays(policy: WorkspacePolicy) -> Int {
        let policyDays = policy.screenshotRetentionDays
        if policyDays == 0 { return retentionDays }
        if retentionDays == 0 { return policyDays }
        return min(retentionDays, policyDays)
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case userID = "user_id"
        case screenshotIntervalMinutes = "screenshot_interval_minutes"
        case screenshotCaptureEnabled = "screenshot_capture_enabled"
        case pomodoroWorkMinutes = "pomodoro_work_minutes"
        case pomodoroBreakMinutes = "pomodoro_break_minutes"
        case localOnlyScreenshots = "local_only_screenshots"
        case retentionDays = "retention_days"
        case idleThresholdMinutes = "idle_threshold_minutes"
        case vision
    }

    public init(from decoder: any Decoder) throws {
        sync = try SyncEnvelope(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userID = try c.decodeUUID(.userID)
        screenshotIntervalMinutes = try c.value(.screenshotIntervalMinutes, or: 5)
        screenshotCaptureEnabled = try c.value(.screenshotCaptureEnabled, or: true)
        pomodoroWorkMinutes = try c.value(.pomodoroWorkMinutes, or: 25)
        pomodoroBreakMinutes = try c.value(.pomodoroBreakMinutes, or: 5)
        localOnlyScreenshots = try c.value(.localOnlyScreenshots, or: true)
        retentionDays = try c.value(.retentionDays, or: 0)
        idleThresholdMinutes = try c.value(.idleThresholdMinutes, or: 5)
        vision = try c.value(.vision, or: .defaults)
    }

    public func encode(to encoder: any Encoder) throws {
        try sync.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode("user_settings", forKey: .kind)
        try c.encodeUUID(userID, forKey: .userID)
        try c.encode(screenshotIntervalMinutes, forKey: .screenshotIntervalMinutes)
        try c.encode(screenshotCaptureEnabled, forKey: .screenshotCaptureEnabled)
        try c.encode(pomodoroWorkMinutes, forKey: .pomodoroWorkMinutes)
        try c.encode(pomodoroBreakMinutes, forKey: .pomodoroBreakMinutes)
        try c.encode(localOnlyScreenshots, forKey: .localOnlyScreenshots)
        try c.encode(retentionDays, forKey: .retentionDays)
        try c.encode(idleThresholdMinutes, forKey: .idleThresholdMinutes)
        try c.encode(vision, forKey: .vision)
    }
}

/// Workspace-wide governance. Only an owner or admin may mutate it; every other
/// actor receives `permission_denied`. Every default is the privacy-preserving
/// value.
///
/// `id` equals `workspace_id`.
public struct WorkspacePolicy: SyncEntity {
    public static var kind: EntityKind { .workspacePolicy }

    public var sync: SyncEnvelope

    /// Gate 1 of 2 for image byte upload. Flipping this to false moves existing
    /// blobs to `purge_pending` and then `purged`; metadata rows survive, so the
    /// timeline does not develop holes.
    public var screenshotUploadAllowed: Bool

    /// Whether verbatim model transcriptions of the screen may leave the device.
    /// Gates `VisionAnalysis.rawResponse`, which is image-equivalent.
    public var syncVisionRawResponse: Bool

    public var defaultLocalOnlyScreenshots: Bool
    public var screenshotRetentionDays: Int
    public var blobRetentionDays: Int
    public var requireApprovalBeforeExport: Bool
    public var idleThresholdMinutes: Double

    /// Spans starting on or before this date are locked against edits.
    public var lockedThrough: CalendarDate?

    public init(
        sync: SyncEnvelope,
        screenshotUploadAllowed: Bool = false,
        syncVisionRawResponse: Bool = false,
        defaultLocalOnlyScreenshots: Bool = true,
        screenshotRetentionDays: Int = 0,
        blobRetentionDays: Int = 30,
        requireApprovalBeforeExport: Bool = false,
        idleThresholdMinutes: Double = 5,
        lockedThrough: CalendarDate? = nil
    ) {
        self.sync = sync
        self.screenshotUploadAllowed = screenshotUploadAllowed
        self.syncVisionRawResponse = syncVisionRawResponse
        self.defaultLocalOnlyScreenshots = defaultLocalOnlyScreenshots
        self.screenshotRetentionDays = screenshotRetentionDays
        self.blobRetentionDays = blobRetentionDays
        self.requireApprovalBeforeExport = requireApprovalBeforeExport
        self.idleThresholdMinutes = idleThresholdMinutes
        self.lockedThrough = lockedThrough
    }

    /// The safe assumption for a client that has not yet pulled a policy: both
    /// gates closed.
    public static func closed(workspaceID: UUID, at now: Date = Date()) -> WorkspacePolicy {
        WorkspacePolicy(
            sync: SyncEnvelope(
                id: workspaceID,
                workspaceID: workspaceID,
                createdAt: now,
                updatedAt: now
            )
        )
    }

    /// Whether a span starting at this instant falls inside the locked range.
    /// Compared against the *end* of the locked day, since `locked_through` is
    /// inclusive.
    public func isLocked(spanStart: Date) -> Bool {
        guard let lockedThrough else { return false }
        return spanStart < lockedThrough.startOfDayUTC.addingTimeInterval(86_400)
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case screenshotUploadAllowed = "screenshot_upload_allowed"
        case syncVisionRawResponse = "sync_vision_raw_response"
        case defaultLocalOnlyScreenshots = "default_local_only_screenshots"
        case screenshotRetentionDays = "screenshot_retention_days"
        case blobRetentionDays = "blob_retention_days"
        case requireApprovalBeforeExport = "require_approval_before_export"
        case idleThresholdMinutes = "idle_threshold_minutes"
        case lockedThrough = "locked_through"
    }

    public init(from decoder: any Decoder) throws {
        sync = try SyncEnvelope(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        screenshotUploadAllowed = try c.value(.screenshotUploadAllowed, or: false)
        syncVisionRawResponse = try c.value(.syncVisionRawResponse, or: false)
        defaultLocalOnlyScreenshots = try c.value(.defaultLocalOnlyScreenshots, or: true)
        screenshotRetentionDays = try c.value(.screenshotRetentionDays, or: 0)
        blobRetentionDays = try c.value(.blobRetentionDays, or: 30)
        requireApprovalBeforeExport = try c.value(.requireApprovalBeforeExport, or: false)
        idleThresholdMinutes = try c.value(.idleThresholdMinutes, or: 5)
        lockedThrough = try c.optional(.lockedThrough)
    }

    public func encode(to encoder: any Encoder) throws {
        try sync.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode("workspace_policy", forKey: .kind)
        try c.encode(screenshotUploadAllowed, forKey: .screenshotUploadAllowed)
        try c.encode(syncVisionRawResponse, forKey: .syncVisionRawResponse)
        try c.encode(defaultLocalOnlyScreenshots, forKey: .defaultLocalOnlyScreenshots)
        try c.encode(screenshotRetentionDays, forKey: .screenshotRetentionDays)
        try c.encode(blobRetentionDays, forKey: .blobRetentionDays)
        try c.encode(requireApprovalBeforeExport, forKey: .requireApprovalBeforeExport)
        try c.encode(idleThresholdMinutes, forKey: .idleThresholdMinutes)
        try c.encode(lockedThrough, forKey: .lockedThrough)
    }
}

/// The `settings` bucket carries a discriminated union so user preferences and
/// workspace policy share one revision stream.
public enum SettingsRow: Hashable, Sendable, Codable {
    case userSettings(UserSettings)
    case workspacePolicy(WorkspacePolicy)

    private enum DiscriminatorKey: String, CodingKey { case kind }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: DiscriminatorKey.self)
        let kind = try c.decode(String.self, forKey: .kind)
        switch kind {
        case "user_settings":
            self = .userSettings(try UserSettings(from: decoder))
        case "workspace_policy":
            self = .workspacePolicy(try WorkspacePolicy(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .kind, in: c,
                debugDescription: "Unknown settings discriminator: \(kind)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .userSettings(let value): try value.encode(to: encoder)
        case .workspacePolicy(let value): try value.encode(to: encoder)
        }
    }

    public var envelope: SyncEnvelope {
        switch self {
        case .userSettings(let value): value.sync
        case .workspacePolicy(let value): value.sync
        }
    }
}
