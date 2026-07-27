package com.noizu.timely.data.repo

import com.noizu.timely.BuildConfig
import com.noizu.timely.data.auth.SessionState
import com.noizu.timely.data.auth.TokenStore
import com.noizu.timely.data.privacy.ScreenshotGate
import com.noizu.timely.data.remote.AuthApi
import com.noizu.timely.data.remote.TimelyApi
import com.noizu.timely.data.remote.dto.AuthTokensDto
import com.noizu.timely.data.remote.dto.DeviceRegistrationDto
import com.noizu.timely.data.remote.dto.LoginRequestDto
import com.noizu.timely.data.remote.dto.RegisterRequestDto
import com.noizu.timely.data.remote.dto.SsoExchangeRequestDto
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import javax.inject.Singleton

sealed interface AuthResult {
    data object Success : AuthResult
    data class Failed(val message: String) : AuthResult
    /** No network. Distinguished from bad credentials so the UI can say so honestly. */
    data class Offline(val message: String) : AuthResult
}

/**
 * Email/password and OIDC sign-in.
 *
 * Note what this class does NOT do: it never touches the local store or the push
 * queue on failure. A user whose token expired overnight still opens the app to
 * their full timeline and can still edit it; signing in again just lets the
 * queue drain. That is protocol 11.2 step 3 and it is the difference between an
 * offline-capable app and one that merely caches.
 */
@Singleton
class AuthRepository @Inject constructor(
    private val authApi: AuthApi,
    private val timelyApi: TimelyApi,
    private val tokenStore: TokenStore,
) {

    val session: StateFlow<SessionState> get() = tokenStore.session

    suspend fun signIn(email: String, password: String): AuthResult = runCatching {
        val response = authApi.login(LoginRequestDto(email = email, password = password))
        if (!response.isSuccessful) {
            return@runCatching AuthResult.Failed(
                when (response.code()) {
                    401, 403 -> "That email and password did not match."
                    else -> "Sign-in failed (HTTP ${response.code()})."
                },
            )
        }
        adopt(response.body()) ?: AuthResult.Failed("The server returned no token.")
    }.getOrElse { AuthResult.Offline(it.message ?: "Could not reach the server.") }

    suspend fun register(email: String, password: String, name: String?): AuthResult = runCatching {
        val response = authApi.register(RegisterRequestDto(email, password, name))
        if (!response.isSuccessful) {
            return@runCatching AuthResult.Failed("Registration failed (HTTP ${response.code()}).")
        }
        adopt(response.body()) ?: AuthResult.Failed("The server returned no token.")
    }.getOrElse { AuthResult.Offline(it.message ?: "Could not reach the server.") }

    /**
     * Exchange an SSO authorization code for tokens.
     *
     * The browser leg lives in the Activity because it needs one; everything
     * after it lands here, so there is one identity-hydration path rather than a
     * second, subtly different one.
     *
     * The verifier is passed in rather than held by this class: it belongs to a
     * single in-flight attempt, and a repository that cached it would keep a
     * secret alive past the attempt that needed it.
     */
    suspend fun exchangeSsoCode(code: String, codeVerifier: String?): AuthResult = runCatching {
        val response = authApi.ssoExchange(
            SsoExchangeRequestDto(code = code, codeVerifier = codeVerifier),
        )
        if (!response.isSuccessful) {
            return@runCatching AuthResult.Failed(
                when (response.code()) {
                    400 -> "That sign-in link was rejected. Please start again."
                    401, 403 -> "That sign-in wasn't accepted."
                    // The code is single-use with a short TTL, so a stale one is
                    // an ordinary outcome (a retried intent, a resumed app), not
                    // an error worth alarming language.
                    404, 410 -> "That sign-in link has expired. Please start again."
                    else -> "Sign-in failed (HTTP ${response.code()})."
                },
            )
        }
        adopt(response.body()) ?: AuthResult.Failed("The server returned no token.")
    }.getOrElse { AuthResult.Offline(it.message ?: "Could not reach the server.") }

    private suspend fun adopt(tokens: AuthTokensDto?): AuthResult? {
        val access = tokens?.accessToken ?: return null
        tokenStore.saveTokens(access, tokens.refreshToken)
        tokens.user?.let { tokenStore.saveIdentity(it.id, it.workspaceId, it.email) }
        return hydrateIdentity()
    }

    /** Resolve who we are and which workspace we sync, then register the device. */
    private suspend fun hydrateIdentity(): AuthResult = runCatching {
        if (tokenStore.userId() == null || tokenStore.workspaceId() == null) {
            val me = authApi.me()
            if (me.isSuccessful) {
                me.body()?.let { tokenStore.saveIdentity(it.id, it.workspaceId, it.email) }
            }
        }
        if (tokenStore.workspaceId() == null) {
            return@runCatching AuthResult.Failed(
                "Signed in, but this account has no workspace yet.",
            )
        }
        registerDevice()
        AuthResult.Success
    }.getOrElse { AuthResult.Offline(it.message ?: "Could not reach the server.") }

    /**
     * Register this installation as a companion device.
     *
     * `local_only_screenshots` and `is_capture_agent` are read from
     * [ScreenshotGate] rather than written as literals, so the device row and the
     * push allowlist state the same fact and cannot drift apart. The server
     * rejects a capture-agent claim from a non-macOS platform anyway; this is
     * the client half of saying the same thing.
     */
    suspend fun registerDevice(): Boolean = runCatching {
        val workspaceId = tokenStore.workspaceId() ?: return false
        val response = timelyApi.registerDevice(
            DeviceRegistrationDto(
                deviceId = tokenStore.deviceId(),
                workspaceId = workspaceId,
                name = "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}".trim(),
                appVersion = BuildConfig.VERSION_NAME,
                osVersion = "Android ${android.os.Build.VERSION.RELEASE}",
                localOnlyScreenshots = ScreenshotGate.LOCAL_ONLY_SCREENSHOTS,
                isCaptureAgent = ScreenshotGate.IS_CAPTURE_AGENT,
            ),
        )
        if (response.isSuccessful) tokenStore.markDeviceRegistered()
        response.isSuccessful
    }.getOrDefault(false)

    /**
     * Sign out.
     *
     * Clears credentials and NOTHING else. The local mirror and the push queue
     * stay exactly where they are, because "sign out" and "throw away my
     * unsynced work" are different requests and only one of them was made.
     */
    fun signOut() {
        tokenStore.clearTokens()
    }

    /** The only path that discards local data, and only on explicit confirmation. */
    suspend fun switchAccount(clearLocal: suspend (String) -> Unit) {
        tokenStore.workspaceId()?.let { clearLocal(it) }
        tokenStore.clearAll()
    }
}
