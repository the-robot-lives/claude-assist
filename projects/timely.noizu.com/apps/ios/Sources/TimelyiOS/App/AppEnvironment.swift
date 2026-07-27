import Foundation
import Observation
import TimelyKit

#if canImport(UIKit) && os(iOS)
import UIKit
#endif

/// What the sync loop last did, in the terms the UI reports it.
struct SyncStatus: Sendable, Hashable {
    enum Session: Sendable, Hashable {
        /// Never signed in on this device, or signed out.
        case none
        /// Credentials present. Says nothing about whether they are fresh.
        case active
        /// The refresh token was rejected. Local work is unaffected.
        case expired
    }

    var session: Session = .none
    var isSyncing = false
    var lastSyncedAt: Date?
    var lastError: String?

    /// Mutations waiting to be pushed. A growing number offline is the system
    /// working, not failing, and the UI says so.
    var queuedMutations = 0

    var lastOutcome: SyncOutcome?

    var isOffline: Bool { lastError != nil }

    var needsReauthentication: Bool { session == .expired }
}

/// The composition root.
///
/// Holds the store, the auth client, the API client and the sync engine, and
/// nothing else. It exposes exactly one rule about connectivity: **there isn't
/// one.** No property here is consulted before a write, and no view asks it for
/// permission to edit. `SyncStatus` is a report, never a gate.
@MainActor
@Observable
final class AppEnvironment {

    enum Phase: Equatable {
        case launching

        /// Storage is open and a workspace — real or provisional — is bound.
        /// The app is fully usable from here with no network and no session.
        case ready

        /// Local storage could not be opened. Nothing works; say so plainly
        /// rather than showing an empty timeline that looks like no data.
        case failed(String)
    }

    let configuration: AppConfiguration
    let dismissals: any IdleGapDismissing

    private let identityStore: any IdentityStoring
    private let tokenStore: any TokenStoring
    private let transport: any HTTPTransporting
    private let storeLocation: URL?

    private(set) var phase: Phase = .launching
    private(set) var context: WorkspaceContext?
    private(set) var status = SyncStatus()

    private(set) var store: TimelyLocalStore?
    private(set) var auth: AuthClient?
    private(set) var api: TimelyAPIClient?
    private(set) var syncEngine: SyncEngine?

    private var identity: StoredIdentity

    /// The one persistence door, once a workspace is known.
    var repository: TimelyRepository? {
        guard let store, let context else { return nil }
        return TimelyRepository(store: store, context: context)
    }

    var deviceName: String {
        #if canImport(UIKit) && os(iOS)
        UIDevice.current.name
        #else
        "iOS device"
        #endif
    }

    var osVersion: String? {
        #if canImport(UIKit) && os(iOS)
        "iOS \(UIDevice.current.systemVersion)"
        #else
        nil
        #endif
    }

    // MARK: - Construction

    init(
        configuration: AppConfiguration,
        identityStore: any IdentityStoring = UserDefaultsIdentityStore(),
        tokenStore: any TokenStoring = KeychainTokenStore(),
        transport: any HTTPTransporting = URLSessionTransport(timeout: 30),
        dismissals: any IdleGapDismissing = IdleGapDismissals(),
        storeLocation: URL? = TimelyLocalStore.defaultURL()
    ) {
        self.configuration = configuration
        self.identityStore = identityStore
        self.tokenStore = tokenStore
        self.transport = transport
        self.dismissals = dismissals
        self.storeLocation = storeLocation
        self.identity = identityStore.load()
    }

    static func live() -> AppEnvironment {
        AppEnvironment(configuration: .fromBundle())
    }

    /// An environment backed by an in-memory store, for previews and tests.
    static func inMemory(
        configuration: AppConfiguration = AppConfiguration(
            baseURL: AppConfiguration.fallbackBaseURL,
            oidc: nil,
            appVersion: "0.0.0",
            appBuild: "0"
        ),
        context: WorkspaceContext,
        transport: any HTTPTransporting = StubTransport()
    ) -> AppEnvironment {
        AppEnvironment(
            configuration: configuration,
            identityStore: InMemoryIdentityStore(
                StoredIdentity(
                    deviceID: context.deviceID,
                    workspaceID: context.workspaceID,
                    userID: context.userID
                )
            ),
            tokenStore: InMemoryTokenStore(),
            transport: transport,
            dismissals: InMemoryIdleGapDismissals(),
            storeLocation: nil
        )
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        guard case .launching = phase else { return }

        let opened: TimelyLocalStore
        do {
            opened = try storeLocation.map { try TimelyLocalStore(url: $0) }
                ?? TimelyLocalStore()
        } catch {
            phase = .failed("Timely could not open its local database. \(error)")
            return
        }

        let auth = AuthClient(
            baseURL: configuration.baseURL, transport: transport, tokenStore: tokenStore
        )
        let api = TimelyAPIClient(
            baseURL: configuration.baseURL, transport: transport, auth: auth
        )

        store = opened
        self.auth = auth
        self.api = api

        // A session on disk may name a workspace this device has not recorded
        // yet — a reinstall that restored the Keychain but not the defaults.
        if identity.workspaceID == nil, let workspaceID = await auth.currentWorkspaceID {
            identity.workspaceID = workspaceID
            identity.userID = await auth.currentUserID
            identityStore.save(identity)
        }

        status.session = await auth.hasSession ? .active : .none

        // No workspace yet means this install has never signed in. Mint a
        // provisional one rather than blocking: the user can review, correct
        // and enter time immediately, and signing in later re-keys those rows
        // onto the real workspace.
        if identity.workspaceID == nil {
            identity.workspaceID = UUID.v7()
            identity.workspaceIsProvisional = true
            identityStore.save(identity)
        }

        if let context = identity.context {
            activate(context: context)
        }

        await refreshQueueDepth()
        await syncNow()
    }

    /// Bind local data to the workspace a sign-in resolved.
    ///
    /// When the current workspace is provisional this is a **re-key**, not a
    /// column update: taxonomy ids are `uuidv5(workspace_id, key)`, so every
    /// client, project and ticket id has to be re-derived or those rows would
    /// never merge with the same names created on another device.
    /// `rebindWorkspace` does that in one transaction and is idempotent.
    func adopt(workspaceID: UUID, userID: UUID?) async {
        let previous = identity.workspaceID

        if let previous, previous != workspaceID, identity.workspaceIsProvisional,
           let store {
            do {
                try await store.rebindWorkspace(
                    from: previous, to: workspaceID, deviceID: identity.deviceID
                )
            } catch {
                // Re-keying failed, so the local rows still belong to the
                // provisional workspace. Binding the context to the new id
                // anyway would hide them. Surface it and stay put.
                status.lastError = "Could not move local records to your workspace. \(error)"
                return
            }
        }

        identity.workspaceID = workspaceID
        identity.userID = userID
        identity.workspaceIsProvisional = false
        identityStore.save(identity)

        activate(context: WorkspaceContext(
            workspaceID: workspaceID, deviceID: identity.deviceID, userID: userID
        ))
        status.session = .active
        await registerDevice()
        await syncNow()
    }

    /// True while local records live under a locally minted workspace id.
    var isUsingProvisionalWorkspace: Bool { identity.workspaceIsProvisional }

    private func activate(context: WorkspaceContext) {
        self.context = context
        phase = .ready

        guard let store, let api, let auth else { return }
        syncEngine = SyncEngine(
            store: store,
            client: api,
            auth: auth,
            workspaceID: context.workspaceID,
            deviceID: context.deviceID
        )
    }

    // MARK: - Session

    /// Forget the session, keep every local record.
    ///
    /// Signing out is not a request to delete the user's time. The queue keeps
    /// its mutations and the store keeps its rows; the next sign-in to the same
    /// workspace picks up exactly where this left off.
    func signOut() async {
        try? await auth?.signOut()
        status.session = .none
    }

    func noteSessionExpired() {
        status.session = .expired
    }

    func noteSignedIn(workspaceID: UUID?, userID: UUID?) async {
        if let workspaceID, identity.workspaceID != workspaceID || identity.workspaceIsProvisional {
            await adopt(workspaceID: workspaceID, userID: userID)
        } else {
            if let userID, identity.userID != userID {
                identity.userID = userID
                identityStore.save(identity)
                if let existing = context {
                    self.context = WorkspaceContext(
                        workspaceID: existing.workspaceID,
                        deviceID: existing.deviceID,
                        userID: userID
                    )
                }
            }
            status.session = .active
            await registerDevice()
            await syncNow()
        }
    }

    func makeOIDCAuthenticator(webAuth: any WebAuthenticating) -> OIDCAuthenticator? {
        guard let oidc = configuration.oidc else { return nil }
        return OIDCAuthenticator(
            baseURL: configuration.baseURL,
            configuration: oidc,
            transport: transport,
            webAuth: webAuth
        )
    }

    // MARK: - Device registration

    /// Announce this install, best effort.
    ///
    /// Failure is silent by design: registration is how the workspace learns a
    /// friendly name for `origin_device_id`, not a precondition for anything.
    /// A companion that never reaches the server still works completely.
    func registerDevice() async {
        guard let repository, let api else { return }
        do {
            let device = try await repository.deviceOrDefault(
                appVersion: configuration.versionDescription,
                osVersion: osVersion,
                name: deviceName
            )
            try await repository.saveDevice(device)

            let registered = try await api.registerDevice(
                DeviceRegistration(
                    deviceID: device.id,
                    workspaceID: device.sync.workspaceID,
                    platform: .ios,
                    name: device.name,
                    appVersion: device.appVersion,
                    osVersion: device.osVersion,
                    localOnlyScreenshots: device.localOnlyScreenshots,
                    // A companion never claims capture. The server rejects the
                    // claim from a non-macOS platform anyway.
                    isCaptureAgent: false
                )
            )
            try await store?.upsert(registered, markDirty: false)
        } catch {
            // Local row is already written; the server will learn about this
            // device on a later attempt.
        }
    }

    // MARK: - Sync

    func syncNow() async {
        guard let syncEngine, !status.isSyncing else {
            await refreshQueueDepth()
            return
        }

        status.isSyncing = true
        defer { status.isSyncing = false }

        do {
            let outcome = try await syncEngine.sync()
            status.lastOutcome = outcome
            status.lastError = nil

            switch outcome.reason {
            case .sessionExpired:
                status.session = .expired
            case .noSession:
                status.session = .none
            case nil:
                if !outcome.skipped {
                    status.lastSyncedAt = Date()
                    status.session = .active
                }
            }
        } catch let error as AuthError where error.requiresReauthentication {
            status.session = .expired
        } catch {
            // Offline is the expected state, not an error state. It is recorded
            // so the UI can say "not synced since…", and nothing else changes.
            status.lastError = String(describing: error)
        }

        await refreshQueueDepth()
    }

    func refreshQueueDepth() async {
        guard let repository else { return }
        status.queuedMutations = (try? await repository.queueDepth()) ?? status.queuedMutations
    }
}
