package com.noizu.timely.data.auth

import android.util.Base64
import java.security.MessageDigest
import java.security.SecureRandom

/**
 * PKCE (RFC 7636) for the SSO code exchange.
 *
 * Note carefully WHOSE exchange this protects. It is **not** PKCE against the
 * identity provider -- this app never speaks to the IdP. Timely's server is the
 * OAuth client, holds the client secret, and completes the IdP leg itself. PKCE
 * here guards the exchange between this app and *our* server.
 *
 * That is not ceremony. The authorization code comes back over a redirect the
 * app does not exclusively own: a custom scheme is claimed by pattern, and even
 * an App Link is only as good as its verification state. Whoever receives the
 * redirect can redeem the code, and single-use plus a 60s TTL do not help --
 * whoever wins the race gets a full token pair. The verifier is the one thing an
 * interceptor does not have, because it never leaves this process.
 *
 * Which is why [Pkce.challenge] is what goes in the URL and [Pkce.verifier]
 * never does. The authorization URL is precisely what an interceptor can read.
 */
data class Pkce(
    val verifier: String,
    val challenge: String,
) {
    /** Always S256. The server refuses `plain`, and it should. */
    val method: String get() = METHOD

    companion object {
        const val METHOD = "S256"

        /** RFC 7636 section 4.1: 43..128 chars of the unreserved set. */
        private const val VERIFIER_BYTES = 64
        private const val UNRESERVED = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"

        private val random = SecureRandom()

        fun generate(): Pkce {
            val verifier = randomVerifier()
            return Pkce(verifier = verifier, challenge = challengeFor(verifier))
        }

        /**
         * Drawn from the unreserved set directly rather than base64url-encoding
         * random bytes. Both are legal; this one cannot accidentally emit a
         * padding character or a `+`/`/` if someone later swaps the encoder for
         * a non-URL-safe one, which is a real way to produce a verifier the
         * server rejects only sometimes.
         *
         * Rejection sampling on the byte, so the character distribution stays
         * uniform: `byte % 66` would over-weight the first 58 characters,
         * because 256 is not a multiple of 66.
         */
        fun randomVerifier(length: Int = VERIFIER_BYTES): String {
            require(length in 43..128) { "PKCE verifier must be 43..128 chars, got $length" }
            val out = StringBuilder(length)
            val buffer = ByteArray(1)
            val limit = 256 - (256 % UNRESERVED.length)
            while (out.length < length) {
                random.nextBytes(buffer)
                val value = buffer[0].toInt() and 0xFF
                if (value >= limit) continue
                out.append(UNRESERVED[value % UNRESERVED.length])
            }
            return out.toString()
        }

        /**
         * `BASE64URL-ENCODE(SHA256(ASCII(verifier)))`, unpadded.
         *
         * All three flags matter and each has been a real interop bug somewhere:
         * URL_SAFE (`-_` not `+/`), NO_PADDING (no trailing `=`), and NO_WRAP
         * (no newline every 76 chars, which `Base64.encodeToString` inserts by
         * default and which would be invisible in a log and fatal on the wire).
         */
        fun challengeFor(verifier: String): String {
            val digest = MessageDigest.getInstance("SHA-256")
                .digest(verifier.toByteArray(Charsets.US_ASCII))
            return Base64.encodeToString(
                digest,
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP,
            )
        }
    }
}
