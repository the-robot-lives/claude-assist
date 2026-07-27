package com.noizu.timely.data.remote

import com.noizu.timely.data.remote.dto.AuthTokensDto
import com.noizu.timely.data.remote.dto.AuthUserDto
import com.noizu.timely.data.remote.dto.ChangesResponseDto
import com.noizu.timely.data.remote.dto.DeviceEnvelopeDto
import com.noizu.timely.data.remote.dto.DeviceRegistrationDto
import com.noizu.timely.data.remote.dto.DeviceUpdateDto
import com.noizu.timely.data.remote.dto.LoginRequestDto
import com.noizu.timely.data.remote.dto.MutationRequestDto
import com.noizu.timely.data.remote.dto.MutationResponseDto
import com.noizu.timely.data.remote.dto.RefreshRequestDto
import com.noizu.timely.data.remote.dto.RegisterRequestDto
import com.noizu.timely.data.remote.dto.SsoExchangeRequestDto
import com.noizu.timely.data.remote.dto.ReportSummaryDto
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

interface TimelyApi {

    @POST("api/v1/devices")
    suspend fun registerDevice(@Body body: DeviceRegistrationDto): Response<DeviceEnvelopeDto>

    @PATCH("api/v1/devices/{device_id}")
    suspend fun updateDevice(
        @Path("device_id") deviceId: String,
        @Body body: DeviceUpdateDto,
    ): Response<DeviceEnvelopeDto>

    @GET("api/v1/sync/changes")
    suspend fun pullChanges(
        @Query("workspace_id") workspaceId: String,
        @Query("since") since: Long,
        @Query("limit") limit: Int = 500,
        @Query("entities") entities: String? = null,
    ): Response<ChangesResponseDto>

    @POST("api/v1/sync/mutations")
    suspend fun pushMutations(@Body body: MutationRequestDto): Response<MutationResponseDto>

    @GET("api/v1/reports/summary")
    suspend fun reportSummary(
        @Query("workspace_id") workspaceId: String,
        @Query("from") from: String,
        @Query("to") to: String,
        @Query("group_by") groupBy: String? = null,
        @Query("client_id") clientId: String? = null,
        @Query("project_id") projectId: String? = null,
        @Query("billable") billable: Boolean? = null,
        @Query("include_unreviewed") includeUnreviewed: Boolean? = null,
        @Query("time_zone") timeZone: String? = null,
    ): Response<ReportSummaryDto>

    /**
     * Screenshot bytes are download-only on Android.
     *
     * There is deliberately no upload method on this interface. See
     * [com.noizu.timely.data.privacy.ScreenshotGate] -- the absence of an upload
     * call is the structural half of the privacy guarantee.
     *
     * A 404 here is the NORMAL path for a local-only screenshot and MUST NOT be
     * surfaced as an error (protocol 10.2).
     */
    @GET("api/v1/screenshots/{screenshot_id}/blob")
    suspend fun downloadScreenshotBlob(
        @Path("screenshot_id") screenshotId: String,
        @Header("Accept") accept: String = "image/png, image/jpeg",
    ): Response<okhttp3.ResponseBody>
}

/**
 * Auth lives in the scaffold, not in the Timely contract. Kept on a separate
 * interface because these calls must bypass the token interceptor's refresh
 * logic (refreshing a refresh call would recurse).
 */
interface AuthApi {

    @POST("api/v1/auth/register")
    suspend fun register(@Body body: RegisterRequestDto): Response<AuthTokensDto>

    @POST("api/v1/auth/login")
    suspend fun login(@Body body: LoginRequestDto): Response<AuthTokensDto>

    @POST("api/v1/auth/refresh")
    suspend fun refresh(@Body body: RefreshRequestDto): Response<AuthTokensDto>

    @GET("api/v1/auth/me")
    suspend fun me(): Response<AuthUserDto>

    /**
     * Exchange the SSO authorization code for tokens.
     *
     * The app never talks to the identity provider: our server is the
     * confidential OAuth client and has already completed that leg. This
     * exchange is between the app and our server, which is what the PKCE
     * verifier protects.
     */
    @POST("api/v1/auth/sso/exchange")
    suspend fun ssoExchange(@Body body: SsoExchangeRequestDto): Response<AuthTokensDto>
}
