package com.noizu.timely.sync

import com.noizu.timely.data.auth.SessionState
import com.noizu.timely.data.auth.SessionStore
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * An in-memory [SessionStore].
 *
 * Exists so the offline tests can put the session into states that are awkward
 * to reach for real -- an expired access token with a valid refresh token, a
 * `reauth_required` session with a full queue -- without an Android Keystore.
 */
class FakeSessionStore(
    private var access: String? = "access-token",
    private var refresh: String? = "refresh-token",
    private var user: String? = "user-1",
    private var workspace: String? = WORKSPACE_ID,
    private val device: String = "device-1",
) : SessionStore {

    private val _session = MutableStateFlow(
        SessionState(
            userId = user,
            workspaceId = workspace,
            hasAccessToken = access != null,
            hasRefreshToken = refresh != null,
        ),
    )
    override val session: StateFlow<SessionState> = _session.asStateFlow()

    var reauthMarked: Boolean = false
        private set
    var clearTokensCalls: Int = 0
        private set
    var clearAllCalls: Int = 0
        private set

    override fun accessToken(): String? = access
    override fun refreshToken(): String? = refresh
    override fun userId(): String? = user
    override fun workspaceId(): String? = workspace
    override fun deviceId(): String = device
    override fun deviceRegistered(): Boolean = true

    override fun saveTokens(accessToken: String?, refreshToken: String?) {
        accessToken?.let { access = it }
        refreshToken?.let { refresh = it }
        publish()
    }

    override fun saveIdentity(userId: String?, workspaceId: String?, email: String?) {
        userId?.let { user = it }
        workspaceId?.let { workspace = it }
        publish()
    }

    override fun markReauthRequired() {
        reauthMarked = true
        access = null
        publish()
    }

    override fun markDeviceRegistered() = Unit

    override fun clearTokens() {
        clearTokensCalls++
        access = null
        refresh = null
        publish()
    }

    override fun clearAll() {
        clearAllCalls++
        access = null; refresh = null; user = null; workspace = null
        publish()
    }

    /** Simulate the access token ageing out while the refresh token survives. */
    fun expireAccessToken() {
        access = "expired-access-token"
        publish()
    }

    fun signOut() {
        access = null
        refresh = null
        publish()
    }

    private fun publish() {
        _session.value = SessionState(
            userId = user,
            workspaceId = workspace,
            hasAccessToken = access != null,
            hasRefreshToken = refresh != null,
            reauthRequired = reauthMarked,
        )
    }

    companion object {
        /** The fixture workspace, so ids in tests line up with canon-fixtures.json. */
        const val WORKSPACE_ID = "0192f7a1-2b44-7000-8a10-9d3e4f5a6b7c"
    }
}
