import Foundation
import Testing
import TimelyKit
@testable import TimelyiOS

@Suite("OIDC sign-in")
@MainActor
struct OIDCAuthenticatorTests {

    private let baseURL = URL(string: "https://timely.example.com")!
    /// Defaults on purpose — the scheme and redirect are what ship, and this
    /// suite pins the literal the backend allow-list has to match.
    private let configuration = OIDCConfiguration()

    // MARK: - Callback parsing

    @Test("The authorization code is read from the callback")
    func extractsCode() throws {
        let callback = URL(
            string: "com.noizu.timely://auth/callback?code=abc123&provider=oidc"
        )!

        #expect(try OIDCAuthenticator.authorizationCode(from: callback) == "abc123")
    }

    @Test("Every documented backend error code maps to something actionable",
          arguments: SSOErrorCode.allCases)
    func mapsEveryDocumentedErrorCode(code: SSOErrorCode) throws {
        let callback = URL(string: "com.noizu.timely://auth/callback?error=\(code.rawValue)")!

        #expect(throws: OIDCError.sso(code)) {
            try OIDCAuthenticator.authorizationCode(from: callback)
        }
        // The user gets a sentence, not a code they cannot act on.
        #expect(code.message.count > 20)
        #expect(code.message.contains(code.rawValue) == false)
    }

    @Test("All seven documented codes are covered")
    func allSevenCodesPresent() {
        #expect(SSOErrorCode.allCases.count == 7)
        let raw = Set(SSOErrorCode.allCases.map(\.rawValue))
        #expect(raw == [
            "redirect_not_allowed", "invalid_code_challenge", "state_mismatch",
            "not_provisioned", "sso_unavailable", "sso_failed", "oidc_failed"
        ])
    }

    @Test("A permanent failure points at the password form instead of a retry")
    func permanentFailuresSuggestFallback() {
        #expect(OIDCError.sso(.notProvisioned).suggestsPasswordFallback)
        #expect(OIDCError.sso(.ssoUnavailable).suggestsPasswordFallback)
        #expect(OIDCError.sso(.stateMismatch).suggestsPasswordFallback == false)

        // A configuration fault will fail identically on retry.
        #expect(OIDCError.sso(.redirectNotAllowed).isRetryable == false)
        #expect(OIDCError.sso(.stateMismatch).isRetryable)
    }

    @Test("An unknown error code degrades instead of reading as a missing code")
    func unknownErrorCodeDegrades() {
        let callback = URL(
            string: "com.noizu.timely://auth/callback?error=brand_new_code"
                + "&error_description=Something%20new"
        )!

        #expect(throws: OIDCError.unrecognized(code: "brand_new_code", description: "Something new")) {
            try OIDCAuthenticator.authorizationCode(from: callback)
        }
    }

    @Test("A callback with no code and no error is a missing code")
    func missingCode() {
        let callback = URL(string: "com.noizu.timely://auth/callback")!

        #expect(throws: OIDCError.missingCode) {
            try OIDCAuthenticator.authorizationCode(from: callback)
        }
    }

    @Test("An empty code is not a code")
    func emptyCode() {
        let callback = URL(string: "com.noizu.timely://auth/callback?code=")!

        #expect(throws: OIDCError.missingCode) {
            try OIDCAuthenticator.authorizationCode(from: callback)
        }
    }

    // MARK: - Authorization URL

    /// The literal the backend's `SSO_REDIRECT_ALLOWLIST` must contain.
    ///
    /// Pinned as a test because the allow-list is **exact-match**: any drift
    /// here — a trailing slash, a different host segment — fails the flow with
    /// `redirect_not_allowed` and no other signal.
    @Test("The redirect URI is exactly the allow-listed literal")
    func redirectURIIsExact() {
        #expect(configuration.redirectURI == "com.noizu.timely://auth/callback")
    }

    @Test("The authorization URL carries the native redirect and the S256 challenge")
    func authorizationURLCarriesRedirectAndChallenge() throws {
        let pkce = PKCEChallenge.generate()
        let url = configuration.authorizationURL(baseURL: baseURL, codeChallenge: pkce.challenge)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = components.queryItems ?? []

        #expect(components.path == "/auth/oidc")
        #expect(items.contains {
            $0.name == "redirect_uri" && $0.value == "com.noizu.timely://auth/callback"
        })
        #expect(items.contains { $0.name == "code_challenge" && $0.value == pkce.challenge })
        #expect(items.contains { $0.name == "code_challenge_method" && $0.value == "S256" })
        // `plain` is refused server-side and would defeat the point anyway.
        #expect(items.contains { $0.value == "plain" } == false)
        // The verifier is the secret; it must never appear in the URL that an
        // interceptor of the custom scheme could read.
        #expect(url.absoluteString.contains(pkce.verifier) == false)
    }

    @Test("PKCE omitted entirely when no challenge is supplied")
    func authorizationURLWithoutPKCE() throws {
        let url = configuration.authorizationURL(baseURL: baseURL, codeChallenge: nil)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        #expect(items.contains { $0.name == "code_challenge" } == false)
        #expect(items.contains { $0.name == "code_challenge_method" } == false)
    }

    // MARK: - Exchange decoding

    @Test("A single-organization exchange resolves the workspace")
    func singleOrganizationResolves() throws {
        let body = """
        {
          "access_token": "at",
          "refresh_token": "rt",
          "user": { "id": "0192f7a1-0000-7000-8000-000000000002" },
          "organizations": [
            { "id": "0192f7a1-0000-7000-8000-00000000c0de", "name": "Noizu Labs" }
          ]
        }
        """

        let result = try OIDCAuthenticator.result(
            fromExchange: Data(body.utf8), now: Fixture.noon
        )

        #expect(result.tokens.accessToken == "at")
        #expect(result.tokens.refreshToken == "rt")
        #expect(result.tokens.workspaceID == Fixture.workspaceID)
        #expect(result.tokens.userID == Fixture.userID)
        #expect(result.needsWorkspaceChoice == false)
    }

    @Test("Several organizations require a choice rather than a guess")
    func multipleOrganizationsRequireAChoice() throws {
        let body = """
        {
          "access_token": "at",
          "refresh_token": "rt",
          "organizations": [
            { "id": "0192f7a1-0000-7000-8000-00000000c0de", "name": "One" },
            { "id": "0192f7a1-0000-7000-8000-00000000c0df", "name": "Two" }
          ]
        }
        """

        let result = try OIDCAuthenticator.result(
            fromExchange: Data(body.utf8), now: Fixture.noon
        )

        #expect(result.tokens.workspaceID == nil)
        #expect(result.organizations.count == 2)
        #expect(result.needsWorkspaceChoice)
    }

    @Test("An expiry is assumed when the server omits one")
    func assumesExpiry() throws {
        let body = #"{"access_token":"at","refresh_token":"rt","organizations":[]}"#

        let result = try OIDCAuthenticator.result(
            fromExchange: Data(body.utf8), now: Fixture.noon
        )

        #expect(
            result.tokens.expiresAt
                == Fixture.noon.addingTimeInterval(OIDCAuthenticator.assumedAccessTokenLifetime)
        )
    }

    @Test("A response without tokens is malformed, not empty")
    func malformedResponse() {
        let body = #"{"error":"Invalid or expired SSO code"}"#

        #expect(throws: OIDCError.self) {
            try OIDCAuthenticator.result(fromExchange: Data(body.utf8), now: Fixture.noon)
        }
    }

    // MARK: - End-to-end, with a stub browser

    @Test("The exchange sends the verifier, and the verifier alone proves the flow")
    func exchangeSendsVerifier() async throws {
        let transport = StubTransport()
        transport.script([
            .json(200, """
            {
              "access_token": "at", "refresh_token": "rt",
              "user": { "id": "0192f7a1-0000-7000-8000-000000000002" },
              "organizations": [
                { "id": "0192f7a1-0000-7000-8000-00000000c0de", "name": "Noizu Labs" }
              ]
            }
            """)
        ])

        let pkce = PKCEChallenge.generate()
        let authenticator = OIDCAuthenticator(
            baseURL: baseURL,
            configuration: configuration,
            transport: transport,
            webAuth: StubWebAuth(
                result: .success(URL(string: "com.noizu.timely://auth/callback?code=c")!)
            )
        )

        _ = try await authenticator.exchange(
            code: "c", verifier: pkce.verifier, now: Fixture.noon
        )

        let body = try #require(transport.bodies.first)
        let json = try #require(
            try JSONSerialization.jsonObject(with: body) as? [String: Any]
        )
        #expect(json["code"] as? String == "c")
        #expect(json["code_verifier"] as? String == pkce.verifier)
    }

    @Test("Without PKCE the verifier key is omitted, not sent as null")
    func exchangeOmitsVerifierWhenAbsent() async throws {
        let transport = StubTransport()
        transport.script([
            .json(200, #"{"access_token":"at","refresh_token":"rt","organizations":[]}"#)
        ])

        let authenticator = OIDCAuthenticator(
            baseURL: baseURL,
            configuration: configuration,
            transport: transport,
            webAuth: StubWebAuth(
                result: .success(URL(string: "com.noizu.timely://auth/callback?code=c")!)
            )
        )

        _ = try await authenticator.exchange(code: "c", verifier: nil, now: Fixture.noon)

        let body = try #require(transport.bodies.first)
        let json = try #require(
            try JSONSerialization.jsonObject(with: body) as? [String: Any]
        )
        #expect(json["code_verifier"] == nil)
        #expect(json.keys.contains("code_verifier") == false)
    }

    @Test("A completed flow yields tokens")
    func fullFlow() async throws {
        let transport = StubTransport()
        transport.script([
            .json(200, """
            {
              "access_token": "at",
              "refresh_token": "rt",
              "user": { "id": "0192f7a1-0000-7000-8000-000000000002" },
              "organizations": [
                { "id": "0192f7a1-0000-7000-8000-00000000c0de", "name": "Noizu Labs" }
              ]
            }
            """)
        ])

        let authenticator = OIDCAuthenticator(
            baseURL: baseURL,
            configuration: configuration,
            transport: transport,
            webAuth: StubWebAuth(
                result: .success(URL(string: "com.noizu.timely://auth/callback?code=sso-code")!)
            )
        )

        let result = try await authenticator.signIn(now: Fixture.noon)

        #expect(result.tokens.workspaceID == Fixture.workspaceID)
        #expect(transport.requestCount == 1)
        #expect(
            transport.requests.first?.url?.path == "/api/v1/auth/sso/exchange"
        )
    }

    @Test("A cancelled browser session is a cancellation, not a failure")
    func cancellationPropagates() async {
        let authenticator = OIDCAuthenticator(
            baseURL: baseURL,
            configuration: configuration,
            transport: StubTransport(),
            webAuth: StubWebAuth(result: .failure(OIDCError.cancelled))
        )

        await #expect(throws: OIDCError.cancelled) {
            try await authenticator.signIn(now: Fixture.noon)
        }
    }

    @Test("A rejected exchange reports the status rather than a decode error")
    func exchangeFailure() async {
        let transport = StubTransport()
        transport.script([.json(401, #"{"error":"Invalid or expired SSO code"}"#)])

        let authenticator = OIDCAuthenticator(
            baseURL: baseURL,
            configuration: configuration,
            transport: transport,
            webAuth: StubWebAuth(
                result: .success(URL(string: "com.noizu.timely://auth/callback?code=stale")!)
            )
        )

        await #expect(throws: OIDCError.exchangeFailed("HTTP 401")) {
            try await authenticator.signIn(now: Fixture.noon)
        }
    }
}

/// A browser that returns a scripted answer.
@MainActor
private struct StubWebAuth: WebAuthenticating {
    let result: Result<URL, Error>

    func authenticate(
        url: URL,
        callbackScheme: String,
        prefersEphemeralSession: Bool
    ) async throws -> URL {
        try result.get()
    }
}
