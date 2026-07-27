import Foundation
import TimelyKit

/// This Mac's stable identity, and the workspace its rows belong to.
///
/// Timely has always worked without an account, and it has to keep working that
/// way: a user can install it, track a week, and only then decide to sign in.
/// But every synced row needs a `workspace_id` from the moment it is created,
/// so the app mints a **provisional** workspace on first launch and re-keys to
/// the real one at sign-in via `TimelyLocalStore.rebindWorkspace`.
///
/// Both ids live in `UserDefaults` rather than the Keychain on purpose. Neither
/// is a secret — they are the equivalent of a filename — and putting them in the
/// Keychain would mean a user who denies keychain access cannot track time.
/// The *tokens* are the secret, and those go in the Keychain.
@MainActor
final class DeviceIdentity {

    private enum Key {
        static let deviceID = "com.noizu.timely.deviceID"
        static let workspaceID = "com.noizu.timely.workspaceID"
        static let workspaceIsProvisional = "com.noizu.timely.workspaceIsProvisional"
        static let didImportLegacySnapshot = "com.noizu.timely.didImportLegacySnapshot"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Stable for the life of the install. UUIDv7 so the server's device table
    /// stays append-mostly.
    private(set) lazy var deviceID: UUID = {
        if let raw = defaults.string(forKey: Key.deviceID), let id = UUID(uuidString: raw) {
            return id
        }
        let minted = UUID.v7()
        defaults.set(minted.canonicalString, forKey: Key.deviceID)
        return minted
    }()

    /// The workspace local rows are currently keyed under — provisional until
    /// the user signs in.
    private(set) lazy var workspaceID: UUID = {
        if let raw = defaults.string(forKey: Key.workspaceID), let id = UUID(uuidString: raw) {
            return id
        }
        let minted = UUID.v7()
        defaults.set(minted.canonicalString, forKey: Key.workspaceID)
        defaults.set(true, forKey: Key.workspaceIsProvisional)
        return minted
    }()

    /// True while rows are keyed under a locally minted workspace. Signing in
    /// clears it.
    var workspaceIsProvisional: Bool {
        // Absent means "never set", which for an install that has a workspace id
        // can only be a provisional one — the real id is only ever written by
        // `adoptRealWorkspace`.
        defaults.object(forKey: Key.workspaceIsProvisional) as? Bool ?? true
    }

    /// Record the workspace the server says this account belongs to.
    ///
    /// Returns the previous id when a rebind is actually needed, so the caller
    /// can re-key the store; `nil` when nothing changed.
    @discardableResult
    func adoptRealWorkspace(_ id: UUID) -> UUID? {
        let previous = workspaceID
        guard previous != id else {
            defaults.set(false, forKey: Key.workspaceIsProvisional)
            return nil
        }
        workspaceID = id
        defaults.set(id.canonicalString, forKey: Key.workspaceID)
        defaults.set(false, forKey: Key.workspaceIsProvisional)
        return previous
    }

    /// Whether the one-time import of the legacy `timely-state.json` has run.
    ///
    /// The import is idempotent, so this is a cost optimization rather than a
    /// correctness guard — but re-reading and re-upserting a year of history on
    /// every launch is a visible hitch.
    var didImportLegacySnapshot: Bool {
        get { defaults.bool(forKey: Key.didImportLegacySnapshot) }
        set { defaults.set(newValue, forKey: Key.didImportLegacySnapshot) }
    }

    /// A human-readable name for the device row.
    var deviceName: String {
        Host.current().localizedName ?? "Mac"
    }
}
