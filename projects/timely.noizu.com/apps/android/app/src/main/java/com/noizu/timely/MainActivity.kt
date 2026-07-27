package com.noizu.timely

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.lifecycle.lifecycleScope
import com.noizu.timely.data.auth.SsoError
import com.noizu.timely.data.auth.SsoFlow
import com.noizu.timely.data.repo.AuthRepository
import com.noizu.timely.data.repo.AuthResult
import com.noizu.timely.ui.nav.TimelyApp
import com.noizu.timely.ui.theme.TimelyTheme
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject lateinit var authRepository: AuthRepository
    @Inject lateinit var ssoFlow: SsoFlow

    /**
     * The in-flight attempt, holding the PKCE verifier.
     *
     * Deliberately NOT persisted and NOT in the encrypted store. The verifier is
     * meaningful only between opening the browser and redeeming the code moments
     * later; writing it to disk would give it a lifetime far longer than its
     * purpose, for no benefit. The cost is that a process death mid-flow loses
     * the attempt -- the user taps sign-in again, which is a far better outcome
     * than a verifier outliving the exchange it existed for.
     */
    private var attempt: SsoFlow.Attempt? = null

    /** Surfaced to the sign-in screen. */
    private val ssoMessage = MutableStateFlow<SsoBanner?>(null)

    data class SsoBanner(
        val title: String,
        val detail: String,
        val isRetryable: Boolean,
        val suggestsPasswordFallback: Boolean,
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            TimelyTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    TimelyApp(
                        onLaunchOidc = { launchSso() },
                        ssoBanner = ssoMessage,
                        onDismissSsoBanner = { ssoMessage.value = null },
                    )
                }
            }
        }

        // A cold start via the App Link: the redirect arrived before onCreate.
        handleRedirect(intent)
    }

    /**
     * `launchMode="singleTask"`, so a redirect into a running app lands here
     * rather than creating a second activity. Without it the user would end up
     * with two stacked copies of Timely, the one holding the verifier buried
     * underneath the one showing the result.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleRedirect(intent)
    }

    private fun launchSso(provider: String? = null) {
        ssoMessage.value = null
        val started = ssoFlow.begin(
            baseUrl = BuildConfig.TIMELY_BASE_URL,
            redirectUri = BuildConfig.OIDC_REDIRECT_URI,
            provider = provider,
        )
        attempt = started

        try {
            CustomTabsIntent.Builder()
                .setShowTitle(true)
                .build()
                .launchUrl(this, Uri.parse(started.authorizationUrl))
        } catch (_: ActivityNotFoundException) {
            // No browser at all. Rare, but a device with every browser disabled
            // must be told to use the password form rather than left tapping a
            // button that silently does nothing.
            attempt = null
            ssoMessage.value = SsoError.NO_BROWSER.toBanner()
        }
    }

    private fun handleRedirect(intent: Intent?) {
        val data = intent?.data ?: return
        when (val redirect = ssoFlow.parseRedirect(data, BuildConfig.OIDC_REDIRECT_URI)) {
            is SsoFlow.Redirect.NotSso -> return

            is SsoFlow.Redirect.Failed -> {
                attempt = null
                ssoMessage.value = redirect.error.toBanner()
            }

            is SsoFlow.Redirect.Unrecognised -> {
                attempt = null
                ssoMessage.value = SsoBanner(
                    title = redirect.error.title,
                    detail = redirect.error.detail,
                    isRetryable = redirect.error.isRetryable,
                    suggestsPasswordFallback = redirect.error.suggestsPasswordFallback,
                )
            }

            is SsoFlow.Redirect.Success -> {
                val verifier = attempt?.pkce?.verifier
                // Cleared BEFORE the network call: the code is single-use, so a
                // replayed intent must not be able to redeem it a second time.
                attempt = null
                exchange(redirect.code, verifier)
            }
        }
        // Consume it, so a configuration change does not replay the same
        // callback against an attempt that has already been cleared.
        intent.data = null
    }

    private fun exchange(code: String, verifier: String?) = lifecycleScope.launch {
        when (val result = authRepository.exchangeSsoCode(code, verifier)) {
            is AuthResult.Success -> ssoMessage.value = null
            is AuthResult.Failed -> ssoMessage.value = SsoBanner(
                title = "Sign-in failed",
                detail = result.message,
                isRetryable = true,
                suggestsPasswordFallback = true,
            )
            is AuthResult.Offline -> ssoMessage.value = SsoBanner(
                title = "Couldn't reach Timely",
                detail = "You signed in, but the app couldn't finish the exchange. " +
                    "Check your connection and try again -- nothing on this device " +
                    "has been changed.",
                isRetryable = true,
                suggestsPasswordFallback = false,
            )
        }
    }

    private fun SsoError.toBanner() = SsoBanner(
        title = title,
        detail = detail,
        isRetryable = isRetryable,
        suggestsPasswordFallback = suggestsPasswordFallback,
    )
}
