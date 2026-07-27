package com.noizu.timely.data.auth

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.noizu.timely.core.identity.Uuids
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Session state as the rest of the app sees it.
 *
 * Note what is NOT here: any notion of "may I write". Token state never gates
 * local reads or writes (protocol 11.3). This type exists so the UI can show an
 * honest status line, not so callers can decide whether to let the user edit.
 */
data class SessionState(
    val userId: String? = null,
    val workspaceId: String? = null,
    val email: String? = null,
    val hasAccessToken: Boolean = false,
    val hasRefreshToken: Boolean = false,
    val reauthRequired: Boolean = false,
) {
    val isSignedIn: Boolean get() = userId != null
}

/**
 * Tokens at rest.
 *
 * Backed by [EncryptedSharedPreferences] (AES256-GCM values, AES256-SIV keys,
 * master key in the Android Keystore). Plain SharedPreferences would leave
 * bearer tokens in world-readable-to-root XML and readable by anything with a
 * backup extraction; that is the one storage choice this app cannot get wrong.
 */
@Singleton
class TokenStore @Inject constructor(
    @ApplicationContext private val context: Context,
) : SessionStore {

    private val prefs: SharedPreferences by lazy {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        EncryptedSharedPreferences.create(
            context,
            FILE_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    private val _session = MutableStateFlow(readSession())
    override val session: StateFlow<SessionState> = _session.asStateFlow()

    @Synchronized
    override fun accessToken(): String? = prefs.getString(KEY_ACCESS, null)

    @Synchronized
    override fun refreshToken(): String? = prefs.getString(KEY_REFRESH, null)

    @Synchronized
    override fun userId(): String? = prefs.getString(KEY_USER_ID, null)

    @Synchronized
    override fun workspaceId(): String? = prefs.getString(KEY_WORKSPACE_ID, null)

    /**
     * This installation's stable device id, minted once and kept.
     *
     * Deliberately NOT derived from a hardware identifier: ANDROID_ID is scoped
     * per signing key and per user profile, survives an app reinstall in some
     * OEM builds and not others, and using it would make the sync device row a
     * cross-app tracking surface for no benefit. A random v7 minted on first run
     * is stable for as long as the install lives, which is exactly the lifetime
     * the protocol's device row is about.
     *
     * It lives in the encrypted store beside the tokens so that clearing
     * credentials on an account switch also retires the device identity.
     */
    @Synchronized
    override fun deviceId(): String {
        prefs.getString(KEY_DEVICE_ID, null)?.let { return it }
        val minted = Uuids.v7String()
        prefs.edit().putString(KEY_DEVICE_ID, minted).commit()
        return minted
    }

    /** True once the device row has been registered with the server. */
    @Synchronized
    override fun deviceRegistered(): Boolean = prefs.getBoolean(KEY_DEVICE_REGISTERED, false)

    @Synchronized
    override fun markDeviceRegistered() {
        prefs.edit().putBoolean(KEY_DEVICE_REGISTERED, true).commit()
    }

    /**
     * Store the new access token, and the new refresh token if one was issued,
     * BEFORE discarding the old one (protocol 11.2 step 2). A crash between the
     * two writes must not leave the device with no usable refresh token.
     */
    @Synchronized
    override fun saveTokens(accessToken: String?, refreshToken: String?) {
        prefs.edit().apply {
            accessToken?.let { putString(KEY_ACCESS, it) }
            refreshToken?.let { putString(KEY_REFRESH, it) }
            putBoolean(KEY_REAUTH_REQUIRED, false)
        }.commit()
        _session.value = readSession()
    }

    @Synchronized
    override fun saveIdentity(userId: String?, workspaceId: String?, email: String?) {
        prefs.edit().apply {
            userId?.let { putString(KEY_USER_ID, it) }
            workspaceId?.let { putString(KEY_WORKSPACE_ID, it) }
            email?.let { putString(KEY_EMAIL, it) }
        }.commit()
        _session.value = readSession()
    }

    /**
     * Refresh failed with 401.
     *
     * Marks the session `reauth_required` and does NOT clear the local store or
     * the push queue (protocol 11.2 step 3). Clearing either here would delete a
     * user's unsynced workday because a token aged out overnight.
     */
    @Synchronized
    override fun markReauthRequired() {
        prefs.edit()
            .putBoolean(KEY_REAUTH_REQUIRED, true)
            .remove(KEY_ACCESS)
            .commit()
        _session.value = readSession()
    }

    /**
     * Sign out. Deliberately keeps `user_id` so that
     * [com.noizu.timely.data.sync.PushQueue] can still tell whether a later
     * sign-in is the same principal the queue was built under (protocol 11.4).
     */
    @Synchronized
    override fun clearTokens() {
        prefs.edit()
            .remove(KEY_ACCESS)
            .remove(KEY_REFRESH)
            .putBoolean(KEY_REAUTH_REQUIRED, false)
            .commit()
        _session.value = readSession()
    }

    /** Full wipe, used only when the user explicitly switches account. */
    @Synchronized
    override fun clearAll() {
        prefs.edit().clear().commit()
        _session.value = readSession()
    }

    private fun readSession() = SessionState(
        userId = prefs.getString(KEY_USER_ID, null),
        workspaceId = prefs.getString(KEY_WORKSPACE_ID, null),
        email = prefs.getString(KEY_EMAIL, null),
        hasAccessToken = prefs.getString(KEY_ACCESS, null) != null,
        hasRefreshToken = prefs.getString(KEY_REFRESH, null) != null,
        reauthRequired = prefs.getBoolean(KEY_REAUTH_REQUIRED, false),
    )

    private companion object {
        const val FILE_NAME = "timely_secure_tokens"
        const val KEY_ACCESS = "access_token"
        const val KEY_REFRESH = "refresh_token"
        const val KEY_USER_ID = "user_id"
        const val KEY_WORKSPACE_ID = "workspace_id"
        const val KEY_EMAIL = "email"
        const val KEY_REAUTH_REQUIRED = "reauth_required"
        const val KEY_DEVICE_ID = "device_id"
        const val KEY_DEVICE_REGISTERED = "device_registered"
    }
}
