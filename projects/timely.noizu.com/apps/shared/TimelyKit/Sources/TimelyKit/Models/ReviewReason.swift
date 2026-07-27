import Foundation

/// A non-destructive flag attached to a row by the server or a user.
///
/// The server raises these and never resolves them. It does not merge, trim,
/// reorder, pick a winner, or hide either side of a flagged pair — "review
/// beats recall". A client that auto-resolves a `suspected_duplicate` on the
/// user's behalf is destroying billable evidence to save a tap.
public struct ReviewReason: Hashable, Sendable, Codable {
    public var code: ReviewReasonCode
    public var detail: String?

    /// The other row in a pair, for `suspected_duplicate` and `billing_overlap`.
    public var relatedID: UUID?

    public var raisedAt: Date
    public var raisedBy: ReviewRaisedBy
    public var resolution: ReviewResolution
    public var resolvedAt: Date?

    public init(
        code: ReviewReasonCode,
        detail: String? = nil,
        relatedID: UUID? = nil,
        raisedAt: Date,
        raisedBy: ReviewRaisedBy,
        resolution: ReviewResolution = .pending,
        resolvedAt: Date? = nil
    ) {
        self.code = code
        self.detail = detail
        self.relatedID = relatedID
        self.raisedAt = raisedAt
        self.raisedBy = raisedBy
        self.resolution = resolution
        self.resolvedAt = resolvedAt
    }

    public var isPending: Bool { resolution == .pending }

    /// Whether this flag needs a human decision the client must not make. Both
    /// of these are raised on *both* rows of a pair, each citing the other.
    public var requiresUserJudgement: Bool {
        isPending && (code == .suspectedDuplicate || code == .billingOverlap)
    }

    /// Resolve locally. The flag is cleared only by a client mutation carrying
    /// one of the three terminal resolutions.
    public func resolving(as resolution: ReviewResolution, at now: Date = Date()) -> ReviewReason {
        var copy = self
        copy.resolution = resolution
        copy.resolvedAt = now
        return copy
    }

    enum CodingKeys: String, CodingKey {
        case code
        case detail
        case relatedID = "related_id"
        case raisedAt = "raised_at"
        case raisedBy = "raised_by"
        case resolution
        case resolvedAt = "resolved_at"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        code = try c.contractEnum(.code, or: .unknown)
        detail = try c.optional(.detail)
        relatedID = try c.decodeOptionalUUID(.relatedID)
        raisedAt = try c.decode(Date.self, forKey: .raisedAt)
        raisedBy = try c.contractEnum(.raisedBy, or: .server)
        resolution = try c.contractEnum(.resolution, or: .pending)
        resolvedAt = try c.optional(.resolvedAt)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(code, forKey: .code)
        try c.encode(detail, forKey: .detail)
        try c.encodeNullableUUID(relatedID, forKey: .relatedID)
        try c.encode(raisedAt, forKey: .raisedAt)
        try c.encode(raisedBy, forKey: .raisedBy)
        try c.encode(resolution, forKey: .resolution)
        try c.encode(resolvedAt, forKey: .resolvedAt)
    }
}
