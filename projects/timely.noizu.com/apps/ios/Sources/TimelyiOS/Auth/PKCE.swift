import CryptoKit
import Foundation

/// A PKCE verifier/challenge pair (RFC 7636), S256 only.
///
/// **This is not PKCE against the identity provider.** The Timely backend is the
/// OAuth client and holds the client secret; this app never talks to the IdP.
/// PKCE guards *our* code exchange, and it is load-bearing for one specific
/// reason: a custom URL scheme is claimed by **pattern, not owned**. Any app on
/// the device may register `com.noizu.timely://` and receive the redirect. The
/// authorization code being single-use with a 60-second TTL does not help —
/// whoever redeems it first gets a full token pair.
///
/// The verifier is the one thing an interceptor does not have. It never leaves
/// this process except in the exchange body, over TLS, to our own server.
struct PKCEChallenge: Sendable, Hashable {

    /// 43–128 characters of `[A-Za-z0-9-._~]`. Held only for the life of one
    /// sign-in attempt.
    let verifier: String

    /// `BASE64URL(SHA256(verifier))`, unpadded.
    let challenge: String

    /// RFC 7636 §4.1 unreserved set.
    static let allowedCharacters = Array(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    /// A fresh pair. **Generate one per flow** — reusing a verifier across
    /// attempts hands a second chance to anyone who saw the first.
    static func generate(length: Int = 64) -> PKCEChallenge {
        let bounded = min(max(length, 43), 128)
        var generator = SystemRandomNumberGenerator()
        let verifier = String((0..<bounded).map { _ in
            allowedCharacters[Int.random(in: 0..<allowedCharacters.count, using: &generator)]
        })
        return PKCEChallenge(verifier: verifier)
    }

    init(verifier: String) {
        self.verifier = verifier
        self.challenge = Self.s256(verifier)
    }

    /// `BASE64URL-ENCODE(SHA256(ASCII(verifier)))` with padding stripped, per
    /// RFC 7636 §4.2.
    static func s256(_ verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    var isValid: Bool {
        (43...128).contains(verifier.count)
            && verifier.allSatisfy { Self.allowedCharacters.contains($0) }
    }
}

extension Data {
    /// Base64url without padding (RFC 4648 §5).
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

/// The error codes the backend returns on the custom scheme.
///
/// They arrive as `?error=<code>` on the **same** redirect the success case
/// uses. That is deliberate: an error rendered as a web page would leave
/// `ASWebAuthenticationSession` sitting open with nothing to return to — the
/// same hang the native redirect was added to fix, reached a different way.
enum SSOErrorCode: String, Sendable, Hashable, CaseIterable {
    case redirectNotAllowed = "redirect_not_allowed"
    case invalidCodeChallenge = "invalid_code_challenge"
    case stateMismatch = "state_mismatch"
    case notProvisioned = "not_provisioned"
    case ssoUnavailable = "sso_unavailable"
    case ssoFailed = "sso_failed"
    case oidcFailed = "oidc_failed"

    /// What to show the user. Written to say what happened and what they can do,
    /// rather than echoing a code they cannot act on.
    var message: String {
        switch self {
        case .redirectNotAllowed:
            "This app's sign-in address is not registered with the server. "
                + "This is a configuration problem, not something you can fix — "
                + "please report it."
        case .invalidCodeChallenge:
            "Sign-in could not be secured properly and was stopped. Please try again."
        case .stateMismatch:
            "Sign-in took too long or was interrupted, so it was stopped for safety. "
                + "Please try again."
        case .notProvisioned:
            "Your account is not set up for Timely yet. Ask your workspace "
                + "administrator to add you."
        case .ssoUnavailable:
            "Single sign-on is not available for this workspace. Try signing in "
                + "with your email and password."
        case .ssoFailed:
            "Sign-in did not complete. Please try again."
        case .oidcFailed:
            "Your organization's sign-in service could not complete the request. "
                + "Please try again, or contact your administrator if it continues."
        }
    }

    /// True when retrying could plausibly work. A configuration or provisioning
    /// problem will fail identically every time, and inviting a retry there
    /// just wastes the user's effort.
    var isRetryable: Bool {
        switch self {
        case .stateMismatch, .ssoFailed, .oidcFailed, .invalidCodeChallenge:
            true
        case .redirectNotAllowed, .notProvisioned, .ssoUnavailable:
            false
        }
    }

    /// Whether email/password is worth offering instead.
    var suggestsPasswordFallback: Bool {
        self == .ssoUnavailable || self == .notProvisioned
    }
}
