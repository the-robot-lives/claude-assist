import Foundation

/// Where this build points and how it signs in.
///
/// Read from the bundle rather than compiled in, so a TestFlight build and a
/// local build against a port-forwarded backend are the same binary with a
/// different `Info.plist`.
struct AppConfiguration: Sendable, Hashable {
    var baseURL: URL
    var oidc: OIDCConfiguration?
    var appVersion: String
    var appBuild: String

    var versionDescription: String { "\(appVersion) (\(appBuild))" }

    static let fallbackBaseURL = URL(string: "https://timely.noizu.com")!

    static func fromBundle(_ bundle: Bundle = .main) -> AppConfiguration {
        let baseURL = (bundle.object(forInfoDictionaryKey: "TimelyAPIBaseURL") as? String)
            .flatMap(URL.init(string:)) ?? fallbackBaseURL

        let oidcEnabled = bundle.object(forInfoDictionaryKey: "TimelyOIDCEnabled") as? Bool ?? false
        let scheme = bundle.object(forInfoDictionaryKey: "TimelyOIDCCallbackScheme") as? String

        return AppConfiguration(
            baseURL: baseURL,
            oidc: oidcEnabled ? OIDCConfiguration(callbackScheme: scheme ?? "timely") : nil,
            appVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                ?? "0.0.0",
            appBuild: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        )
    }
}

/// Single sign-on against Authentik, brokered by the Timely backend.
///
/// The app never talks to Authentik directly: it opens the backend's
/// `/auth/oidc` entry point, which performs the OIDC dance and hands back a
/// short-lived SSO code. That keeps the OIDC client secret on the server, where
/// a public mobile client cannot leak it.
struct OIDCConfiguration: Sendable, Hashable {
    /// Backend path that starts the flow.
    var initPath: String = "auth/oidc"

    /// Backend path that trades the SSO code for a token pair.
    var exchangePath: String = "api/v1/auth/sso/exchange"

    /// The custom URL scheme `ASWebAuthenticationSession` completes on. Must
    /// also appear in `CFBundleURLTypes`.
    ///
    /// Reverse-DNS rather than a bare word: a short scheme like `timely` is
    /// trivially squatted by another app, and while the scheme is claimed by
    /// pattern rather than owned either way, reverse-DNS at least makes a
    /// collision deliberate rather than accidental.
    var callbackScheme: String = "com.noizu.timely"

    var callbackHost: String = "auth"
    var callbackPath: String = "/callback"

    /// The literal the backend allow-list must contain.
    ///
    /// The server matches this **exactly**, not by prefix — a prefix check is
    /// satisfied by `com.noizu.timely://auth/callback@evil.example`, which is a
    /// different destination wearing the right beginning.
    var redirectURI: String {
        "\(callbackScheme)://\(callbackHost)\(callbackPath)"
    }

    /// `GET /auth/oidc?redirect_uri=…&code_challenge=…&code_challenge_method=S256`
    func authorizationURL(baseURL: URL, codeChallenge: String? = nil) -> URL {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(initPath),
            resolvingAgainstBaseURL: false
        )
        var items = [URLQueryItem(name: "redirect_uri", value: redirectURI)]
        if let codeChallenge {
            items.append(URLQueryItem(name: "code_challenge", value: codeChallenge))
            // S256 only. The server refuses `plain`, and correctly: `plain`
            // sends the secret in the same redirect an interceptor is reading.
            items.append(URLQueryItem(name: "code_challenge_method", value: "S256"))
        }
        components?.queryItems = items
        return components?.url ?? baseURL.appendingPathComponent(initPath)
    }
}
