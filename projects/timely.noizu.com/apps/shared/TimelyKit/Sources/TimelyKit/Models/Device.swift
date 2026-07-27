import Foundation

/// A registered client install.
///
/// Devices sync so companions can render `origin_device_id` as a human name —
/// "captured on Keith's MacBook Pro" — and so the privacy gate is inspectable
/// from any surface. Only the owning device may mutate its own row; the server
/// rejects anything else with `not_device_owner`.
public struct Device: SyncEntity {
    public static var kind: EntityKind { .device }

    public var sync: SyncEnvelope

    public var userID: UUID?
    public var platform: DevicePlatform
    public var name: String
    public var appVersion: String
    public var osVersion: String?

    /// Half of the screenshot upload gate. Defaults to the privacy-preserving
    /// value. A device can only *tighten* the effective gate, never loosen the
    /// workspace policy — the effective gate is a logical AND.
    public var localOnlyScreenshots: Bool

    /// True only for macOS. Companions MUST register `false`, and the server
    /// rejects a capture-agent claim from a non-macOS platform.
    public var isCaptureAgent: Bool

    public var lastSeenAt: Date?
    public var lastSyncRevision: Int64
    public var revokedAt: Date?

    public init(
        sync: SyncEnvelope,
        userID: UUID? = nil,
        platform: DevicePlatform,
        name: String,
        appVersion: String,
        osVersion: String? = nil,
        localOnlyScreenshots: Bool = true,
        isCaptureAgent: Bool = false,
        lastSeenAt: Date? = nil,
        lastSyncRevision: Int64 = 0,
        revokedAt: Date? = nil
    ) {
        self.sync = sync
        self.userID = userID
        self.platform = platform
        self.name = name
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.localOnlyScreenshots = localOnlyScreenshots
        // A non-macOS platform cannot be a capture agent. Enforced here as well
        // as server-side so a companion cannot even compose the claim.
        self.isCaptureAgent = isCaptureAgent && platform.mayCapture
        self.lastSeenAt = lastSeenAt
        self.lastSyncRevision = lastSyncRevision
        self.revokedAt = revokedAt
    }

    public var isRevoked: Bool { revokedAt != nil }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case platform
        case name
        case appVersion = "app_version"
        case osVersion = "os_version"
        case localOnlyScreenshots = "local_only_screenshots"
        case isCaptureAgent = "is_capture_agent"
        case lastSeenAt = "last_seen_at"
        case lastSyncRevision = "last_sync_revision"
        case revokedAt = "revoked_at"
    }

    public init(from decoder: any Decoder) throws {
        sync = try SyncEnvelope(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userID = try c.decodeOptionalUUID(.userID)
        platform = try c.contractEnum(.platform, or: .web)
        name = try c.value(.name, or: "")
        appVersion = try c.value(.appVersion, or: "")
        osVersion = try c.optional(.osVersion)
        localOnlyScreenshots = try c.value(.localOnlyScreenshots, or: true)
        isCaptureAgent = try c.value(.isCaptureAgent, or: false)
        lastSeenAt = try c.optional(.lastSeenAt)
        lastSyncRevision = try c.value(.lastSyncRevision, or: Int64(0))
        revokedAt = try c.optional(.revokedAt)
    }

    public func encode(to encoder: any Encoder) throws {
        try sync.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeNullableUUID(userID, forKey: .userID)
        try c.encode(platform, forKey: .platform)
        try c.encode(name, forKey: .name)
        try c.encode(appVersion, forKey: .appVersion)
        try c.encode(osVersion, forKey: .osVersion)
        try c.encode(localOnlyScreenshots, forKey: .localOnlyScreenshots)
        try c.encode(isCaptureAgent, forKey: .isCaptureAgent)
        try c.encode(lastSeenAt, forKey: .lastSeenAt)
        try c.encode(lastSyncRevision, forKey: .lastSyncRevision)
        try c.encode(revokedAt, forKey: .revokedAt)
    }
}

/// `POST /api/v1/devices` body. Idempotent by client-supplied `device_id`; a
/// device that re-registers after reinstall SHOULD reuse its persisted id so
/// that `origin_device_id` history stays intact.
public struct DeviceRegistration: Hashable, Sendable, Codable {
    public var deviceID: UUID
    public var workspaceID: UUID
    public var platform: DevicePlatform
    public var name: String
    public var appVersion: String
    public var osVersion: String?
    public var localOnlyScreenshots: Bool
    public var isCaptureAgent: Bool

    public init(
        deviceID: UUID,
        workspaceID: UUID,
        platform: DevicePlatform,
        name: String,
        appVersion: String,
        osVersion: String? = nil,
        localOnlyScreenshots: Bool = true,
        isCaptureAgent: Bool = false
    ) {
        self.deviceID = deviceID
        self.workspaceID = workspaceID
        self.platform = platform
        self.name = name
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.localOnlyScreenshots = localOnlyScreenshots
        self.isCaptureAgent = isCaptureAgent && platform.mayCapture
    }

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case workspaceID = "workspace_id"
        case platform
        case name
        case appVersion = "app_version"
        case osVersion = "os_version"
        case localOnlyScreenshots = "local_only_screenshots"
        case isCaptureAgent = "is_capture_agent"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        deviceID = try c.decodeUUID(.deviceID)
        workspaceID = try c.decodeUUID(.workspaceID)
        platform = try c.contractEnum(.platform, or: .web)
        name = try c.value(.name, or: "")
        appVersion = try c.value(.appVersion, or: "")
        osVersion = try c.optional(.osVersion)
        localOnlyScreenshots = try c.value(.localOnlyScreenshots, or: true)
        isCaptureAgent = try c.value(.isCaptureAgent, or: false)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeUUID(deviceID, forKey: .deviceID)
        try c.encodeUUID(workspaceID, forKey: .workspaceID)
        try c.encode(platform, forKey: .platform)
        try c.encode(name, forKey: .name)
        try c.encode(appVersion, forKey: .appVersion)
        try c.encode(osVersion, forKey: .osVersion)
        try c.encode(localOnlyScreenshots, forKey: .localOnlyScreenshots)
        try c.encode(isCaptureAgent, forKey: .isCaptureAgent)
    }
}

/// `PATCH /api/v1/devices/{device_id}` body. Sparse: omitted fields are
/// untouched, so every property is optional.
public struct DeviceUpdate: Hashable, Sendable, Codable {
    public var name: String?
    public var appVersion: String?
    public var osVersion: String?
    public var localOnlyScreenshots: Bool?

    public init(
        name: String? = nil,
        appVersion: String? = nil,
        osVersion: String? = nil,
        localOnlyScreenshots: Bool? = nil
    ) {
        self.name = name
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.localOnlyScreenshots = localOnlyScreenshots
    }

    enum CodingKeys: String, CodingKey {
        case name
        case appVersion = "app_version"
        case osVersion = "os_version"
        case localOnlyScreenshots = "local_only_screenshots"
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(appVersion, forKey: .appVersion)
        try c.encodeIfPresent(osVersion, forKey: .osVersion)
        try c.encodeIfPresent(localOnlyScreenshots, forKey: .localOnlyScreenshots)
    }
}

/// Response to registration and to a device patch. Carries the workspace policy
/// so a client learns the upload gate at the same moment it learns its own id.
public struct DeviceEnvelope: Hashable, Sendable, Codable {
    public var device: Device
    public var workspacePolicy: WorkspacePolicy
    public var serverTime: Date

    /// Current workspace watermark. A freshly registered device may start its
    /// pull loop from 0 to bootstrap, or from this value to skip history.
    public var syncCursor: Int64

    public init(device: Device, workspacePolicy: WorkspacePolicy, serverTime: Date, syncCursor: Int64) {
        self.device = device
        self.workspacePolicy = workspacePolicy
        self.serverTime = serverTime
        self.syncCursor = syncCursor
    }

    enum CodingKeys: String, CodingKey {
        case device
        case workspacePolicy = "workspace_policy"
        case serverTime = "server_time"
        case syncCursor = "sync_cursor"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        device = try c.decode(Device.self, forKey: .device)
        workspacePolicy = try c.decode(WorkspacePolicy.self, forKey: .workspacePolicy)
        serverTime = try c.decode(Date.self, forKey: .serverTime)
        syncCursor = try c.value(.syncCursor, or: Int64(0))
    }
}
