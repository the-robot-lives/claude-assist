import Foundation

/// Email/password authentication against the scaffold's auth endpoints, and
/// custody of the resulting tokens.
///
/// **This type never gates local work.** It has no opinion about whether the
/// user may start a timer or edit a span; it only answers "what Authorization
/// header should the next network request carry, if any". A companion whose
/// refresh token expired six weeks ago is a fully functional offline time
/// tracker with a growing push queue, and that is the intended experience — not
/// a degraded one.
public actor AuthClient {

    private let baseURL: URL
    private let transport: any HTTPTransporting
    private let tokenStore: any TokenStoring

    private var cached: AuthTokens?

    /// Collapses a refresh storm. When the access token expires, every queued
    /// request 401s at once; without this they would each mint a refresh and
    /// the losers would invalidate the winner's rotated refresh token.
    private var inFlightRefresh: Task<AuthTokens, Error>?

    public init(
        baseURL: URL,
        transport: any HTTPTransporting = URLSessionTransport(),
        tokenStore: any TokenStoring = KeychainTokenStore()
    ) {
        self.baseURL = baseURL
        self.transport = transport
        self.tokenStore = tokenStore
    }

    // MARK: - State

    /// Whether a session exists at all. **Not** whether it is fresh — an
    /// expired session is still a session, and the refresh token may well work.
    public var hasSession: Bool {
        get async { (try? currentTokens()) != nil }
    }

    public var currentUserID: UUID? {
        get async { try? currentTokens()?.userID }
    }

    public var currentWorkspaceID: UUID? {
        get async { try? currentTokens()?.workspaceID }
    }

    private func currentTokens() throws -> AuthTokens? {
        if let cached { return cached }
        cached = try tokenStore.load()
        return cached
    }

    // MARK: - Sign in / out

    @discardableResult
    public func signIn(email: String, password: String) async throws -> AuthTokens {
        let body = try TimelyJSON.encode(
            LoginRequest(email: email, password: password)
        )

        var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/auth/login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await transport.send(request)

        guard response.statusCode != 401 && response.statusCode != 422 else {
            throw AuthError.invalidCredentials
        }
        guard (200..<300).contains(response.statusCode) else {
            throw AuthError.transport("Sign-in failed with HTTP \(response.statusCode)")
        }

        let tokens = try decodeTokens(from: data)
        try persist(tokens)
        return tokens
    }

    /// Forget the session. Deliberately does **not** touch the local store:
    /// signing out is not a request to delete the user's time records, and a
    /// queued mutation stays queued for whoever signs in next to the same
    /// workspace.
    public func signOut() throws {
        cached = nil
        try tokenStore.clear()
    }

    // MARK: - Authorization

    /// The header value for the next request, refreshing first if the token is
    /// known to be stale.
    ///
    /// Returns `nil` — rather than throwing — when there is no session at all.
    /// Callers that can proceed without auth (there are none on the wire, but
    /// the sync engine's scheduling logic asks) should not need a `do/catch` to
    /// find out.
    public func authorizationHeader() async throws -> String? {
        guard let tokens = try currentTokens() else { return nil }

        if tokens.isExpired() {
            let refreshed = try await refresh()
            return "Bearer \(refreshed.accessToken)"
        }
        return "Bearer \(tokens.accessToken)"
    }

    /// Exchange the refresh token for a new pair.
    ///
    /// Concurrent callers share one in-flight refresh: the server rotates the
    /// refresh token, so two simultaneous refreshes would leave one caller
    /// holding a token the server has already retired.
    @discardableResult
    public func refresh() async throws -> AuthTokens {
        if let inFlightRefresh {
            return try await inFlightRefresh.value
        }

        guard let tokens = try currentTokens() else {
            throw AuthError.notAuthenticated
        }

        let task = Task<AuthTokens, Error> { [baseURL, transport] in
            var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/auth/refresh"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try TimelyJSON.encode(
                RefreshRequest(refreshToken: tokens.refreshToken)
            )

            let (data, response) = try await transport.send(request)

            // A rejected *refresh* token is the one case that genuinely needs
            // the user back. Everything else is retryable.
            if response.statusCode == 401 || response.statusCode == 403 {
                throw AuthError.sessionExpired
            }
            guard (200..<300).contains(response.statusCode) else {
                throw AuthError.refreshFailed("HTTP \(response.statusCode)")
            }
            return try Self.decodeTokens(from: data, fallbackRefresh: tokens.refreshToken)
        }

        inFlightRefresh = task
        defer { inFlightRefresh = nil }

        do {
            let refreshed = try await task.value
            try persist(refreshed)
            return refreshed
        } catch let error as AuthError where error == .sessionExpired {
            // Drop the dead session so the UI can prompt once rather than on
            // every request. The local store is untouched.
            cached = nil
            try? tokenStore.clear()
            throw error
        }
    }

    // MARK: - Test / host seams

    /// Install tokens directly. For tests, and for a host app that obtained a
    /// session through some other supported flow.
    public func adopt(_ tokens: AuthTokens) throws {
        try persist(tokens)
    }

    private func persist(_ tokens: AuthTokens) throws {
        cached = tokens
        try tokenStore.save(tokens)
    }

    // MARK: - Decoding

    private func decodeTokens(from data: Data) throws -> AuthTokens {
        try Self.decodeTokens(from: data, fallbackRefresh: nil)
    }

    private static func decodeTokens(from data: Data, fallbackRefresh: String?) throws -> AuthTokens {
        let payload: TokenResponse
        do {
            payload = try TimelyJSON.decode(TokenResponse.self, from: data)
        } catch {
            throw AuthError.malformedResponse(String(describing: error))
        }

        // A refresh response may legitimately omit the refresh token when the
        // server is not rotating it. Reusing the old one is correct; treating
        // its absence as an error would break a conformant server.
        guard let refreshToken = payload.refreshToken ?? fallbackRefresh else {
            throw AuthError.malformedResponse("No refresh token in the response")
        }

        return AuthTokens(
            accessToken: payload.accessToken,
            refreshToken: refreshToken,
            expiresAt: payload.expiresAt
                ?? Date().addingTimeInterval(TimeInterval(payload.expiresIn ?? 3600)),
            userID: payload.userID,
            workspaceID: payload.workspaceID ?? payload.organizationID
        )
    }
}

extension AuthError: Equatable {
    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}

// MARK: - Wire shapes

private struct LoginRequest: Encodable {
    let email: String
    let password: String
}

private struct RefreshRequest: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

/// Tolerant of the several shapes the scaffold's auth endpoints use across
/// apps: `expires_at` or `expires_in`, `workspace_id` or `organization_id`,
/// and a refresh token that may be rotated or reused.
private struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
    let expiresIn: Int?
    let userID: UUID?
    let workspaceID: UUID?
    let organizationID: UUID?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case expiresIn = "expires_in"
        case userID = "user_id"
        case workspaceID = "workspace_id"
        case organizationID = "organization_id"
        case data
    }

    init(from decoder: any Decoder) throws {
        let outer = try decoder.container(keyedBy: CodingKeys.self)

        // The scaffold wraps some responses in `{"data": {...}}`.
        let c: KeyedDecodingContainer<CodingKeys>
        if outer.contains(.data), outer.contains(.accessToken) == false {
            c = try outer.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        } else {
            c = outer
        }

        accessToken = try c.decode(String.self, forKey: .accessToken)
        refreshToken = try c.decodeIfPresent(String.self, forKey: .refreshToken)
        expiresAt = try c.decodeIfPresent(Date.self, forKey: .expiresAt)
        expiresIn = try c.decodeIfPresent(Int.self, forKey: .expiresIn)
        userID = try c.decodeOptionalUUID(.userID)
        workspaceID = try c.decodeOptionalUUID(.workspaceID)
        organizationID = try c.decodeOptionalUUID(.organizationID)
    }
}
