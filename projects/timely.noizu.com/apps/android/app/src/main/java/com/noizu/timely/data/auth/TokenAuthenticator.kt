package com.noizu.timely.data.auth

import com.noizu.timely.data.remote.dto.AuthTokensDto
import com.noizu.timely.data.remote.dto.RefreshRequestDto
import kotlinx.serialization.json.Json
import okhttp3.Authenticator
import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okhttp3.Route
import javax.inject.Inject
import javax.inject.Provider
import javax.inject.Singleton

/**
 * Attaches `Authorization: Bearer <access_token>` to every Timely request.
 *
 * A request with no token is still sent. The server answers 401, the sync
 * engine treats that as "not now" and leaves the queue intact -- which is the
 * whole offline story. Short-circuiting here would be equivalent to gating
 * writes on token freshness, which protocol 11.3 forbids.
 */
@Singleton
class AuthInterceptor @Inject constructor(
    private val tokenStore: TokenStore,
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        if (request.header(HEADER_AUTHORIZATION) != null || request.header(HEADER_SKIP_AUTH) != null) {
            return chain.proceed(request.newBuilder().removeHeader(HEADER_SKIP_AUTH).build())
        }
        val token = tokenStore.accessToken()
            ?: return chain.proceed(request)
        return chain.proceed(
            request.newBuilder().header(HEADER_AUTHORIZATION, "Bearer $token").build(),
        )
    }

    companion object {
        const val HEADER_AUTHORIZATION = "Authorization"
        const val HEADER_SKIP_AUTH = "X-Timely-Skip-Auth"
    }
}

/**
 * Refresh-on-401, per protocol 11.2.
 *
 * OkHttp calls an [Authenticator] only after a 401 and re-issues the returned
 * request, so "refresh once, retry once" falls out of returning null on the
 * second attempt.
 *
 * The whole body is `@Synchronized`: 11.2 step 4 requires a client to serialize
 * refresh. Without it, a sync push and a report fetch that 401 together each
 * spend the refresh token, and whichever lands second is rejected against a
 * rotated token -- signing the user out mid-sync for no reason.
 */
@Singleton
class TokenAuthenticator @Inject constructor(
    private val tokenStore: TokenStore,
    private val refreshClient: Provider<OkHttpClient>,
    private val baseUrl: String,
    private val json: Json,
) : Authenticator {

    @Synchronized
    override fun authenticate(route: Route?, response: Response): Request? {
        // Already retried once. Give up rather than loop.
        if (responseCount(response) >= 2) return null

        val staleToken = response.request.header(AuthInterceptor.HEADER_AUTHORIZATION)
            ?.removePrefix("Bearer ")

        // Another thread refreshed while we waited on the monitor. Retry with
        // the token it obtained instead of spending the refresh token again.
        val current = tokenStore.accessToken()
        if (current != null && current != staleToken) {
            return response.request.newBuilder()
                .header(AuthInterceptor.HEADER_AUTHORIZATION, "Bearer $current")
                .build()
        }

        val refreshToken = tokenStore.refreshToken() ?: run {
            tokenStore.markReauthRequired()
            return null
        }

        val refreshed = performRefresh(refreshToken) ?: run {
            // Refresh failed. Mark the session and stop -- do NOT clear the
            // local store or the push queue (11.2 step 3).
            tokenStore.markReauthRequired()
            return null
        }

        val newAccess = refreshed.accessToken ?: run {
            tokenStore.markReauthRequired()
            return null
        }
        tokenStore.saveTokens(newAccess, refreshed.refreshToken)

        return response.request.newBuilder()
            .header(AuthInterceptor.HEADER_AUTHORIZATION, "Bearer $newAccess")
            .build()
    }

    /**
     * Issued on a bare client with no authenticator and no auth interceptor, so
     * a 401 from the refresh endpoint itself cannot recurse.
     */
    private fun performRefresh(refreshToken: String): AuthTokensDto? = runCatching {
        val body = json.encodeToString(RefreshRequestDto.serializer(), RefreshRequestDto(refreshToken))
            .toRequestBody(JSON_MEDIA_TYPE)
        val request = Request.Builder()
            .url(baseUrl.trimEnd('/') + "/api/v1/auth/refresh")
            .post(body)
            .build()
        refreshClient.get().newCall(request).execute().use { httpResponse ->
            if (!httpResponse.isSuccessful) return null
            val payload = httpResponse.body?.string() ?: return null
            json.decodeFromString(AuthTokensDto.serializer(), payload)
        }
    }.getOrNull()

    private fun responseCount(response: Response): Int {
        var count = 1
        var prior = response.priorResponse
        while (prior != null) {
            count++
            prior = prior.priorResponse
        }
        return count
    }

    private companion object {
        val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()
    }
}
