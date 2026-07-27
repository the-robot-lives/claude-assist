import Foundation

/// A tracked interval. Mirrors the macOS `TrackedTimeSpan`, wrapped in the sync
/// envelope and carrying both the resolved taxonomy ids and the raw names.
///
/// Timely models time as **overlapping intervals**, not one linear stopwatch.
/// Two live spans covering the same instant are legal and expected, and the
/// conflict matrix explicitly declines to treat overlap as an error (row 8).
/// Any client code that assumes a single active span is wrong.
///
/// The dual `*_id` / `*_name` representation is the genuine impedance mismatch
/// in the protocol (§6): the macOS agent has always referenced client, project
/// and ticket by plain string and auto-created them on first use. On write, a
/// name is a resolution input when the id is absent. On read, the name is a
/// denormalized convenience refreshed from the referenced row.
public struct TimeSpan: SyncEntity {
    public static var kind: EntityKind { .timeSpan }

    public var sync: SyncEnvelope

    public var title: String

    public var clientID: UUID?
    public var projectID: UUID?
    public var ticketID: UUID?

    /// Resolution input on write when the matching id is absent; denormalized
    /// name on read. Empty means "no reference" — never a row named `""`.
    public var clientName: String
    public var projectName: String
    public var ticketName: String

    public var start: Date

    /// Null means the span is open. A **closed** span may never be reopened by
    /// a stale update: the server rejects that with `span_reopen_forbidden`
    /// (conflict matrix row 6), because a closed span is evidence and a device
    /// that has not seen the close must not undo it.
    public var end: Date?

    public var source: SpanSource
    public var isBillable: Bool
    public var notes: String

    public var reviewState: ReviewState
    public var reviewReasons: [ReviewReason]

    /// Lineage for split and merge. A split emits N creates each citing the
    /// original plus one delete of the original, in one atomic batch; a merge
    /// emits one create citing all sources plus their deletes.
    public var derivedFromSpanIDs: [UUID]

    /// Set when a reviewed day is locked. Updates to a locked span are rejected.
    public var lockedAt: Date?

    /// Server-clamped `updated_at` — the value actually compared during LWW.
    /// Read-only; never sent.
    public var updatedAtEffective: Date?

    public init(
        sync: SyncEnvelope,
        title: String,
        clientID: UUID? = nil,
        projectID: UUID? = nil,
        ticketID: UUID? = nil,
        clientName: String = "",
        projectName: String = "",
        ticketName: String = "",
        start: Date,
        end: Date? = nil,
        source: SpanSource,
        isBillable: Bool = false,
        notes: String = "",
        reviewState: ReviewState = .unreviewed,
        reviewReasons: [ReviewReason] = [],
        derivedFromSpanIDs: [UUID] = [],
        lockedAt: Date? = nil,
        updatedAtEffective: Date? = nil
    ) {
        self.sync = sync
        self.title = title
        self.clientID = clientID
        self.projectID = projectID
        self.ticketID = ticketID
        self.clientName = clientName
        self.projectName = projectName
        self.ticketName = ticketName
        self.start = start
        self.end = end
        self.source = source
        self.isBillable = isBillable
        self.notes = notes
        self.reviewState = reviewState
        self.reviewReasons = reviewReasons
        self.derivedFromSpanIDs = derivedFromSpanIDs
        self.lockedAt = lockedAt
        self.updatedAtEffective = updatedAtEffective
    }

    // MARK: - Derived

    public var isOpen: Bool { end == nil }

    public func duration(now: Date = Date()) -> TimeInterval {
        (end ?? now).timeIntervalSince(start)
    }

    public var isLocked: Bool { lockedAt != nil }

    /// The timestamp LWW actually compares. Falls back to the unclamped client
    /// clock for a row the server has not yet seen.
    public var effectiveUpdatedAt: Date { updatedAtEffective ?? sync.updatedAt }

    /// Flags a human still has to answer. The UI surfaces these; nothing here
    /// resolves them.
    public var pendingReviewReasons: [ReviewReason] {
        reviewReasons.filter(\.isPending)
    }

    public var needsReview: Bool {
        reviewState.demandsAttention || !pendingReviewReasons.isEmpty
    }

    /// Overlap with another span, in seconds. Used by the local weighted
    /// rollup, and by nothing that mutates.
    public func overlap(with other: TimeSpan, now: Date = Date()) -> TimeInterval {
        let aEnd = end ?? now
        let bEnd = other.end ?? now
        return max(0, min(aEnd, bEnd).timeIntervalSince(max(start, other.start)))
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case title
        case clientID = "client_id"
        case projectID = "project_id"
        case ticketID = "ticket_id"
        case clientName = "client_name"
        case projectName = "project_name"
        case ticketName = "ticket_name"
        case start
        case end
        case source
        case isBillable = "is_billable"
        case notes
        case reviewState = "review_state"
        case reviewReasons = "review_reasons"
        case derivedFromSpanIDs = "derived_from_span_ids"
        case lockedAt = "locked_at"
        case updatedAtEffective = "updated_at_effective"
    }

    public init(from decoder: any Decoder) throws {
        sync = try SyncEnvelope(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.value(.title, or: "")
        clientID = try c.decodeOptionalUUID(.clientID)
        projectID = try c.decodeOptionalUUID(.projectID)
        ticketID = try c.decodeOptionalUUID(.ticketID)
        clientName = try c.value(.clientName, or: "")
        projectName = try c.value(.projectName, or: "")
        ticketName = try c.value(.ticketName, or: "")
        start = try c.decode(Date.self, forKey: .start)
        end = try c.optional(.end)
        source = try c.contractEnum(.source, or: .manual)
        isBillable = try c.value(.isBillable, or: false)
        notes = try c.value(.notes, or: "")
        reviewState = try c.contractEnum(.reviewState, or: .unreviewed)
        reviewReasons = try c.value(.reviewReasons, or: [])
        derivedFromSpanIDs = try c.decodeUUIDArray(.derivedFromSpanIDs)
        lockedAt = try c.optional(.lockedAt)
        updatedAtEffective = try c.optional(.updatedAtEffective)
    }

    public func encode(to encoder: any Encoder) throws {
        try sync.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
        try c.encodeNullableUUID(clientID, forKey: .clientID)
        try c.encodeNullableUUID(projectID, forKey: .projectID)
        try c.encodeNullableUUID(ticketID, forKey: .ticketID)
        try c.encode(clientName, forKey: .clientName)
        try c.encode(projectName, forKey: .projectName)
        try c.encode(ticketName, forKey: .ticketName)
        try c.encode(start, forKey: .start)
        // `encode`, NOT `encodeIfPresent` — the explicit null is deliberate and
        // load-bearing. See SYNC-PROTOCOL.md §8.2, the note under rows 6/7/7a.
        //
        // `"end": null` and an absent `end` are different instructions on the
        // wire. Present-and-null asserts "this span is open", which against a
        // row the server holds closed is a deliberate reopen (row 7, or row 6's
        // rejection if `base_revision` is stale). Omitting the key means "I am
        // not touching this field" (row 7a).
        //
        // Switching to `encodeIfPresent` looks like a tidy-up and is a bug: it
        // deletes the key at exactly the moment it carries meaning, so a user
        // who genuinely reopens a span can no longer say so. It is safe to send
        // the null here because the server's guard fires on *its* copy being
        // closed, so an ordinary edit to an open span is never read as a reopen.
        //
        // The same reasoning applies to `deleted_at`, `ticket_id` and
        // `locked_at` below and in `SyncEnvelope` — all nullable AND required,
        // so omitting them produces a body that fails the contract's own schema.
        try c.encode(end, forKey: .end)
        try c.encode(source, forKey: .source)
        try c.encode(isBillable, forKey: .isBillable)
        try c.encode(notes, forKey: .notes)
        try c.encode(reviewState, forKey: .reviewState)
        try c.encode(reviewReasons, forKey: .reviewReasons)
        try c.encode(derivedFromSpanIDs.map(\.canonicalString), forKey: .derivedFromSpanIDs)
        try c.encode(lockedAt, forKey: .lockedAt)

        // `updated_at_effective` is readOnly. Omitted on the wire rather than
        // sent and ignored, so a client can never appear to assert it — but
        // kept in local storage, because it is the timestamp LWW actually
        // compares and losing it on relaunch would silently change which of two
        // concurrent edits wins.
        if encoder.includesServerOwnedFields {
            try c.encode(updatedAtEffective, forKey: .updatedAtEffective)
        }
    }
}
