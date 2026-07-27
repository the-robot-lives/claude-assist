import Foundation

/// The seven fields carried by every syncable row (`SYNC-PROTOCOL.md` §4).
///
/// All seven are persisted locally. Dropping `serverRevision` in particular is
/// not a space optimization — a client that cannot report its watermark
/// re-bootstraps the entire workspace on every launch, forever.
public struct SyncEnvelope: Hashable, Sendable, Codable {

    /// Primary key. Minted locally; never allocated by the server.
    public var id: UUID

    /// Tenancy scope. Equal to the scaffold's organization id.
    public var workspaceID: UUID

    /// Client wall clock at creation. Informational only — never used for
    /// ordering, because client clocks are wrong.
    public var createdAt: Date

    /// Client wall clock at last local edit. Advisory LWW input. The server
    /// compares `min(updatedAt, receivedAt)`, not this value.
    public var updatedAt: Date

    /// Server-assigned, monotonic per workspace. The one and only sync cursor.
    /// Zero for a row the server has not yet acknowledged.
    public var serverRevision: Int64

    /// Soft-delete tombstone. A non-null value always wins over a concurrent
    /// update (conflict matrix row 2).
    public var deletedAt: Date?

    /// Last authoring device, and the LWW tie-break key: on equal effective
    /// timestamps the lexically greater device id wins, so every client
    /// computes the same winner without asking the server.
    public var originDeviceID: UUID?

    public init(
        id: UUID,
        workspaceID: UUID,
        createdAt: Date,
        updatedAt: Date,
        serverRevision: Int64 = 0,
        deletedAt: Date? = nil,
        originDeviceID: UUID? = nil
    ) {
        self.id = id
        self.workspaceID = workspaceID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.serverRevision = serverRevision
        self.deletedAt = deletedAt
        self.originDeviceID = originDeviceID
    }

    /// A fresh, never-synced envelope for a locally minted row.
    public static func local(
        id: UUID,
        workspaceID: UUID,
        deviceID: UUID?,
        at now: Date = Date()
    ) -> SyncEnvelope {
        SyncEnvelope(
            id: id,
            workspaceID: workspaceID,
            createdAt: now,
            updatedAt: now,
            serverRevision: 0,
            deletedAt: nil,
            originDeviceID: deviceID
        )
    }

    public var isDeleted: Bool { deletedAt != nil }

    /// True when the server has never acknowledged this row.
    public var isLocalOnly: Bool { serverRevision == 0 }

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceID = "workspace_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case serverRevision = "server_revision"
        case deletedAt = "deleted_at"
        case originDeviceID = "origin_device_id"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeUUID(.id)
        workspaceID = try container.decodeUUID(.workspaceID)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        serverRevision = try container.decodeIfPresent(Int64.self, forKey: .serverRevision) ?? 0
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt) ?? nil
        originDeviceID = try container.decodeOptionalUUID(.originDeviceID)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.canonicalString, forKey: .id)
        try container.encode(workspaceID.canonicalString, forKey: .workspaceID)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(serverRevision, forKey: .serverRevision)
        // `deleted_at` and `origin_device_id` are nullable but *required*. The
        // synthesized encoder would omit them when nil, producing a body that
        // fails the contract's own schema.
        try container.encode(deletedAt, forKey: .deletedAt)
        try container.encode(originDeviceID?.canonicalString, forKey: .originDeviceID)
    }
}

/// Anything the sync loop can store, page, and push.
public protocol SyncEntity: Codable, Sendable, Identifiable, Hashable {
    static var kind: EntityKind { get }
    var sync: SyncEnvelope { get set }
}

public extension SyncEntity {
    var id: UUID { sync.id }
    var workspaceID: UUID { sync.workspaceID }
    var serverRevision: Int64 { sync.serverRevision }
    var isDeleted: Bool { sync.isDeleted }

    /// Stamp a local edit. `updatedAt` is advisory only, but the server clamps
    /// rather than rejects, so a wrong clock costs a `low_confidence` flag
    /// rather than a lost write.
    mutating func touch(deviceID: UUID?, at now: Date = Date()) {
        sync.updatedAt = now
        sync.originDeviceID = deviceID
    }

    /// Apply a tombstone. Never a hard delete — the protocol's fourth design
    /// commitment is that nothing is destroyed.
    mutating func tombstone(deviceID: UUID?, at now: Date = Date()) {
        sync.deletedAt = now
        sync.updatedAt = now
        sync.originDeviceID = deviceID
    }
}

// MARK: - Decoding helpers

extension KeyedDecodingContainer {

    /// UUIDs arrive as lowercase canonical strings. `Foundation`'s `UUID`
    /// conformance handles that, but a malformed value should name the field
    /// rather than surfacing as an opaque type mismatch.
    func decodeUUID(_ key: Key) throws -> UUID {
        let text = try decode(String.self, forKey: key)
        guard let value = UUID(uuidString: text) else {
            throw DecodingError.dataCorruptedError(
                forKey: key, in: self, debugDescription: "Not a UUID: \(text)"
            )
        }
        return value
    }

    func decodeOptionalUUID(_ key: Key) throws -> UUID? {
        guard let text = try decodeIfPresent(String.self, forKey: key) else { return nil }
        guard let value = UUID(uuidString: text) else {
            throw DecodingError.dataCorruptedError(
                forKey: key, in: self, debugDescription: "Not a UUID: \(text)"
            )
        }
        return value
    }

    func decodeUUIDArray(_ key: Key) throws -> [UUID] {
        let raw = try decodeIfPresent([String].self, forKey: key) ?? []
        return raw.compactMap(UUID.init(uuidString:))
    }

    /// A field the contract declares with a `default:`. A server that omits it
    /// is conformant, so this must not throw.
    func value<T: Decodable>(_ key: Key, or fallback: T) throws -> T {
        try decodeIfPresent(T.self, forKey: key) ?? fallback
    }

    func optional<T: Decodable>(_ key: Key) throws -> T? {
        try decodeIfPresent(T.self, forKey: key) ?? nil
    }

    /// An enum member this build may not know; falls back rather than failing
    /// the whole page.
    func contractEnum<T: ContractEnum>(_ key: Key, or fallback: T) throws -> T {
        guard let raw = try decodeIfPresent(String.self, forKey: key) else { return fallback }
        return T(rawValue: raw) ?? T.unknownFallback
    }
}

extension KeyedEncodingContainer {
    mutating func encodeUUID(_ value: UUID, forKey key: Key) throws {
        try encode(value.canonicalString, forKey: key)
    }

    /// Encodes an explicit `null` when absent, for nullable-but-required fields.
    mutating func encodeNullableUUID(_ value: UUID?, forKey key: Key) throws {
        try encode(value?.canonicalString, forKey: key)
    }
}
