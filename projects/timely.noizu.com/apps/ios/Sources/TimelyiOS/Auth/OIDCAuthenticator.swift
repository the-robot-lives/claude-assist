import Foundation
import TimelyKit

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

/// Presents a hosted sign-in page and reports the callback URL it lands on.
///
/// A protocol so the whole OIDC flow — URL construction, callback parsing,
/// token exchange, error mapping — is testable without a browser. The only
/// untestable part left is `ASWebAuthenticationSession` itself.
@MainActor
protocol WebAuthenticating {
    func authenticate(
        url: URL,
        callbackScheme: String,
        prefersEphemeralSession: Bool
    ) async throws -> URL
}

enum OIDCError: Error, Equatable, CustomStringConvertible {
    case cancelled
    case notConfigured

    /// One of the backend's documented `?error=` codes.
    case sso(SSOErrorCode)

    /// An error code this build does not recognize. Additive change rules mean
    /// a new code can ship without a client release, so this must not read as a
    /// crash or a generic failure.
    case unrecognized(code: String, description: String?)

    case missingCode
    case exchangeFailed(String)
    case malformedResponse(String)
    case unsupportedPlatform

    /// The browser session itself failed to run — distinct from the backend
    /// declining the request, and not one of the documented `?error=` codes.
    case sessionFailed(String)

    var description: String {
        switch self {
        case .cancelled:
            "Sign-in was cancelled."
        case .notConfigured:
            "Single sign-on is not configured for this build."
        case .sso(let code):
            code.message
        case .unrecognized(let code, let description):
            description ?? "Sign-in did not complete (\(code)). Please try again."
        case .missingCode:
            "Sign-in finished without returning an authorization code."
        case .exchangeFailed(let message):
            "Could not complete sign-in: \(message)"
        case .malformedResponse(let message):
            "Unexpected response from the server: \(message)"
        case .unsupportedPlatform:
            "Single sign-on is not available on this platform."
        case .sessionFailed(let message):
            "The sign-in page could not be opened: \(message)"
        }
    }

    var isCancellation: Bool { self == .cancelled }

    /// Whether to offer email/password instead of a retry.
    var suggestsPasswordFallback: Bool {
        if case .sso(let code) = self { return code.suggestsPasswordFallback }
        return false
    }

    var isRetryable: Bool {
        switch self {
        case .sso(let code): code.isRetryable
        case .cancelled, .notConfigured, .unsupportedPlatform: false
        default: true
        }
    }
}

/// The OIDC half of sign-in.
///
/// Deliberately produces the same `AuthTokens` that `AuthClient.signIn` does and
/// hands them to `AuthClient.adopt(_:)`, so from the rest of the app's point of
/// view there is exactly one session type and one refresh path. Nothing
/// downstream branches on how the user signed in.
@MainActor
struct OIDCAuthenticator {
    let baseURL: URL
    let configuration: OIDCConfiguration
    let transport: any HTTPTransporting
    let webAuth: any WebAuthenticating

    /// Access-token lifetime the backend documents. Used only when the exchange
    /// response omits an explicit expiry, which the current backend does.
    static let assumedAccessTokenLifetime: TimeInterval = 3600

    /// A completed exchange.
    ///
    /// The organizations come back with the tokens because a user in more than
    /// one workspace has to choose, and choosing for them binds their records
    /// to the wrong tenant.
    struct SignInResult: Sendable {
        var tokens: AuthTokens
        var organizations: [Organization]

        var needsWorkspaceChoice: Bool {
            tokens.workspaceID == nil && organizations.count > 1
        }
    }

    func signIn(now: Date = Date()) async throws -> SignInResult {
        // A fresh verifier per flow. Never logged, never persisted, discarded
        // when this function returns.
        let pkce = PKCEChallenge.generate()

        let callback = try await webAuth.authenticate(
            url: configuration.authorizationURL(
                baseURL: baseURL, codeChallenge: pkce.challenge
            ),
            callbackScheme: configuration.callbackScheme,
            // Not ephemeral: reusing the system session is what makes SSO feel
            // like SSO. An ephemeral session forces a full Authentik login every
            // time even when the user just authenticated in Safari. The signed
            // session carrying state/nonce/PKCE round-trips either way —
            // "ephemeral" means "not shared with Safari", not "no cookies".
            prefersEphemeralSession: false
        )

        let code = try Self.authorizationCode(from: callback)
        return try await exchange(code: code, verifier: pkce.verifier, now: now)
    }

    /// Pull the SSO code out of the callback, or surface the backend's error.
    ///
    /// Errors arrive on the **same** custom scheme as the success case, so this
    /// is the only place that learns a flow failed. Every documented code maps
    /// to something a person can act on; an unknown one degrades rather than
    /// being reported as a missing code.
    static func authorizationCode(from callback: URL) throws -> String {
        guard let components = URLComponents(url: callback, resolvingAgainstBaseURL: false) else {
            throw OIDCError.missingCode
        }
        let items = components.queryItems ?? []

        if let raw = items.first(where: { $0.name == "error" })?.value, !raw.isEmpty {
            let description = items.first(where: { $0.name == "error_description" })?.value
            if let known = SSOErrorCode(rawValue: raw) {
                throw OIDCError.sso(known)
            }
            throw OIDCError.unrecognized(code: raw, description: description)
        }
        guard let code = items.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
            throw OIDCError.missingCode
        }
        return code
    }

    /// `POST /api/v1/auth/sso/exchange` with `{"code": …, "code_verifier": …}`.
    func exchange(
        code: String,
        verifier: String? = nil,
        now: Date = Date()
    ) async throws -> SignInResult {
        var request = URLRequest(url: baseURL.appendingPathComponent(configuration.exchangePath))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try TimelyJSON.encode(
            ExchangeRequest(code: code, codeVerifier: verifier)
        )

        let (data, response) = try await transport.send(request)
        guard (200..<300).contains(response.statusCode) else {
            throw OIDCError.exchangeFailed("HTTP \(response.statusCode)")
        }

        return try Self.result(fromExchange: data, now: now)
    }

    static func result(fromExchange data: Data, now: Date = Date()) throws -> SignInResult {
        let payload: ExchangeResponse
        do {
            payload = try TimelyJSON.decode(ExchangeResponse.self, from: data)
        } catch {
            throw OIDCError.malformedResponse(String(describing: error))
        }

        let tokens = AuthTokens(
            accessToken: payload.accessToken,
            refreshToken: payload.refreshToken,
            expiresAt: payload.expiresAt
                ?? now.addingTimeInterval(assumedAccessTokenLifetime),
            userID: payload.userID,
            // The exchange response lists the user's organizations rather than
            // naming a workspace. A single-org user resolves unambiguously; a
            // multi-org user needs a picker, which the session view model
            // surfaces rather than guessing.
            workspaceID: payload.organizations.count == 1 ? payload.organizations.first?.id : nil
        )

        return SignInResult(tokens: tokens, organizations: payload.organizations)
    }

    // MARK: - Wire shapes

    private struct ExchangeRequest: Encodable {
        let code: String

        /// Omitted entirely when absent — PKCE is optional server-side, and
        /// sending an explicit null would be a claim rather than an omission.
        let codeVerifier: String?

        enum CodingKeys: String, CodingKey {
            case code
            case codeVerifier = "code_verifier"
        }

        func encode(to encoder: any Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(code, forKey: .code)
            try c.encodeIfPresent(codeVerifier, forKey: .codeVerifier)
        }
    }

    struct Organization: Decodable, Sendable, Hashable, Identifiable {
        let id: UUID
        let name: String?

        enum CodingKeys: String, CodingKey { case id, name, slug, title }

        init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decodeUUIDValue(.id)
            name = try c.decodeIfPresent(String.self, forKey: .name)
                ?? c.decodeIfPresent(String.self, forKey: .title)
                ?? c.decodeIfPresent(String.self, forKey: .slug)
        }
    }

    struct ExchangeResponse: Decodable, Sendable {
        let accessToken: String
        let refreshToken: String
        let expiresAt: Date?
        let userID: UUID?
        let organizations: [Organization]

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresAt = "expires_at"
            case user
            case organizations
        }

        private struct User: Decodable { let id: UUID? }

        init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            accessToken = try c.decode(String.self, forKey: .accessToken)
            refreshToken = try c.decode(String.self, forKey: .refreshToken)
            expiresAt = try c.decodeIfPresent(Date.self, forKey: .expiresAt)
            userID = try c.decodeIfPresent(User.self, forKey: .user)?.id
            organizations = try c.decodeIfPresent([Organization].self, forKey: .organizations) ?? []
        }
    }
}

private extension KeyedDecodingContainer {
    /// The exchange response is not part of `timely-api.yaml`, so it does not
    /// get TimelyKit's contract-aware UUID helpers.
    func decodeUUIDValue(_ key: Key) throws -> UUID {
        let text = try decode(String.self, forKey: key)
        guard let value = UUID(uuidString: text) else {
            throw DecodingError.dataCorruptedError(
                forKey: key, in: self, debugDescription: "Not a UUID: \(text)"
            )
        }
        return value
    }
}

// MARK: - The real presenter

#if canImport(AuthenticationServices) && os(iOS)

/// `ASWebAuthenticationSession`, wrapped so the flow above never imports UIKit.
@MainActor
final class WebAuthenticationPresenter: NSObject, WebAuthenticating {

    /// Held for the lifetime of the call; releasing it cancels the session.
    private var session: ASWebAuthenticationSession?

    func authenticate(
        url: URL,
        callbackScheme: String,
        prefersEphemeralSession: Bool
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error {
                    let code = (error as? ASWebAuthenticationSessionError)?.code
                    continuation.resume(
                        throwing: code == .canceledLogin
                            ? OIDCError.cancelled
                            : OIDCError.sessionFailed(error.localizedDescription)
                    )
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: OIDCError.missingCode)
                    return
                }
                continuation.resume(returning: callbackURL)
            }

            session.prefersEphemeralWebBrowserSession = prefersEphemeralSession
            session.presentationContextProvider = self
            self.session = session

            guard session.start() else {
                continuation.resume(throwing: OIDCError.sessionFailed("the session would not start"))
                return
            }
        }
    }
}

extension WebAuthenticationPresenter: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }

            return scene?.keyWindow
                ?? scene?.windows.first
                ?? ASPresentationAnchor()
        }
    }
}

#else

/// Stand-in for non-iOS builds, so the package still type-checks elsewhere.
@MainActor
final class WebAuthenticationPresenter: WebAuthenticating {
    func authenticate(
        url: URL,
        callbackScheme: String,
        prefersEphemeralSession: Bool
    ) async throws -> URL {
        throw OIDCError.unsupportedPlatform
    }
}

#endif
