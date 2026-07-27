import Foundation
import Security

/// A stored credential pair.
///
/// `refreshToken` is the long-lived secret; `accessToken` expires in an hour.
/// Both live in the Keychain — never `UserDefaults`, which is a plist in the
/// app container, unencrypted, included in backups, and readable by anything
/// that can read the container.
public struct AuthTokens: Sendable, Hashable, Codable {
    public var accessToken: String
    public var refreshToken: String

    /// When `accessToken` stops being accepted. Advisory: the server is the
    /// authority and a 401 can arrive before this passes (clock skew, or a
    /// revoked session).
    public var expiresAt: Date

    public var userID: UUID?
    public var workspaceID: UUID?

    public init(
        accessToken: String,
        refreshToken: String,
        expiresAt: Date,
        userID: UUID? = nil,
        workspaceID: UUID? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.userID = userID
        self.workspaceID = workspaceID
    }

    /// True when the access token is past its stated life. **This is not a
    /// reason to block anything the user is doing** — it is a hint to the sync
    /// engine that it should refresh before its next request.
    public func isExpired(at now: Date = Date(), leeway: TimeInterval = 60) -> Bool {
        now.addingTimeInterval(leeway) >= expiresAt
    }
}

/// Where tokens live.
///
/// A protocol so tests can substitute an in-memory implementation without
/// touching the login keychain, and so a host app can supply a shared
/// access-group store when an extension needs the same session.
public protocol TokenStoring: Sendable {
    func load() throws -> AuthTokens?
    func save(_ tokens: AuthTokens) throws
    func clear() throws
}

/// Keychain-backed token storage.
///
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`:
/// - *AfterFirstUnlock* because sync runs in the background while the phone is
///   locked, and `WhenUnlocked` would make a background refresh fail.
/// - *ThisDeviceOnly* because a refresh token restored onto a second device
///   from an iCloud backup is a session the user never opened there.
public struct KeychainTokenStore: TokenStoring {

    private let service: String
    private let account: String
    private let accessGroup: String?

    public init(
        service: String = "com.noizu.timely.auth",
        account: String = "primary",
        accessGroup: String? = nil
    ) {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
    }

    private var baseQuery: [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }

    public func load() throws -> AuthTokens? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return try TimelyJSON.decode(AuthTokens.self, from: data)
        case errSecItemNotFound:
            return nil
        default:
            throw AuthError.keychain(status: status)
        }
    }

    public func save(_ tokens: AuthTokens) throws {
        let data = try TimelyJSON.encode(tokens)

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var insert = baseQuery
            insert.merge(attributes) { _, new in new }
            let addStatus = SecItemAdd(insert as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw AuthError.keychain(status: addStatus)
            }
        default:
            throw AuthError.keychain(status: status)
        }
    }

    public func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthError.keychain(status: status)
        }
    }
}

/// In-memory token storage for tests and previews. Never ships in a UI target.
public final class InMemoryTokenStore: TokenStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var tokens: AuthTokens?

    public init(tokens: AuthTokens? = nil) {
        self.tokens = tokens
    }

    public func load() throws -> AuthTokens? {
        lock.lock(); defer { lock.unlock() }
        return tokens
    }

    public func save(_ tokens: AuthTokens) throws {
        lock.lock(); defer { lock.unlock() }
        self.tokens = tokens
    }

    public func clear() throws {
        lock.lock(); defer { lock.unlock() }
        tokens = nil
    }
}

// MARK: - Errors

public enum AuthError: Error, CustomStringConvertible, Sendable {
    case keychain(status: OSStatus)
    case notAuthenticated
    case invalidCredentials
    case refreshFailed(String)

    /// The refresh token itself was rejected. The only error here that requires
    /// the user to log in again — everything else is retryable.
    case sessionExpired

    case transport(String)
    case malformedResponse(String)

    public var description: String {
        switch self {
        case .keychain(let status):
            return "Keychain error \(status)"
        case .notAuthenticated:
            return "Not signed in"
        case .invalidCredentials:
            return "That email and password did not match an account"
        case .refreshFailed(let message):
            return "Could not refresh the session: \(message)"
        case .sessionExpired:
            return "Your session expired. Sign in again to resume syncing."
        case .transport(let message):
            return "Network error: \(message)"
        case .malformedResponse(let message):
            return "Unexpected response from the server: \(message)"
        }
    }

    /// True when the user must re-enter credentials. Everything else the sync
    /// engine can retry on its own, and **nothing** here should stop local use.
    public var requiresReauthentication: Bool {
        switch self {
        case .sessionExpired, .invalidCredentials, .notAuthenticated: return true
        default: return false
        }
    }
}
