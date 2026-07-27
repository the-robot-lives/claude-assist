package com.noizu.timely.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

/**
 * Wire DTOs mirroring `apps/shared/contracts/timely-api.yaml`.
 *
 * The OpenAPI document composes every entity from `SyncEnvelope` via `allOf`.
 * kotlinx.serialization has no allOf, so the seven envelope fields are repeated
 * on each DTO. They are: id, workspace_id, created_at, updated_at,
 * server_revision, deleted_at, origin_device_id.
 *
 * Timestamps are carried as raw strings at this layer and parsed at the mapper
 * boundary. A malformed timestamp from the server must not take down a whole
 * sync page; the mapper decides what to do with it.
 */

@Serializable
enum class SpanSourceDto {
    @SerialName("manual") MANUAL,
    @SerialName("timer") TIMER,
    @SerialName("pomodoro") POMODORO,
}

@Serializable
enum class ReviewStateDto {
    @SerialName("unreviewed") UNREVIEWED,
    @SerialName("needs_review") NEEDS_REVIEW,
    @SerialName("reviewed") REVIEWED,
    @SerialName("approved") APPROVED,
    @SerialName("locked") LOCKED,
    @SerialName("disputed") DISPUTED,
}

@Serializable
enum class ReviewReasonCodeDto {
    @SerialName("suspected_duplicate") SUSPECTED_DUPLICATE,
    @SerialName("billing_overlap") BILLING_OVERLAP,
    @SerialName("unresolved_idle_gap") UNRESOLVED_IDLE_GAP,
    @SerialName("low_confidence") LOW_CONFIDENCE,
    @SerialName("unresolved_reference") UNRESOLVED_REFERENCE,
    @SerialName("auto_created_entity") AUTO_CREATED_ENTITY,
    @SerialName("privacy_censored") PRIVACY_CENSORED,
    @SerialName("reopened_after_approval") REOPENED_AFTER_APPROVAL,
}

@Serializable
enum class ReviewResolutionDto {
    @SerialName("pending") PENDING,
    @SerialName("accepted") ACCEPTED,
    @SerialName("dismissed") DISMISSED,
    @SerialName("merged") MERGED,
}

@Serializable
enum class RaisedByDto {
    @SerialName("server") SERVER,
    @SerialName("device") DEVICE,
    @SerialName("user") USER,
}

@Serializable
data class ReviewReasonDto(
    val code: ReviewReasonCodeDto,
    val detail: String? = null,
    @SerialName("related_id") val relatedId: String? = null,
    @SerialName("raised_at") val raisedAt: String,
    @SerialName("raised_by") val raisedBy: RaisedByDto,
    val resolution: ReviewResolutionDto = ReviewResolutionDto.PENDING,
    @SerialName("resolved_at") val resolvedAt: String? = null,
)

@Serializable
data class TimeSpanDto(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    val title: String = "",
    @SerialName("client_id") val clientId: String? = null,
    @SerialName("project_id") val projectId: String? = null,
    @SerialName("ticket_id") val ticketId: String? = null,
    @SerialName("client_name") val clientName: String = "",
    @SerialName("project_name") val projectName: String = "",
    @SerialName("ticket_name") val ticketName: String = "",
    val start: String,
    val end: String? = null,
    val source: SpanSourceDto = SpanSourceDto.MANUAL,
    @SerialName("is_billable") val isBillable: Boolean = false,
    val notes: String = "",
    @SerialName("review_state") val reviewState: ReviewStateDto = ReviewStateDto.UNREVIEWED,
    @SerialName("review_reasons") val reviewReasons: List<ReviewReasonDto> = emptyList(),
    @SerialName("derived_from_span_ids") val derivedFromSpanIds: List<String> = emptyList(),
    @SerialName("locked_at") val lockedAt: String? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    @SerialName("updated_at_effective") val updatedAtEffective: String? = null,
    @SerialName("server_revision") val serverRevision: Long = 0,
    @SerialName("deleted_at") val deletedAt: String? = null,
    @SerialName("origin_device_id") val originDeviceId: String? = null,
)

@Serializable
data class ClientDto(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    val name: String,
    @SerialName("canonical_name") val canonicalName: String = "",
    val notes: String = "",
    @SerialName("auto_created") val autoCreated: Boolean = false,
    @SerialName("merged_into_id") val mergedIntoId: String? = null,
    @SerialName("review_state") val reviewState: ReviewStateDto = ReviewStateDto.UNREVIEWED,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    @SerialName("server_revision") val serverRevision: Long = 0,
    @SerialName("deleted_at") val deletedAt: String? = null,
    @SerialName("origin_device_id") val originDeviceId: String? = null,
)

@Serializable
data class ProjectDto(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    val name: String,
    @SerialName("canonical_name") val canonicalName: String = "",
    @SerialName("client_id") val clientId: String? = null,
    @SerialName("client_name") val clientName: String = "",
    val notes: String = "",
    @SerialName("auto_created") val autoCreated: Boolean = false,
    @SerialName("merged_into_id") val mergedIntoId: String? = null,
    @SerialName("review_state") val reviewState: ReviewStateDto = ReviewStateDto.UNREVIEWED,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    @SerialName("server_revision") val serverRevision: Long = 0,
    @SerialName("deleted_at") val deletedAt: String? = null,
    @SerialName("origin_device_id") val originDeviceId: String? = null,
)

@Serializable
data class TicketDto(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    val name: String,
    @SerialName("canonical_name") val canonicalName: String = "",
    @SerialName("client_id") val clientId: String? = null,
    @SerialName("project_id") val projectId: String? = null,
    @SerialName("client_name") val clientName: String = "",
    @SerialName("project_name") val projectName: String = "",
    val notes: String = "",
    @SerialName("auto_created") val autoCreated: Boolean = false,
    @SerialName("merged_into_id") val mergedIntoId: String? = null,
    @SerialName("review_state") val reviewState: ReviewStateDto = ReviewStateDto.UNREVIEWED,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    @SerialName("server_revision") val serverRevision: Long = 0,
    @SerialName("deleted_at") val deletedAt: String? = null,
    @SerialName("origin_device_id") val originDeviceId: String? = null,
)

@Serializable
enum class ScreenshotUploadStateDto {
    @SerialName("local_only") LOCAL_ONLY,
    @SerialName("eligible") ELIGIBLE,
    @SerialName("pending") PENDING,
    @SerialName("uploaded") UPLOADED,
    @SerialName("refused") REFUSED,
    @SerialName("purge_pending") PURGE_PENDING,
    @SerialName("purged") PURGED,
}

@Serializable
data class ScreenshotDto(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("span_id") val spanId: String? = null,
    @SerialName("captured_at") val capturedAt: String,
    @SerialName("file_name") val fileName: String = "",
    @SerialName("active_app_name") val activeAppName: String = "",
    @SerialName("upload_state") val uploadState: ScreenshotUploadStateDto = ScreenshotUploadStateDto.LOCAL_ONLY,
    @SerialName("blob_available") val blobAvailable: Boolean = false,
    @SerialName("blob_content_hash") val blobContentHash: String? = null,
    @SerialName("blob_byte_size") val blobByteSize: Long? = null,
    @SerialName("blob_uploaded_at") val blobUploadedAt: String? = null,
    @SerialName("blob_url") val blobUrl: String? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    @SerialName("server_revision") val serverRevision: Long = 0,
    @SerialName("deleted_at") val deletedAt: String? = null,
    @SerialName("origin_device_id") val originDeviceId: String? = null,
)

@Serializable
enum class PrivacyCategoryDto {
    @SerialName("none") NONE,
    @SerialName("secret") SECRET,
    @SerialName("private_email") PRIVATE_EMAIL,
    @SerialName("personal_chat") PERSONAL_CHAT,
    @SerialName("adult_material") ADULT_MATERIAL,
    @SerialName("financial") FINANCIAL,
    @SerialName("identity") IDENTITY,
    @SerialName("medical") MEDICAL,
    @SerialName("other_private") OTHER_PRIVATE,
}

@Serializable
data class VisionAnalysisDto(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("screenshot_id") val screenshotId: String,
    @SerialName("analyzed_at") val analyzedAt: String,
    val model: String = "",
    @SerialName("status_update") val statusUpdate: String = "",
    @SerialName("inferred_project") val inferredProject: String = "",
    @SerialName("inferred_task") val inferredTask: String = "",
    @SerialName("project_switch_detected") val projectSwitchDetected: Boolean = false,
    val confidence: Double = 0.0,
    val evidence: String = "",
    @SerialName("privacy_sensitive") val privacySensitive: Boolean = false,
    @SerialName("privacy_category") val privacyCategory: PrivacyCategoryDto = PrivacyCategoryDto.NONE,
    @SerialName("raw_response") val rawResponse: String? = null,
    @SerialName("raw_response_withheld") val rawResponseWithheld: Boolean = true,
    @SerialName("error_message") val errorMessage: String? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    @SerialName("server_revision") val serverRevision: Long = 0,
    @SerialName("deleted_at") val deletedAt: String? = null,
    @SerialName("origin_device_id") val originDeviceId: String? = null,
)

@Serializable
data class CensoredScreenshotDto(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("screenshot_id") val screenshotId: String,
    @SerialName("span_id") val spanId: String? = null,
    @SerialName("file_name") val fileName: String = "",
    @SerialName("active_app_name") val activeAppName: String = "",
    @SerialName("captured_at") val capturedAt: String,
    @SerialName("censored_at") val censoredAt: String,
    val model: String = "",
    val category: PrivacyCategoryDto = PrivacyCategoryDto.NONE,
    val reason: String = "",
    val confidence: Double = 0.0,
    @SerialName("deleted_local_file") val deletedLocalFile: Boolean = false,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    @SerialName("server_revision") val serverRevision: Long = 0,
    @SerialName("deleted_at") val deletedAt: String? = null,
    @SerialName("origin_device_id") val originDeviceId: String? = null,
)

@Serializable
enum class DevicePlatformDto {
    @SerialName("macos") MACOS,
    @SerialName("ios") IOS,
    @SerialName("android") ANDROID,
    @SerialName("web") WEB,
}

@Serializable
data class DeviceDto(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    @SerialName("user_id") val userId: String? = null,
    val platform: DevicePlatformDto,
    val name: String,
    @SerialName("app_version") val appVersion: String = "",
    @SerialName("os_version") val osVersion: String? = null,
    @SerialName("local_only_screenshots") val localOnlyScreenshots: Boolean = true,
    @SerialName("is_capture_agent") val isCaptureAgent: Boolean = false,
    @SerialName("last_seen_at") val lastSeenAt: String? = null,
    @SerialName("last_sync_revision") val lastSyncRevision: Long = 0,
    @SerialName("revoked_at") val revokedAt: String? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    @SerialName("server_revision") val serverRevision: Long = 0,
    @SerialName("deleted_at") val deletedAt: String? = null,
    @SerialName("origin_device_id") val originDeviceId: String? = null,
)

@Serializable
data class VisionSyncSettingsDto(
    @SerialName("analysis_enabled") val analysisEnabled: Boolean = false,
    @SerialName("notify_on_project_switch") val notifyOnProjectSwitch: Boolean = true,
    @SerialName("privacy_redaction_enabled") val privacyRedactionEnabled: Boolean = true,
    @SerialName("notify_on_censored_screenshot") val notifyOnCensoredScreenshot: Boolean = true,
    val provider: String = "openai",
    val model: String = "gpt-4o",
    @SerialName("base_url") val baseUrl: String? = null,
    val prompt: String? = null,
    @SerialName("confidence_threshold") val confidenceThreshold: Double = 0.72,
)

/**
 * The `settings` bucket is a discriminated union on `kind`. Rather than model it
 * as a sealed hierarchy on the wire (kotlinx.serialization's polymorphism would
 * need the discriminator to be absent from the body, which it is not), the two
 * shapes are parsed opportunistically from the raw JsonObject.
 */
@Serializable
data class UserSettingsDto(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    val kind: String = "user_settings",
    @SerialName("user_id") val userId: String,
    @SerialName("screenshot_interval_minutes") val screenshotIntervalMinutes: Double = 5.0,
    @SerialName("screenshot_capture_enabled") val screenshotCaptureEnabled: Boolean = true,
    @SerialName("pomodoro_work_minutes") val pomodoroWorkMinutes: Double = 25.0,
    @SerialName("pomodoro_break_minutes") val pomodoroBreakMinutes: Double = 5.0,
    @SerialName("local_only_screenshots") val localOnlyScreenshots: Boolean = true,
    @SerialName("retention_days") val retentionDays: Int = 0,
    @SerialName("idle_threshold_minutes") val idleThresholdMinutes: Double = 5.0,
    val vision: VisionSyncSettingsDto = VisionSyncSettingsDto(),
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    @SerialName("server_revision") val serverRevision: Long = 0,
    @SerialName("deleted_at") val deletedAt: String? = null,
    @SerialName("origin_device_id") val originDeviceId: String? = null,
)

@Serializable
data class WorkspacePolicyDto(
    val id: String,
    @SerialName("workspace_id") val workspaceId: String,
    val kind: String = "workspace_policy",
    @SerialName("screenshot_upload_allowed") val screenshotUploadAllowed: Boolean = false,
    @SerialName("sync_vision_raw_response") val syncVisionRawResponse: Boolean = false,
    @SerialName("default_local_only_screenshots") val defaultLocalOnlyScreenshots: Boolean = true,
    @SerialName("screenshot_retention_days") val screenshotRetentionDays: Int = 0,
    @SerialName("blob_retention_days") val blobRetentionDays: Int = 30,
    @SerialName("require_approval_before_export") val requireApprovalBeforeExport: Boolean = false,
    @SerialName("idle_threshold_minutes") val idleThresholdMinutes: Double = 5.0,
    @SerialName("locked_through") val lockedThrough: String? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    @SerialName("server_revision") val serverRevision: Long = 0,
    @SerialName("deleted_at") val deletedAt: String? = null,
    @SerialName("origin_device_id") val originDeviceId: String? = null,
)

@Serializable
data class ChangeSetDto(
    val clients: List<ClientDto> = emptyList(),
    val projects: List<ProjectDto> = emptyList(),
    val tickets: List<TicketDto> = emptyList(),
    @SerialName("time_spans") val timeSpans: List<TimeSpanDto> = emptyList(),
    val screenshots: List<ScreenshotDto> = emptyList(),
    @SerialName("vision_analyses") val visionAnalyses: List<VisionAnalysisDto> = emptyList(),
    @SerialName("censored_screenshots") val censoredScreenshots: List<CensoredScreenshotDto> = emptyList(),
    val devices: List<DeviceDto> = emptyList(),
    /** Discriminated union; split by `kind` at the mapper. */
    val settings: List<JsonObject> = emptyList(),
) {
    val isEmpty: Boolean
        get() = clients.isEmpty() && projects.isEmpty() && tickets.isEmpty() &&
            timeSpans.isEmpty() && screenshots.isEmpty() && visionAnalyses.isEmpty() &&
            censoredScreenshots.isEmpty() && devices.isEmpty() && settings.isEmpty()
}

@Serializable
data class ChangesResponseDto(
    val changes: ChangeSetDto,
    @SerialName("next_cursor") val nextCursor: Long,
    @SerialName("has_more") val hasMore: Boolean,
    @SerialName("tombstone_horizon_revision") val tombstoneHorizonRevision: Long = 0,
    @SerialName("server_time") val serverTime: String? = null,
)
