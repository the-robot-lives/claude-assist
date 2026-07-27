package com.noizu.timely.core

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import com.noizu.timely.BuildConfig
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The SSO redirect URI, pinned in all three places that must agree.
 *
 * This test exists because they silently disagreed. `BuildConfig` held AppAuth's
 * default `com.noizu.timely:/oauth2redirect` while the deployed
 * `SSO_REDIRECT_ALLOWLIST` held an App Link -- so the value the app SENT was on
 * neither allow-list entry, and the flow would have failed at runtime with
 * `redirect_not_allowed` and no other signal. Nothing in the build caught it,
 * because a redirect URI is a string in one file and an intent filter in
 * another, and nothing tied them together.
 *
 * The allow-list is EXACT-MATCH, deliberately: prefix matching on
 * `com.noizu.timely://` would be satisfied by
 * `com.noizu.timely://auth/callback@evil.example`. Exact matching means a
 * one-character difference is a total failure rather than a partial one, which
 * is the right trade -- but it also means this string cannot be approximately
 * right.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class RedirectUriTest {

    @Test
    fun `BuildConfig carries the exact allow-listed literal`() {
        // If this fails, either the app changed or ops' SSO_REDIRECT_ALLOWLIST
        // did. Do not "fix" it by editing this string alone -- the allow-list,
        // the manifest intent filter, and BuildConfig all have to move together
        // or the flow breaks in a way only a real sign-in attempt reveals.
        assertEquals(ALLOW_LISTED_REDIRECT, BuildConfig.OIDC_REDIRECT_URI)
    }

    @Test
    fun `the app is actually registered to receive what it sends`() {
        // The half that a literal-only assertion misses: BuildConfig could hold
        // the right string while the manifest registers a different one, and the
        // browser would then have nowhere to hand the redirect back to.
        val redirect = Uri.parse(BuildConfig.OIDC_REDIRECT_URI)
        val intent = Intent(Intent.ACTION_VIEW, redirect).apply {
            addCategory(Intent.CATEGORY_DEFAULT)
            addCategory(Intent.CATEGORY_BROWSABLE)
        }

        val context = ApplicationProvider.getApplicationContext<Context>()
        val handlers = context.packageManager.queryIntentActivities(intent, 0)

        assertTrue(
            "no activity in this app is registered for ${BuildConfig.OIDC_REDIRECT_URI}. " +
                "The manifest intent filter and BuildConfig have drifted apart: the " +
                "app would open the browser and never get the callback.",
            handlers.any { it.activityInfo?.packageName == context.packageName },
        )
    }

    @Test
    fun `the redirect is an https App Link, not a custom scheme`() {
        // A custom scheme is claimed by pattern -- any installed app may
        // register the same one and receive the redirect. An App Link is
        // ownership-verified against assetlinks.json, so the redirect cannot be
        // intercepted and PKCE is defence in depth rather than the only defence.
        //
        // If someone reverts to a custom scheme, that is a security decision and
        // should be an explicit one, not a quiet edit.
        val redirect = Uri.parse(BuildConfig.OIDC_REDIRECT_URI)
        assertEquals("https", redirect.scheme)
        assertEquals("timely.noizu.com", redirect.host)
        assertEquals("/app/auth/callback", redirect.path)
    }

    @Test
    fun `the redirect has no query or fragment that would break exact matching`() {
        // Errors come back on this same URI as `?error=<code>`, which is fine --
        // but the REGISTERED and SENT value must be the bare path. A stray query
        // string baked into the constant would not exact-match the allow-list.
        val redirect = Uri.parse(BuildConfig.OIDC_REDIRECT_URI)
        assertEquals(null, redirect.query)
        assertEquals(null, redirect.fragment)
        assertTrue(
            "a trailing slash makes this a different string to the allow-list",
            !BuildConfig.OIDC_REDIRECT_URI.endsWith("/"),
        )
    }

    private companion object {
        /**
         * Must equal one entry of ops' `SSO_REDIRECT_ALLOWLIST`, character for
         * character. Currently deployed:
         *
         *   https://timely.noizu.com/app/auth/callback,com.noizu.timely://auth/callback
         *
         * Android uses the first. The second is iOS's, and note it is the
         * DOUBLE-slash form -- AppAuth's Android default is SINGLE-slash
         * (`com.noizu.timely:/oauth2redirect`), a different URI again. Three
         * spellings of "the same" callback is exactly how the original mismatch
         * happened, which is the argument for converging on the App Link.
         */
        const val ALLOW_LISTED_REDIRECT = "https://timely.noizu.com/app/auth/callback"
    }
}
