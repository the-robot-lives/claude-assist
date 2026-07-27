import Foundation
import TimelyKit

/// Which device this install is, and which workspace it last belonged to.
///
/// None of this is secret — tokens live in the Keychain, not here — but the
/// device id must survive relaunch. `origin_device_id` is the LWW tie-break key
/// and the "captured on…" provenance line; a device that mints a new id every
/// launch quietly breaks both.
struct StoredIdentity: Sendable, Hashable {
    var deviceID: UUID
    var workspaceID: UUID?
    var userID: UUID?

    /// True while `workspaceID` is a locally minted placeholder.
    ///
    /// The companion is usable before it has ever reached the server, which
    /// means rows have to exist under *some* workspace id in the meantime.
    /// Signing in re-keys them onto the real workspace via
    /// `TimelyLocalStore.rebindWorkspace(from:to:deviceID:)` — a re-derivation
    /// of every UUIDv5 taxonomy id, not a column update.
    var workspaceIsProvisional: Bool = false

    var context: WorkspaceContext? {
        guard let workspaceID else { return nil }
        return WorkspaceContext(workspaceID: workspaceID, deviceID: deviceID, userID: userID)
    }
}

protocol IdentityStoring: Sendable {
    func load() -> StoredIdentity
    func save(_ identity: StoredIdentity)
}

/// `@unchecked` because `UserDefaults` is thread-safe but unannotated.
struct UserDefaultsIdentityStore: IdentityStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let deviceKey = "timely.device_id"
    private let workspaceKey = "timely.workspace_id"
    private let userKey = "timely.user_id"
    private let provisionalKey = "timely.workspace_provisional"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> StoredIdentity {
        let deviceID = defaults.string(forKey: deviceKey).flatMap(UUID.init(uuidString:))
            ?? mintDeviceID()

        return StoredIdentity(
            deviceID: deviceID,
            workspaceID: defaults.string(forKey: workspaceKey).flatMap(UUID.init(uuidString:)),
            userID: defaults.string(forKey: userKey).flatMap(UUID.init(uuidString:)),
            workspaceIsProvisional: defaults.bool(forKey: provisionalKey)
        )
    }

    func save(_ identity: StoredIdentity) {
        defaults.set(identity.deviceID.canonicalString, forKey: deviceKey)
        defaults.set(identity.workspaceID?.canonicalString, forKey: workspaceKey)
        defaults.set(identity.userID?.canonicalString, forKey: userKey)
        defaults.set(identity.workspaceIsProvisional, forKey: provisionalKey)
    }

    /// v7 so the id sorts by creation, matching every other locally minted id.
    private func mintDeviceID() -> UUID {
        let minted = UUID.v7()
        defaults.set(minted.canonicalString, forKey: deviceKey)
        return minted
    }
}

/// In-memory identity, for tests and previews.
final class InMemoryIdentityStore: IdentityStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var identity: StoredIdentity

    init(_ identity: StoredIdentity = StoredIdentity(deviceID: UUID.v7())) {
        self.identity = identity
    }

    func load() -> StoredIdentity {
        lock.lock(); defer { lock.unlock() }
        return identity
    }

    func save(_ identity: StoredIdentity) {
        lock.lock(); defer { lock.unlock() }
        self.identity = identity
    }
}
