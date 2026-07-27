import CryptoKit
import Foundation
import Testing
@testable import TimelyiOS

/// PKCE, checked against RFC 7636's own worked example.
///
/// The verifier is the only thing an interceptor of the custom URL scheme does
/// not have, so a wrong challenge derivation is not a cosmetic bug — it silently
/// removes the protection while the flow keeps working.
@Suite("PKCE")
struct PKCETests {

    /// RFC 7636 Appendix B. If this fails, the derivation is wrong regardless of
    /// what the server happens to accept.
    @Test("S256 matches the RFC's worked example")
    func rfcWorkedExample() {
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let expected = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

        #expect(PKCEChallenge.s256(verifier) == expected)
        #expect(PKCEChallenge(verifier: verifier).challenge == expected)
    }

    @Test("The challenge is unpadded base64url, never standard base64")
    func challengeIsBase64URL() {
        for _ in 0..<50 {
            let challenge = PKCEChallenge.generate().challenge
            #expect(challenge.contains("=") == false)
            #expect(challenge.contains("+") == false)
            #expect(challenge.contains("/") == false)
            // SHA-256 is 32 bytes → 43 base64url characters unpadded.
            #expect(challenge.count == 43)
        }
    }

    @Test("Generated verifiers satisfy the RFC's length and alphabet")
    func verifierIsWellFormed() {
        for _ in 0..<100 {
            let pkce = PKCEChallenge.generate()
            #expect(pkce.isValid)
            #expect((43...128).contains(pkce.verifier.count))
            #expect(pkce.verifier.allSatisfy(PKCEChallenge.allowedCharacters.contains))
        }
    }

    @Test("Requested lengths are clamped into the legal range", arguments: [
        (1, 43), (43, 43), (64, 64), (128, 128), (500, 128)
    ])
    func lengthIsClamped(requested: Int, expected: Int) {
        #expect(PKCEChallenge.generate(length: requested).verifier.count == expected)
    }

    /// A reused verifier hands a second chance to anyone who saw the first, and
    /// a custom URL scheme is claimed by pattern rather than owned — so someone
    /// may well have seen it.
    @Test("Every flow gets a fresh verifier")
    func verifiersAreUnique() {
        let verifiers = Set((0..<200).map { _ in PKCEChallenge.generate().verifier })
        #expect(verifiers.count == 200)
    }

    @Test("The challenge is a one-way function of the verifier")
    func challengeIsDeterministicButNotReversible() {
        let a = PKCEChallenge.generate()
        let b = PKCEChallenge(verifier: a.verifier)

        // Same verifier, same challenge — the server can re-derive it.
        #expect(a.challenge == b.challenge)
        // …and the challenge does not leak the verifier.
        #expect(a.challenge.contains(a.verifier) == false)
        #expect(a.verifier.contains(a.challenge) == false)
    }

    @Test("A malformed verifier is rejected by the validity check", arguments: [
        "",
        "too-short",
        String(repeating: "a", count: 42),
        "has spaces in it aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "has+plus+signs+aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    ])
    func rejectsMalformedVerifiers(verifier: String) {
        #expect(PKCEChallenge(verifier: verifier).isValid == false)
    }

    @Test("base64url encoding drops padding and swaps the URL-unsafe pair")
    func base64URLEncoding() {
        // 0xFB 0xFF encodes to "+/8=" in standard base64.
        let data = Data([0xFB, 0xFF])
        #expect(data.base64EncodedString() == "+/8=")
        #expect(data.base64URLEncodedString() == "-_8")
    }
}
