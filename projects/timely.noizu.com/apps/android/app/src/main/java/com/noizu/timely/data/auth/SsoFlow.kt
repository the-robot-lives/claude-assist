package com.noizu.timely.data.auth

import android.net.Uri
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Builds the authorization URL and interprets the redirect.
 *
 * Deliberately has no network dependency and no Android dependency beyond [Uri],
 * so the URL shape and the redirect parsing can be tested for what they are --
 * string handling with security consequences -- rather than through a browser.
 */
@Singleton
class SsoFlow @Inject constructor() {

    /** One in-flight attempt. The verifier lives here and nowhere else. */
    data class Attempt(
        val pkce: Pkce,
        val authorizationUrl: String,
        val provider: String?,
    )

    /**
     * `GET /auth/oidc?redirect_uri=…&code_challenge=…&code_challenge_method=S256`
     * or `/auth/:provider` for social.
     *
     * The CHALLENGE goes in the URL. The VERIFIER does not, and
     * `SsoFlowTest.the verifier never appears in the authorization URL` asserts
     * it -- the URL is exactly what a redirect interceptor gets to read, so
     * putting the verifier there would hand over the one secret that makes the
     * interception survivable.
     */
    fun begin(baseUrl: String, redirectUri: String, provider: String? = null): Attempt {
        val pkce = Pkce.generate()
        val path = if (provider.isNullOrBlank()) "auth/oidc" else "auth/$provider"

        val url = Uri.parse(baseUrl.trimEnd('/'))
            .buildUpon()
            .appendEncodedPath(path)
            // appendQueryParameter percent-encodes values, so the redirect_uri's
            // own `:` and `/` survive as an opaque string rather than being
            // parsed as structure by anything in between.
            .appendQueryParameter("redirect_uri", redirectUri)
            .appendQueryParameter("code_challenge", pkce.challenge)
            .appendQueryParameter("code_challenge_method", pkce.method)
            .build()
            .toString()

        return Attempt(pkce = pkce, authorizationUrl = url, provider = provider)
    }

    /** What came back on the redirect. */
    sealed interface Redirect {
        data class Success(val code: String) : Redirect
        data class Failed(val error: SsoError) : Redirect
        data class Unrecognised(val error: UnknownSsoError) : Redirect
        /** Not our redirect at all -- a deep link into the app for some other reason. */
        data object NotSso : Redirect
    }

    fun parseRedirect(uri: Uri?, expectedRedirectUri: String): Redirect {
        if (uri == null) return Redirect.NotSso

        // Compare against the registered redirect without its query, since the
        // real one arrives carrying `?code=` or `?error=`.
        val expected = Uri.parse(expectedRedirectUri)
        val sameTarget = uri.scheme == expected.scheme &&
            uri.host == expected.host &&
            uri.path == expected.path
        if (!sameTarget) return Redirect.NotSso

        uri.getQueryParameter("error")?.let { raw ->
            return SsoError.fromCode(raw)
                ?.let(Redirect::Failed)
                ?: Redirect.Unrecognised(SsoError.describeUnknown(raw))
        }

        val code = uri.getQueryParameter("code")
        // Neither `code` nor `error`: a malformed callback. Treated as a failure
        // rather than ignored, because silently doing nothing would leave the
        // user staring at a sign-in screen that appears to have forgotten them.
        return if (code.isNullOrBlank()) {
            Redirect.Failed(SsoError.SSO_FAILED)
        } else {
            Redirect.Success(code)
        }
    }
}
