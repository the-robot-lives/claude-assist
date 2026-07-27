import Foundation

/// A name-keyed taxonomy row: `client`, `project`, or `ticket`.
///
/// These are the entities whose ids are **derived**, not random. Two offline
/// devices that independently vivify "Acme / Redesign" compute the same UUIDv5
/// and their creates merge into one row on arrival with no coordination. That
/// is the single most important trick in the protocol, and it only works if
/// every client mints ids through ``Canon``.
public protocol TaxonomyEntity: SyncEntity {
    var name: String { get set }

    /// NFKC, whitespace-collapsed, case-folded `name`. Server-owned and the
    /// uniqueness key; recomputed locally so an offline client can enforce the
    /// same index.
    var canonicalName: String { get }

    var notes: String { get set }

    /// True when the row was vivified from a name reference rather than created
    /// deliberately. Auto-created rows arrive `needs_review`.
    var autoCreated: Bool { get set }

    /// Set on the loser of a merge. Readers follow this pointer exactly one hop
    /// and then give up; the winner absorbs nothing automatically, which keeps
    /// merge reversible and the audit trail intact.
    var mergedIntoID: UUID? { get set }

    var reviewState: ReviewState { get set }
}

public extension TaxonomyEntity {
    /// A merged-away row is still present and still referenced. It is not a
    /// tombstone in the ordinary sense and must not be rendered as a live
    /// choice in a picker.
    var isMergedAway: Bool { mergedIntoID != nil }
}

// MARK: - Client

public struct ClientRecord: TaxonomyEntity {
    public static var kind: EntityKind { .client }

    public var sync: SyncEnvelope
    public var name: String
    public var notes: String
    public var autoCreated: Bool
    public var mergedIntoID: UUID?
    public var reviewState: ReviewState

    /// The server's stored value when it sent one, otherwise computed. Storing
    /// what the server said rather than always recomputing means a divergence
    /// in `canon()` is *visible* locally instead of silently papered over.
    private var serverCanonicalName: String?

    public var canonicalName: String {
        serverCanonicalName ?? Canon.canon(name)
    }

    /// True when this build's `canon()` disagrees with the server's. Should
    /// always be false; if it is ever true, the three implementations have
    /// drifted and taxonomy duplication is imminent.
    public var canonicalNameDiverges: Bool {
        guard let serverCanonicalName else { return false }
        return serverCanonicalName != Canon.canon(name)
    }

    public init(
        sync: SyncEnvelope,
        name: String,
        notes: String = "",
        autoCreated: Bool = false,
        mergedIntoID: UUID? = nil,
        reviewState: ReviewState = .unreviewed
    ) {
        self.sync = sync
        self.name = name
        self.notes = notes
        self.autoCreated = autoCreated
        self.mergedIntoID = mergedIntoID
        self.reviewState = reviewState
        self.serverCanonicalName = nil
    }

    /// Mint a client with the deterministic id from §3.2, or `nil` when the
    /// name canonicalizes to empty.
    ///
    /// A name that is empty, whitespace-only, or made entirely of stripped
    /// invisibles is "no reference" — §3.3 requires that it MUST NOT vivify a
    /// row. Returning `nil` rather than a record with an id minted from
    /// `"client:"` is what enforces that at the type level.
    public static func minted(
        workspaceID: UUID,
        deviceID: UUID?,
        name: String,
        notes: String = "",
        autoCreated: Bool = false,
        at now: Date = Date()
    ) -> ClientRecord? {
        guard let id = Canon.clientID(workspaceID: workspaceID, name: name) else { return nil }
        return ClientRecord(
            sync: .local(
                id: id,
                workspaceID: workspaceID,
                deviceID: deviceID,
                at: now
            ),
            name: name,
            notes: notes,
            autoCreated: autoCreated
        )
    }

    enum CodingKeys: String, CodingKey {
        case name
        case canonicalName = "canonical_name"
        case notes
        case autoCreated = "auto_created"
        case mergedIntoID = "merged_into_id"
        case reviewState = "review_state"
    }

    public init(from decoder: any Decoder) throws {
        sync = try SyncEnvelope(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.value(.name, or: "")
        serverCanonicalName = try c.optional(.canonicalName)
        notes = try c.value(.notes, or: "")
        autoCreated = try c.value(.autoCreated, or: false)
        mergedIntoID = try c.decodeOptionalUUID(.mergedIntoID)
        reviewState = try c.contractEnum(.reviewState, or: .unreviewed)
    }

    public func encode(to encoder: any Encoder) throws {
        try sync.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(notes, forKey: .notes)
        try c.encode(autoCreated, forKey: .autoCreated)
        try c.encodeNullableUUID(mergedIntoID, forKey: .mergedIntoID)
        try c.encode(reviewState, forKey: .reviewState)
        // `canonical_name` is readOnly and server-owned; never asserted.
    }
}

// MARK: - Project

/// Timely's **domain** project — billable client work. Not the scaffold's PBAC
/// `project` resource.
public struct ProjectRecord: TaxonomyEntity {
    public static var kind: EntityKind { .project }

    public var sync: SyncEnvelope
    public var name: String
    public var clientID: UUID?
    public var clientName: String
    public var notes: String
    public var autoCreated: Bool
    public var mergedIntoID: UUID?
    public var reviewState: ReviewState

    private var serverCanonicalName: String?

    public var canonicalName: String { serverCanonicalName ?? Canon.canon(name) }

    public var canonicalNameDiverges: Bool {
        guard let serverCanonicalName else { return false }
        return serverCanonicalName != Canon.canon(name)
    }

    public init(
        sync: SyncEnvelope,
        name: String,
        clientID: UUID? = nil,
        clientName: String = "",
        notes: String = "",
        autoCreated: Bool = false,
        mergedIntoID: UUID? = nil,
        reviewState: ReviewState = .unreviewed
    ) {
        self.sync = sync
        self.name = name
        self.clientID = clientID
        self.clientName = clientName
        self.notes = notes
        self.autoCreated = autoCreated
        self.mergedIntoID = mergedIntoID
        self.reviewState = reviewState
        self.serverCanonicalName = nil
    }

    public static func minted(
        workspaceID: UUID,
        deviceID: UUID?,
        clientName: String,
        name: String,
        notes: String = "",
        autoCreated: Bool = false,
        at now: Date = Date()
    ) -> ProjectRecord? {
        // The *parent* may be absent — that is a legal empty key segment, and
        // `"project:/internal"` is its own scope. The project's own name may not.
        let clientID = Canon.clientID(workspaceID: workspaceID, name: clientName)
        guard let id = Canon.projectID(
            workspaceID: workspaceID, clientName: clientName, name: name
        ) else { return nil }
        return ProjectRecord(
            sync: .local(
                id: id,
                workspaceID: workspaceID,
                deviceID: deviceID,
                at: now
            ),
            name: name,
            clientID: clientID,
            clientName: clientName,
            notes: notes,
            autoCreated: autoCreated
        )
    }

    enum CodingKeys: String, CodingKey {
        case name
        case canonicalName = "canonical_name"
        case clientID = "client_id"
        case clientName = "client_name"
        case notes
        case autoCreated = "auto_created"
        case mergedIntoID = "merged_into_id"
        case reviewState = "review_state"
    }

    public init(from decoder: any Decoder) throws {
        sync = try SyncEnvelope(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.value(.name, or: "")
        serverCanonicalName = try c.optional(.canonicalName)
        clientID = try c.decodeOptionalUUID(.clientID)
        clientName = try c.value(.clientName, or: "")
        notes = try c.value(.notes, or: "")
        autoCreated = try c.value(.autoCreated, or: false)
        mergedIntoID = try c.decodeOptionalUUID(.mergedIntoID)
        reviewState = try c.contractEnum(.reviewState, or: .unreviewed)
    }

    public func encode(to encoder: any Encoder) throws {
        try sync.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encodeNullableUUID(clientID, forKey: .clientID)
        try c.encode(clientName, forKey: .clientName)
        try c.encode(notes, forKey: .notes)
        try c.encode(autoCreated, forKey: .autoCreated)
        try c.encodeNullableUUID(mergedIntoID, forKey: .mergedIntoID)
        try c.encode(reviewState, forKey: .reviewState)
    }
}

// MARK: - Ticket

public struct TicketRecord: TaxonomyEntity {
    public static var kind: EntityKind { .ticket }

    public var sync: SyncEnvelope
    public var name: String
    public var clientID: UUID?
    public var projectID: UUID?
    public var clientName: String
    public var projectName: String
    public var notes: String
    public var autoCreated: Bool
    public var mergedIntoID: UUID?
    public var reviewState: ReviewState

    private var serverCanonicalName: String?

    public var canonicalName: String { serverCanonicalName ?? Canon.canon(name) }

    public var canonicalNameDiverges: Bool {
        guard let serverCanonicalName else { return false }
        return serverCanonicalName != Canon.canon(name)
    }

    public init(
        sync: SyncEnvelope,
        name: String,
        clientID: UUID? = nil,
        projectID: UUID? = nil,
        clientName: String = "",
        projectName: String = "",
        notes: String = "",
        autoCreated: Bool = false,
        mergedIntoID: UUID? = nil,
        reviewState: ReviewState = .unreviewed
    ) {
        self.sync = sync
        self.name = name
        self.clientID = clientID
        self.projectID = projectID
        self.clientName = clientName
        self.projectName = projectName
        self.notes = notes
        self.autoCreated = autoCreated
        self.mergedIntoID = mergedIntoID
        self.reviewState = reviewState
        self.serverCanonicalName = nil
    }

    public static func minted(
        workspaceID: UUID,
        deviceID: UUID?,
        clientName: String,
        projectName: String,
        name: String,
        notes: String = "",
        autoCreated: Bool = false,
        at now: Date = Date()
    ) -> TicketRecord? {
        let clientID = Canon.clientID(workspaceID: workspaceID, name: clientName)
        let projectID = Canon.projectID(
            workspaceID: workspaceID, clientName: clientName, name: projectName
        )
        guard let id = Canon.ticketID(
            workspaceID: workspaceID,
            clientName: clientName,
            projectName: projectName,
            name: name
        ) else { return nil }
        return TicketRecord(
            sync: .local(
                id: id,
                workspaceID: workspaceID,
                deviceID: deviceID,
                at: now
            ),
            name: name,
            clientID: clientID,
            projectID: projectID,
            clientName: clientName,
            projectName: projectName,
            notes: notes,
            autoCreated: autoCreated
        )
    }

    enum CodingKeys: String, CodingKey {
        case name
        case canonicalName = "canonical_name"
        case clientID = "client_id"
        case projectID = "project_id"
        case clientName = "client_name"
        case projectName = "project_name"
        case notes
        case autoCreated = "auto_created"
        case mergedIntoID = "merged_into_id"
        case reviewState = "review_state"
    }

    public init(from decoder: any Decoder) throws {
        sync = try SyncEnvelope(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.value(.name, or: "")
        serverCanonicalName = try c.optional(.canonicalName)
        clientID = try c.decodeOptionalUUID(.clientID)
        projectID = try c.decodeOptionalUUID(.projectID)
        clientName = try c.value(.clientName, or: "")
        projectName = try c.value(.projectName, or: "")
        notes = try c.value(.notes, or: "")
        autoCreated = try c.value(.autoCreated, or: false)
        mergedIntoID = try c.decodeOptionalUUID(.mergedIntoID)
        reviewState = try c.contractEnum(.reviewState, or: .unreviewed)
    }

    public func encode(to encoder: any Encoder) throws {
        try sync.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encodeNullableUUID(clientID, forKey: .clientID)
        try c.encodeNullableUUID(projectID, forKey: .projectID)
        try c.encode(clientName, forKey: .clientName)
        try c.encode(projectName, forKey: .projectName)
        try c.encode(notes, forKey: .notes)
        try c.encode(autoCreated, forKey: .autoCreated)
        try c.encodeNullableUUID(mergedIntoID, forKey: .mergedIntoID)
        try c.encode(reviewState, forKey: .reviewState)
    }
}
