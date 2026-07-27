package com.noizu.timely.data.auth

/**
 * The SSO failure codes, and what a person should do about each.
 *
 * Errors come back on the redirect URI as `?error=<code>` rather than as a web
 * page. That is deliberate on the server's part: an error rendered as HTML would
 * leave the browser sitting on a dead page with the auth session still open and
 * nothing to return to. Arriving on the redirect means the app regains control
 * and can say something useful.
 *
 * Two flags travel with each code because they drive different affordances, and
 * conflating them produces bad advice:
 *
 * - [isRetryable] -- would pressing the same button again plausibly work? For
 *   `sso_unavailable` yes, eventually. For `not_provisioned` never: the account
 *   does not exist on the other side and no amount of retrying creates it.
 * - [suggestsPasswordFallback] -- is there a different door? Offering "try
 *   again" to someone whose account was never provisioned is an invitation to
 *   fail identically; pointing at the password form is the honest move.
 */
enum class SsoError(
    val code: String,
    val title: String,
    val detail: String,
    val isRetryable: Boolean,
    val suggestsPasswordFallback: Boolean,
) {
    REDIRECT_NOT_ALLOWED(
        code = "redirect_not_allowed",
        title = "This app build can't complete sign-in",
        // A configuration fault, not a user fault, so the copy does not imply
        // the user did anything wrong or that retrying will help.
        detail = "Its sign-in address isn't registered with the server. " +
            "Updating the app usually fixes this; otherwise contact support.",
        isRetryable = false,
        suggestsPasswordFallback = true,
    ),

    INVALID_CODE_CHALLENGE(
        code = "invalid_code_challenge",
        title = "Sign-in couldn't be verified",
        detail = "The security check the app sent wasn't accepted. Try again, " +
            "and update the app if it keeps happening.",
        // Retryable because a fresh verifier is minted per attempt, so a
        // transient generation fault genuinely can clear.
        isRetryable = true,
        suggestsPasswordFallback = true,
    ),

    STATE_MISMATCH(
        code = "state_mismatch",
        title = "Sign-in didn't complete safely",
        detail = "The response didn't match the request this app started. " +
            "That can happen if sign-in was left open too long. Start again.",
        isRetryable = true,
        suggestsPasswordFallback = false,
    ),

    NOT_PROVISIONED(
        code = "not_provisioned",
        title = "No Timely account for that sign-in",
        // The one code where retrying is actively wrong: the identity is valid,
        // it simply has no Timely account behind it.
        detail = "You signed in successfully, but there's no Timely workspace " +
            "for that account yet. Ask an admin to invite you, or sign in with " +
            "an email and password.",
        isRetryable = false,
        suggestsPasswordFallback = true,
    ),

    SSO_UNAVAILABLE(
        code = "sso_unavailable",
        title = "Single sign-on is unavailable",
        detail = "The sign-in service isn't responding. This is usually " +
            "temporary — try again shortly, or use your email and password.",
        isRetryable = true,
        suggestsPasswordFallback = true,
    ),

    SSO_FAILED(
        code = "sso_failed",
        title = "Single sign-on failed",
        detail = "Sign-in didn't complete. Try again, or use your email and password.",
        isRetryable = true,
        suggestsPasswordFallback = true,
    ),

    OIDC_FAILED(
        code = "oidc_failed",
        title = "Your identity provider declined the sign-in",
        // Distinct from SSO_FAILED on purpose: this one means the far side
        // actively said no, so "try again" is weaker advice and the user may
        // need to do something with their provider.
        detail = "The provider rejected the request. Check you're using the " +
            "right account, or sign in with your email and password.",
        isRetryable = false,
        suggestsPasswordFallback = true,
    ),

    /**
     * The browser session itself never ran, or the user backed out.
     *
     * Client-side, not a server code. Kept distinct because "you cancelled" and
     * "the server declined" are different events and deserve different copy --
     * iOS found these conflated, and the result was telling a user something
     * failed when they had simply changed their mind.
     */
    CANCELLED(
        code = "cancelled",
        title = "Sign-in cancelled",
        detail = "You can pick up where you left off whenever you're ready.",
        isRetryable = true,
        suggestsPasswordFallback = false,
    ),

    NO_BROWSER(
        code = "no_browser",
        title = "No browser available",
        detail = "Single sign-on needs a browser. Sign in with your email and " +
            "password instead.",
        isRetryable = false,
        suggestsPasswordFallback = true,
    ),
    ;

    companion object {
        /**
         * Map a wire code, degrading gracefully.
         *
         * An unknown code is NOT mapped to [SSO_FAILED]: the server can ship new
         * codes without an app release, and answering a code we do not
         * understand with confident but wrong advice is worse than admitting we
         * do not know. The unknown case keeps the raw code visible so a support
         * conversation has something to work with.
         */
        fun fromCode(raw: String?): SsoError? =
            raw?.let { code -> entries.firstOrNull { it.code == code } }

        fun describeUnknown(raw: String): UnknownSsoError = UnknownSsoError(raw)
    }
}

/** An `?error=` code this build does not recognise. */
data class UnknownSsoError(val code: String) {
    val title: String = "Sign-in failed"
    val detail: String =
        "The server reported \"$code\", which this version of the app doesn't " +
            "recognise. Updating may help. Meanwhile you can sign in with your " +
            "email and password."
    val isRetryable: Boolean = false
    val suggestsPasswordFallback: Boolean = true
}
