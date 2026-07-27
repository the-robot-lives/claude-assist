package com.noizu.timely.core

import android.net.Uri
import com.noizu.timely.data.auth.Pkce
import com.noizu.timely.data.auth.SsoError
import com.noizu.timely.data.auth.SsoFlow
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * PKCE and the SSO redirect, verified against RFC 7636 and the documented
 * contract.
 *
 * The PKCE vector is the RFC's own Appendix B worked example, NOT a value
 * captured from our server. Testing only against what our server accepts proves
 * the two sides agree; it cannot prove they are both correct. If our server and
 * this client shared a bug -- a padded base64, a non-URL-safe alphabet -- a
 * round-trip test would be green and any third implementation would fail.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class SsoFlowTest {

    private val flow = SsoFlow()
    private val redirectUri = "https://timely.noizu.com/app/auth/callback"
    private val baseUrl = "https://timely.noizu.com/"

    // ------------------------------------------------------------- PKCE ----

    @Test
    fun `challenge matches RFC 7636 Appendix B`() {
        // RFC 7636 B.1/B.2, verbatim.
        val verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        val expected = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

        assertEquals(
            "S256 challenge diverges from the RFC's worked example. Suspect the " +
                "base64 flags: it must be URL_SAFE (-_ not +/), NO_PADDING (no " +
                "trailing =), and NO_WRAP (no newline every 76 chars).",
            expected,
            Pkce.challengeFor(verifier),
        )
    }

    @Test
    fun `generated verifiers satisfy the RFC character and length rules`() {
        val allowed = Regex("^[A-Za-z0-9\\-._~]+$")
        repeat(200) {
            val pkce = Pkce.generate()
            assertTrue(
                "verifier length ${pkce.verifier.length} outside RFC 7636's 43..128",
                pkce.verifier.length in 43..128,
            )
            assertTrue(
                "verifier contains a character outside the unreserved set: ${pkce.verifier}",
                allowed.matches(pkce.verifier),
            )
            // A padded or non-URL-safe challenge is the classic interop failure.
            assertFalse("challenge is padded", pkce.challenge.contains("="))
            assertFalse("challenge is not URL-safe", pkce.challenge.contains("+"))
            assertFalse("challenge is not URL-safe", pkce.challenge.contains("/"))
            assertFalse("challenge is wrapped", pkce.challenge.contains("\n"))
        }
    }

    @Test
    fun `each attempt mints a fresh verifier`() {
        // Reuse across attempts would let an interceptor who captured one
        // verifier redeem a later code.
        val seen = (1..100).map { Pkce.generate().verifier }.toSet()
        assertEquals(100, seen.size)
    }

    @Test
    fun `only S256 is offered`() {
        // `plain` sends the verifier itself as the challenge, which defeats the
        // entire mechanism. The server refuses it; so does this.
        assertEquals("S256", Pkce.generate().method)
    }

    // ------------------------------------------- the authorization URL ----

    @Test
    fun `the verifier NEVER appears in the authorization URL`() {
        // The single most important assertion in this file. The URL is exactly
        // what a redirect interceptor gets to read; the verifier is the one
        // thing it must not have.
        repeat(50) {
            val attempt = flow.begin(baseUrl, redirectUri)
            assertFalse(
                "PKCE verifier leaked into the authorization URL:\n  ${attempt.authorizationUrl}",
                attempt.authorizationUrl.contains(attempt.pkce.verifier),
            )
            assertTrue(
                "the challenge must be present",
                attempt.authorizationUrl.contains(Uri.encode(attempt.pkce.challenge)) ||
                    attempt.authorizationUrl.contains(attempt.pkce.challenge),
            )
        }
    }

    @Test
    fun `the authorization URL matches the documented contract`() {
        val attempt = flow.begin(baseUrl, redirectUri)
        val uri = Uri.parse(attempt.authorizationUrl)

        assertEquals("/auth/oidc", uri.path)
        assertEquals(redirectUri, uri.getQueryParameter("redirect_uri"))
        assertEquals("S256", uri.getQueryParameter("code_challenge_method"))
        assertEquals(attempt.pkce.challenge, uri.getQueryParameter("code_challenge"))
    }

    @Test
    fun `a social provider routes to auth colon provider`() {
        val attempt = flow.begin(baseUrl, redirectUri, provider = "google")
        assertEquals("/auth/google", Uri.parse(attempt.authorizationUrl).path)
    }

    @Test
    fun `the redirect_uri travels intact through encoding`() {
        // If this URL-encodes wrongly, the server sees a different string and
        // the EXACT-match allow-list rejects it with redirect_not_allowed --
        // which surfaces only at runtime.
        val attempt = flow.begin(baseUrl, redirectUri)
        assertEquals(
            redirectUri,
            Uri.parse(attempt.authorizationUrl).getQueryParameter("redirect_uri"),
        )
    }

    // ------------------------------------------------- the redirect back ----

    @Test
    fun `a code on the registered redirect is accepted`() {
        val result = flow.parseRedirect(Uri.parse("$redirectUri?code=abc123"), redirectUri)
        assertEquals(SsoFlow.Redirect.Success("abc123"), result)
    }

    @Test
    fun `every documented error code maps to actionable copy`() {
        val documented = listOf(
            "redirect_not_allowed", "invalid_code_challenge", "state_mismatch",
            "not_provisioned", "sso_unavailable", "sso_failed", "oidc_failed",
        )
        for (code in documented) {
            val result = flow.parseRedirect(Uri.parse("$redirectUri?error=$code"), redirectUri)
            val failed = result as? SsoFlow.Redirect.Failed
            assertNotNull("`$code` is documented but unmapped", failed)
            val error = failed!!.error
            assertTrue("`$code` has no title", error.title.isNotBlank())
            assertTrue("`$code` has no actionable detail", error.detail.isNotBlank())
            assertFalse(
                "`$code` surfaces the raw code to the user instead of a sentence",
                error.title.contains("_"),
            )
        }
    }

    @Test
    fun `not_provisioned and sso_unavailable give opposite advice`() {
        // The distinction that makes the flags worth carrying. Retrying an
        // unprovisioned account fails identically every time; retrying an
        // unavailable service is exactly right.
        assertFalse(SsoError.NOT_PROVISIONED.isRetryable)
        assertTrue(SsoError.NOT_PROVISIONED.suggestsPasswordFallback)

        assertTrue(SsoError.SSO_UNAVAILABLE.isRetryable)
        assertTrue(SsoError.SSO_UNAVAILABLE.suggestsPasswordFallback)
    }

    @Test
    fun `an unknown error code degrades readably instead of misleading`() {
        // New codes can ship without an app release. Mapping one we do not know
        // onto SSO_FAILED would give confident, possibly wrong advice.
        val result = flow.parseRedirect(
            Uri.parse("$redirectUri?error=some_future_code"),
            redirectUri,
        )
        val unknown = result as? SsoFlow.Redirect.Unrecognised
        assertNotNull("an unknown code must not be silently coerced to a known one", unknown)
        assertTrue(
            "the raw code should stay visible for support",
            unknown!!.error.detail.contains("some_future_code"),
        )
        assertTrue(unknown.error.suggestsPasswordFallback)
    }

    @Test
    fun `a callback with neither code nor error is a failure, not silence`() {
        // Doing nothing would leave the user on a sign-in screen that appears to
        // have forgotten them.
        val result = flow.parseRedirect(Uri.parse(redirectUri), redirectUri)
        assertTrue(result is SsoFlow.Redirect.Failed)
    }

    @Test
    fun `a deep link that is not our callback is ignored`() {
        for (other in listOf(
            "https://timely.noizu.com/app/somewhere-else?code=abc",
            "https://evil.example/app/auth/callback?code=abc",
            "https://timely.noizu.com.evil.example/app/auth/callback?code=abc",
        )) {
            assertEquals(
                "`$other` must not be treated as our SSO callback",
                SsoFlow.Redirect.NotSso,
                flow.parseRedirect(Uri.parse(other), redirectUri),
            )
        }
    }

    @Test
    fun `code_verifier is OMITTED rather than sent as null`() {
        // Presence-sensitivity, applied consistently: absent means "not
        // supplied", null means "supplied as nothing", and those are different
        // statements. The same rule that governs `end` and `locked_at`.
        val json = kotlinx.serialization.json.Json {
            explicitNulls = false; encodeDefaults = true; ignoreUnknownKeys = true
        }

        val withVerifier = json.encodeToString(
            com.noizu.timely.data.remote.dto.SsoExchangeRequestDto.serializer(),
            com.noizu.timely.data.remote.dto.SsoExchangeRequestDto("abc", "v-123"),
        )
        assertTrue(withVerifier.contains("\"code_verifier\":\"v-123\""))

        val without = json.encodeToString(
            com.noizu.timely.data.remote.dto.SsoExchangeRequestDto.serializer(),
            com.noizu.timely.data.remote.dto.SsoExchangeRequestDto("abc", null),
        )
        assertFalse(
            "an absent verifier must omit the key, not send null:\n  $without",
            without.contains("code_verifier"),
        )
        assertTrue(without.contains("\"code\":\"abc\""))
    }

    @Test
    fun `parsing a null intent uri is not an error`() {
        assertEquals(SsoFlow.Redirect.NotSso, flow.parseRedirect(null, redirectUri))
    }
}
