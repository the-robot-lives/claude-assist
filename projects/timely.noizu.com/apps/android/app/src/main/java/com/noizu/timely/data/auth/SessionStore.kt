package com.noizu.timely.data.auth

import kotlinx.coroutines.flow.StateFlow

/**
 * The identity facts the sync engine and repository need.
 *
 * Extracted from [TokenStore] so those two can be tested without the Android
 * Keystore. That is not a cosmetic concern: [TokenStore] is backed by
 * EncryptedSharedPreferences, whose master key lives in the Keystore, and the
 * Keystore is not meaningfully available under a JVM unit test. Without this
 * seam the offline-behaviour tests -- the ones that prove a write still lands
 * with an expired token -- could not run at all, and those are exactly the tests
 * worth having.
 *
 * Note what is deliberately NOT on this interface: any "may I write" predicate.
 * A caller cannot ask this type for permission to save, because no such
 * permission exists (protocol 11.3).
 */
interface SessionStore {
    val session: StateFlow<SessionState>

    fun accessToken(): String?
    fun refreshToken(): String?
    fun userId(): String?
    fun workspaceId(): String?
    fun deviceId(): String
    fun deviceRegistered(): Boolean

    fun saveTokens(accessToken: String?, refreshToken: String?)
    fun saveIdentity(userId: String?, workspaceId: String?, email: String?)
    fun markReauthRequired()
    fun markDeviceRegistered()
    fun clearTokens()
    fun clearAll()
}
