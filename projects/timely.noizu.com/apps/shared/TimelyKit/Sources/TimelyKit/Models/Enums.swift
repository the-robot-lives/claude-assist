import Foundation

/// A string enum from the contract that must survive a member this build has
/// never heard of.
///
/// The contract's change rules make adding an enum member an *additive* change
/// that ships without a version bump, and require every client to "tolerate
/// unknown enum members by falling back to a documented default rather than
/// failing to decode". A hard decode failure here would take down a client's
/// entire sync loop because the server started using one new `ReviewReason`.
public protocol ContractEnum: RawRepresentable, Codable, Hashable, Sendable, CaseIterable
where RawValue == String {
    /// The documented fallback for an unrecognized member.
    static var unknownFallback: Self { get }
}

public extension ContractEnum {
    init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: raw) ?? Self.unknownFallback
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Entity kinds

public enum EntityKind: String, ContractEnum {
    case client
    case project
    case ticket
    case timeSpan = "time_span"
    case screenshot
    case visionAnalysis = "vision_analysis"
    case censoredScreenshot = "censored_screenshot"
    case device
    case userSettings = "user_settings"
    case workspacePolicy = "workspace_policy"

    /// There is no safe default for an entity kind — a bucket this build cannot
    /// name is a bucket it cannot store — so unknown kinds decode to this
    /// sentinel and are skipped with a recorded issue rather than crashing.
    case unknown = "__unknown__"

    public static var unknownFallback: EntityKind { .unknown }

    /// Append-only entities: the server rejects `update` with `immutable_entity`
    /// (conflict matrix rows 14 and 15), so the client must never enqueue one.
    public var isAppendOnly: Bool {
        self == .visionAnalysis || self == .censoredScreenshot
    }
}

// MARK: - Spans

public enum SpanSource: String, ContractEnum {
    case manual
    case timer
    case pomodoro

    public static var unknownFallback: SpanSource { .manual }

    public var label: String { rawValue.capitalized }
}

public enum ReviewState: String, ContractEnum {
    case unreviewed
    case needsReview = "needs_review"
    case reviewed
    case approved
    case locked
    case disputed

    public static var unknownFallback: ReviewState { .unreviewed }

    /// Whether this state should surface in a review queue.
    public var demandsAttention: Bool {
        self == .needsReview || self == .disputed
    }
}

public enum ReviewReasonCode: String, ContractEnum {
    case suspectedDuplicate = "suspected_duplicate"
    case billingOverlap = "billing_overlap"
    case unresolvedIdleGap = "unresolved_idle_gap"
    case lowConfidence = "low_confidence"
    case unresolvedReference = "unresolved_reference"
    case autoCreatedEntity = "auto_created_entity"
    case privacyCensored = "privacy_censored"
    case reopenedAfterApproval = "reopened_after_approval"
    case unknown = "__unknown__"

    public static var unknownFallback: ReviewReasonCode { .unknown }
}

public enum ReviewRaisedBy: String, ContractEnum {
    case server
    case device
    case user

    public static var unknownFallback: ReviewRaisedBy { .server }
}

public enum ReviewResolution: String, ContractEnum {
    case pending
    case accepted
    case dismissed
    case merged

    public static var unknownFallback: ReviewResolution { .pending }
}

// MARK: - Screenshots and privacy

public enum ScreenshotUploadState: String, ContractEnum {
    case localOnly = "local_only"
    case eligible
    case pending
    case uploaded
    case refused
    case purgePending = "purge_pending"
    case purged

    /// The privacy-preserving value. An unrecognized state must not be read as
    /// "bytes are available".
    public static var unknownFallback: ScreenshotUploadState { .localOnly }

    public var hasServerBytes: Bool { self == .uploaded }
}

public enum PrivacyCategory: String, ContractEnum {
    case none
    case secret
    case privateEmail = "private_email"
    case personalChat = "personal_chat"
    case adultMaterial = "adult_material"
    case financial
    case identity
    case medical
    case otherPrivate = "other_private"

    /// An unrecognized category is treated as private, not as `none` — the
    /// failure mode of guessing wrong in the other direction is retaining
    /// evidence the model flagged as sensitive.
    public static var unknownFallback: PrivacyCategory { .otherPrivate }

    public var isSensitive: Bool { self != .none }
}

public enum DevicePlatform: String, ContractEnum {
    case macos
    case ios
    case android
    case web

    public static var unknownFallback: DevicePlatform { .web }

    /// Only macOS may register as a capture agent; the server rejects the claim
    /// from any other platform.
    public var mayCapture: Bool { self == .macos }
}

public enum VisionProvider: String, ContractEnum {
    case openai
    case litellm
    case ollama
    case custom

    public static var unknownFallback: VisionProvider { .custom }
}

// MARK: - Mutations

public enum MutationOperation: String, ContractEnum {
    case create
    case update
    case delete

    public static var unknownFallback: MutationOperation { .update }
}

public enum MutationStatus: String, ContractEnum {
    case applied
    case conflict
    case rejected

    /// An unrecognized status is treated as `rejected`: terminal, dequeued, and
    /// surfaced. Treating it as `applied` would silently drop a mutation that
    /// never landed.
    public static var unknownFallback: MutationStatus { .rejected }

    /// All three contract statuses are terminal — the mutation leaves the queue.
    /// Only transport failures, 5xx and 429 are retried.
    public var isTerminal: Bool { true }
}

public enum MutationReason: String, ContractEnum {
    case staleWrite = "stale_write"
    case duplicateName = "duplicate_name"
    case tombstoned
    case spanReopenForbidden = "span_reopen_forbidden"
    case immutableEntity = "immutable_entity"
    case notDeviceOwner = "not_device_owner"
    case unknownEntity = "unknown_entity"
    case validationFailed = "validation_failed"
    case workspaceMismatch = "workspace_mismatch"
    case clockSkewRejected = "clock_skew_rejected"
    case lockedDay = "locked_day"
    case permissionDenied = "permission_denied"
    case batchRolledBack = "batch_rolled_back"
    case unknown = "__unknown__"

    public static var unknownFallback: MutationReason { .unknown }
}

// MARK: - Reports

public enum ReportGroupKey: String, ContractEnum {
    case client
    case project
    case ticket
    case day
    case source
    case none

    public static var unknownFallback: ReportGroupKey { .none }
}

public enum ReportWarningCode: String, ContractEnum {
    case spansNeedReview = "spans_need_review"
    case billingOverlap = "billing_overlap"
    case suspectedDuplicate = "suspected_duplicate"
    case openSpans = "open_spans"
    case lowEvidenceCoverage = "low_evidence_coverage"
    case lockedRange = "locked_range"
    case unknown = "__unknown__"

    public static var unknownFallback: ReportWarningCode { .unknown }
}
