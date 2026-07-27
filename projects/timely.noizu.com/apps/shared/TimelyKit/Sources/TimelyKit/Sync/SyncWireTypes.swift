import Foundation

// MARK: - Pull

/// `ChangeSet` — one page of changed rows, bucketed by entity.
///
/// Every bucket is required by the contract even when empty, so a client can
/// iterate a fixed key set. They are decoded leniently anyway: a server that
/// omits an empty bucket is not worth failing a whole page over.
public struct ChangeSet: Sendable, Decodable {
    public var clients: [ClientRecord]
    public var projects: [ProjectRecord]
    public var tickets: [TicketRecord]
    public var timeSpans: [TimeSpan]
    public var screenshots: [Screenshot]
    public var visionAnalyses: [VisionAnalysis]
    public var censoredScreenshots: [CensoredScreenshot]
    public var devices: [Device]
    public var settings: [UserSettings]

    enum CodingKeys: String, CodingKey {
        case clients
        case projects
        case tickets
        case timeSpans = "time_spans"
        case screenshots
        case visionAnalyses = "vision_analyses"
        case censoredScreenshots = "censored_screenshots"
        case devices
        case settings
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        clients = try c.value(.clients, or: [])
        projects = try c.value(.projects, or: [])
        tickets = try c.value(.tickets, or: [])
        timeSpans = try c.value(.timeSpans, or: [])
        screenshots = try c.value(.screenshots, or: [])
        visionAnalyses = try c.value(.visionAnalyses, or: [])
        censoredScreenshots = try c.value(.censoredScreenshots, or: [])
        devices = try c.value(.devices, or: [])
        settings = try c.value(.settings, or: [])
    }

    public var totalCount: Int {
        clients.count + projects.count + tickets.count + timeSpans.count
            + screenshots.count + visionAnalyses.count + censoredScreenshots.count
            + devices.count + settings.count
    }

    public var isEmpty: Bool { totalCount == 0 }
}

public struct ChangesResponse: Sendable, Decodable {
    public let changes: ChangeSet

    /// Highest gap-free committed revision in this page. Fed back as `since`.
    ///
    /// "Gap-free" is why the client must use this rather than the maximum
    /// revision it happens to see: a row committed at revision 40 may be
    /// visible while 38 is still in flight, and taking 40 would skip 38 forever.
    public let nextCursor: Int64

    public let hasMore: Bool

    /// Below this the server no longer guarantees tombstones exist.
    public let tombstoneHorizonRevision: Int64

    public let serverTime: Date

    enum CodingKeys: String, CodingKey {
        case changes
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
        case tombstoneHorizonRevision = "tombstone_horizon_revision"
        case serverTime = "server_time"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        changes = try c.decode(ChangeSet.self, forKey: .changes)
        nextCursor = try c.value(.nextCursor, or: 0)
        hasMore = try c.value(.hasMore, or: false)
        tombstoneHorizonRevision = try c.value(.tombstoneHorizonRevision, or: 0)
        serverTime = try c.decodeIfPresent(Date.self, forKey: .serverTime) ?? Date()
    }
}

// MARK: - Push

public struct MutationRequest: Sendable, Encodable {
    public let workspaceID: UUID
    public let deviceID: UUID

    /// All-or-nothing. Split and merge only; capped at 50 server-side.
    public let atomic: Bool

    public let mutations: [MutationEnvelope]

    enum CodingKeys: String, CodingKey {
        case workspaceID = "workspace_id"
        case deviceID = "device_id"
        case atomic
        case mutations
    }

    public init(workspaceID: UUID, deviceID: UUID, atomic: Bool = false, mutations: [MutationEnvelope]) {
        self.workspaceID = workspaceID
        self.deviceID = deviceID
        self.atomic = atomic
        self.mutations = mutations
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeUUID(workspaceID, forKey: .workspaceID)
        try c.encodeUUID(deviceID, forKey: .deviceID)
        try c.encode(atomic, forKey: .atomic)
        try c.encode(mutations, forKey: .mutations)
    }
}

public struct MutationEnvelope: Sendable, Encodable {
    public let mutationID: UUID
    public let entity: EntityKind
    public let operation: MutationOperation
    public let baseRevision: Int64?
    public let payload: JSONValue

    enum CodingKeys: String, CodingKey {
        case mutationID = "mutation_id"
        case entity
        case operation = "op"
        case baseRevision = "base_revision"
        case payload
    }

    public init(
        mutationID: UUID,
        entity: EntityKind,
        operation: MutationOperation,
        baseRevision: Int64?,
        payload: JSONValue
    ) {
        self.mutationID = mutationID
        self.entity = entity
        self.operation = operation
        self.baseRevision = baseRevision
        self.payload = payload
    }

    public init(_ queued: QueuedMutation) {
        self.init(
            mutationID: queued.mutationID,
            entity: queued.entityKind,
            operation: queued.operation,
            baseRevision: queued.baseRevision,
            payload: queued.payload
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeUUID(mutationID, forKey: .mutationID)
        try c.encode(entity, forKey: .entity)
        try c.encode(operation, forKey: .operation)
        try c.encode(baseRevision, forKey: .baseRevision)
        try c.encode(payload, forKey: .payload)
    }
}

/// A row the server changed that the client did not ask for — an auto-vivified
/// taxonomy row, or the tombstone cascade from a censorship assertion.
public struct SideEffect: Sendable, Decodable {
    public let entity: EntityKind
    public let row: JSONValue

    enum CodingKeys: String, CodingKey {
        case entity
        case row
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        entity = try c.contractEnum(.entity, or: .unknown)
        row = try c.value(.row, or: .null)
    }
}

public struct MutationResult: Sendable, Decodable {
    public let mutationID: UUID
    public let status: MutationStatus
    public let reason: MutationReason?
    public let message: String?

    /// Which kind of row `entity` is, from the result **envelope**.
    ///
    /// `results` is a flat array, so unlike `/sync/changes` — where each row
    /// sits in a named bucket — nothing about the row itself says what it is.
    /// Present even when `entity` is null, which is every `rejected` result and
    /// exactly when a client most needs to route the failure back.
    ///
    /// Nullable for two reasons: an older server predating the field, and a
    /// server naming an entity kind this build does not recognize.
    public let entityKind: EntityKind?

    /// The authoritative row after the attempt. Present for `applied` and
    /// `conflict` — for a conflict it is the *server's* version, which is what
    /// the client must adopt.
    public let entity: JSONValue?

    public let sideEffects: [SideEffect]

    /// True when the server replayed this from its mutation log rather than
    /// applying it fresh. Proof the idempotency key did its job.
    public let replayed: Bool

    /// True when `base_revision` was behind. The client should pull.
    public let staleBase: Bool

    public let unresolvedRefs: [String]

    enum CodingKeys: String, CodingKey {
        case mutationID = "mutation_id"
        case status
        case reason
        case message
        case entityKind = "entity_kind"
        case entity
        case sideEffects = "side_effects"
        case replayed
        case staleBase = "stale_base"
        case unresolvedRefs = "unresolved_refs"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mutationID = try c.decodeUUID(.mutationID)
        status = try c.contractEnum(.status, or: .rejected)
        reason = try c.decodeIfPresent(String.self, forKey: .reason)
            .map { MutationReason(rawValue: $0) ?? .unknown }
        message = try c.optional(.message)
        // Absent on an older server; unrecognized values decode to nil rather
        // than `.unknown`, so the caller can fall back rather than guess.
        entityKind = try c.decodeIfPresent(String.self, forKey: .entityKind)
            .flatMap { EntityKind(rawValue: $0) }
        entity = try c.optional(.entity)
        sideEffects = try c.value(.sideEffects, or: [])
        replayed = try c.value(.replayed, or: false)
        staleBase = try c.value(.staleBase, or: false)
        unresolvedRefs = try c.value(.unresolvedRefs, or: [])
    }
}

public struct MutationResponse: Sendable, Decodable {
    public let results: [MutationResult]
    public let nextCursor: Int64
    public let serverTime: Date

    enum CodingKeys: String, CodingKey {
        case results
        case nextCursor = "next_cursor"
        case serverTime = "server_time"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        results = try c.value(.results, or: [])
        nextCursor = try c.value(.nextCursor, or: 0)
        serverTime = try c.decodeIfPresent(Date.self, forKey: .serverTime) ?? Date()
    }
}
