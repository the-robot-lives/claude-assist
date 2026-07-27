package com.noizu.timely.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

/** Mutation envelope types from `timely-api.yaml`. */

@Serializable
enum class EntityKindDto {
    @SerialName("client") CLIENT,
    @SerialName("project") PROJECT,
    @SerialName("ticket") TICKET,
    @SerialName("time_span") TIME_SPAN,
    @SerialName("screenshot") SCREENSHOT,
    @SerialName("vision_analysis") VISION_ANALYSIS,
    @SerialName("censored_screenshot") CENSORED_SCREENSHOT,
    @SerialName("device") DEVICE,
    @SerialName("user_settings") USER_SETTINGS,
    @SerialName("workspace_policy") WORKSPACE_POLICY,
}

@Serializable
enum class MutationOpDto {
    @SerialName("create") CREATE,
    @SerialName("update") UPDATE,
    @SerialName("delete") DELETE,
}

@Serializable
enum class MutationStatusDto {
    @SerialName("applied") APPLIED,
    @SerialName("conflict") CONFLICT,
    @SerialName("rejected") REJECTED,
}

@Serializable
enum class MutationReasonDto {
    @SerialName("stale_write") STALE_WRITE,
    @SerialName("duplicate_name") DUPLICATE_NAME,
    @SerialName("tombstoned") TOMBSTONED,
    @SerialName("span_reopen_forbidden") SPAN_REOPEN_FORBIDDEN,
    @SerialName("immutable_entity") IMMUTABLE_ENTITY,
    @SerialName("not_device_owner") NOT_DEVICE_OWNER,
    @SerialName("unknown_entity") UNKNOWN_ENTITY,
    @SerialName("validation_failed") VALIDATION_FAILED,
    @SerialName("workspace_mismatch") WORKSPACE_MISMATCH,
    @SerialName("clock_skew_rejected") CLOCK_SKEW_REJECTED,
    @SerialName("locked_day") LOCKED_DAY,
    @SerialName("permission_denied") PERMISSION_DENIED,
    @SerialName("batch_rolled_back") BATCH_ROLLED_BACK,
}

@Serializable
data class MutationDto(
    @SerialName("mutation_id") val mutationId: String,
    val entity: EntityKindDto,
    val op: MutationOpDto,
    @SerialName("base_revision") val baseRevision: Long? = null,
    val payload: JsonObject,
)

@Serializable
data class MutationRequestDto(
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("device_id") val deviceId: String,
    val atomic: Boolean = false,
    val mutations: List<MutationDto>,
)

@Serializable
data class SideEffectDto(
    val entity: EntityKindDto,
    val row: JsonObject,
)

@Serializable
data class MutationResultDto(
    @SerialName("mutation_id") val mutationId: String,
    val status: MutationStatusDto,
    val reason: MutationReasonDto? = null,
    val message: String? = null,
    /**
     * The kind of thing this result is about.
     *
     * On the ENVELOPE, as a sibling of [entity], not inside the row. That
     * placement is what makes it useful: a `rejected` result carries no row at
     * all, and that is exactly the case where the client most needs to know what
     * was refused in order to route the failure back to the queued mutation.
     *
     * Nullable only so that a server predating this field does not fail to
     * decode. Once every deployment sends it, this can become non-null.
     */
    @SerialName("entity_kind") val entityKind: EntityKindDto? = null,
    val entity: JsonObject? = null,
    @SerialName("side_effects") val sideEffects: List<SideEffectDto> = emptyList(),
    val replayed: Boolean = false,
    @SerialName("stale_base") val staleBase: Boolean = false,
    @SerialName("unresolved_refs") val unresolvedRefs: List<String> = emptyList(),
)

@Serializable
data class MutationResponseDto(
    val results: List<MutationResultDto> = emptyList(),
    @SerialName("next_cursor") val nextCursor: Long = 0,
    @SerialName("server_time") val serverTime: String? = null,
)

// ------------------------------------------------------------- devices ----

@Serializable
data class DeviceRegistrationDto(
    @SerialName("device_id") val deviceId: String,
    @SerialName("workspace_id") val workspaceId: String,
    val platform: DevicePlatformDto = DevicePlatformDto.ANDROID,
    val name: String,
    @SerialName("app_version") val appVersion: String,
    @SerialName("os_version") val osVersion: String? = null,
    /**
     * A companion holds no bytes, so this is always true and the field exists
     * only to keep the device row honest for other surfaces.
     */
    @SerialName("local_only_screenshots") val localOnlyScreenshots: Boolean = true,
    /**
     * Hard-coded false. Android is a companion; the server rejects a
     * capture-agent claim from a non-macOS platform anyway.
     */
    @SerialName("is_capture_agent") val isCaptureAgent: Boolean = false,
)

@Serializable
data class DeviceUpdateDto(
    val name: String? = null,
    @SerialName("app_version") val appVersion: String? = null,
    @SerialName("os_version") val osVersion: String? = null,
    @SerialName("local_only_screenshots") val localOnlyScreenshots: Boolean? = null,
)

@Serializable
data class DeviceEnvelopeDto(
    val device: DeviceDto,
    @SerialName("workspace_policy") val workspacePolicy: WorkspacePolicyDto? = null,
    @SerialName("server_time") val serverTime: String? = null,
    @SerialName("sync_cursor") val syncCursor: Long = 0,
)

// ------------------------------------------------------------- reports ----

@Serializable
data class ReportRangeDto(
    val from: String,
    val to: String,
    @SerialName("time_zone") val timeZone: String = "UTC",
)

@Serializable
data class ReportTotalsDto(
    @SerialName("elapsed_seconds") val elapsedSeconds: Long = 0,
    @SerialName("billable_seconds") val billableSeconds: Long = 0,
    @SerialName("non_billable_seconds") val nonBillableSeconds: Long = 0,
    @SerialName("weighted_billable_seconds") val weightedBillableSeconds: Long = 0,
    @SerialName("span_count") val spanCount: Int = 0,
    @SerialName("needs_review_count") val needsReviewCount: Int = 0,
    @SerialName("evidence_coverage") val evidenceCoverage: Double = 0.0,
)

@Serializable
data class ReportGroupDto(
    val key: String,
    @SerialName("key_id") val keyId: String? = null,
    val label: String,
    @SerialName("parent_label") val parentLabel: String? = null,
    @SerialName("elapsed_seconds") val elapsedSeconds: Long = 0,
    @SerialName("billable_seconds") val billableSeconds: Long = 0,
    @SerialName("weighted_billable_seconds") val weightedBillableSeconds: Long = 0,
    @SerialName("span_count") val spanCount: Int = 0,
    @SerialName("evidence_coverage") val evidenceCoverage: Double = 0.0,
)

@Serializable
data class ReportWarningDto(
    val code: String,
    val message: String,
    val count: Int = 0,
)

@Serializable
data class ReportSummaryDto(
    val range: ReportRangeDto,
    @SerialName("group_by") val groupBy: String = "project",
    val totals: ReportTotalsDto = ReportTotalsDto(),
    val groups: List<ReportGroupDto> = emptyList(),
    val warnings: List<ReportWarningDto> = emptyList(),
    @SerialName("generated_at") val generatedAt: String? = null,
    @SerialName("server_revision") val serverRevision: Long = 0,
)

// ---------------------------------------------------------------- auth ----

@Serializable
data class LoginRequestDto(val email: String, val password: String)

@Serializable
data class RegisterRequestDto(
    val email: String,
    val password: String,
    val name: String? = null,
)

@Serializable
data class RefreshRequestDto(@SerialName("refresh_token") val refreshToken: String)

/**
 * `POST /api/v1/auth/sso/exchange`.
 *
 * `code_verifier` is nullable so it can be OMITTED, not sent as null, when PKCE
 * was not used -- `explicitNulls = false` drops a null property, which is the
 * behaviour we want here and the reason this is not a non-null field with an
 * empty-string default. Consistent with the presence-sensitivity rule applied
 * everywhere else on the wire: absent means "not supplied", null means "supplied
 * as nothing", and they are not the same statement.
 */
@Serializable
data class SsoExchangeRequestDto(
    val code: String,
    @SerialName("code_verifier") val codeVerifier: String? = null,
)

/**
 * The scaffold's auth response.
 *
 * `access_token` and `refresh_token` are the real names and the only ones: the
 * backend confirmed every response body in `auth_controller.ex` and
 * `sso_controller.ex` returns exactly these, and nothing anywhere returns a bare
 * `token`. An earlier tolerant accessor here accepted `token` as an alternate;
 * that was wrong. `token` IS a real field name in this API, but as an inbound
 * REQUEST parameter on `/auth/magic-link/verify` and
 * `/auth/verify-email/confirm` -- never as a response field. Tolerating it on
 * the response would have silently accepted a shape the server never sends,
 * which is worse than failing loudly: it hides a contract break instead of
 * reporting it.
 */
@Serializable
data class AuthTokensDto(
    @SerialName("access_token") val accessToken: String? = null,
    @SerialName("refresh_token") val refreshToken: String? = null,
    @SerialName("expires_in") val expiresIn: Long? = null,
    @SerialName("token_type") val tokenType: String? = null,
    val user: AuthUserDto? = null,
)

@Serializable
data class AuthUserDto(
    val id: String,
    val email: String? = null,
    val name: String? = null,
    @SerialName("organization_id") val organizationId: String? = null,
    @SerialName("default_organization_id") val defaultOrganizationId: String? = null,
) {
    /** A Timely `workspace_id` is the scaffold's organization id. */
    val workspaceId: String? get() = organizationId ?: defaultOrganizationId
}

@Serializable
data class ErrorDto(
    val code: String = "",
    val message: String = "",
    val details: JsonObject? = null,
)
