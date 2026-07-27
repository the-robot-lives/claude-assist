package com.noizu.timely.data.local

import com.noizu.timely.core.time.InstantSerializer
import com.noizu.timely.data.remote.dto.CensoredScreenshotDto
import com.noizu.timely.data.remote.dto.ClientDto
import com.noizu.timely.data.remote.dto.DeviceDto
import com.noizu.timely.data.remote.dto.ProjectDto
import com.noizu.timely.data.remote.dto.ReviewReasonDto
import com.noizu.timely.data.remote.dto.ScreenshotDto
import com.noizu.timely.data.remote.dto.TicketDto
import com.noizu.timely.data.remote.dto.TimeSpanDto
import com.noizu.timely.data.remote.dto.UserSettingsDto
import com.noizu.timely.data.remote.dto.VisionAnalysisDto
import com.noizu.timely.data.remote.dto.WorkspacePolicyDto
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json

/**
 * Wire to local.
 *
 * Enums are flattened to their wire strings rather than stored as ordinals. An
 * ordinal is a promise that the enum's *declaration order* never changes, which
 * is a promise nobody remembers making when they alphabetize a list six months
 * later -- and the failure mode is every stored row silently changing meaning.
 */
private val mapperJson = Json { ignoreUnknownKeys = true; encodeDefaults = true }

private fun epochSecondsOf(raw: String?): Long? =
    raw?.let { runCatching { InstantSerializer.parse(it).epochSecond }.getOrNull() }

fun ClientDto.toEntity(pendingLocal: Boolean = false) = ClientEntity(
    id = id,
    workspaceId = workspaceId,
    name = name,
    canonicalName = canonicalName,
    notes = notes,
    autoCreated = autoCreated,
    mergedIntoId = mergedIntoId,
    reviewState = reviewState.wire(),
    createdAt = createdAt,
    updatedAt = updatedAt,
    serverRevision = serverRevision,
    deletedAt = deletedAt,
    originDeviceId = originDeviceId,
    pendingLocal = pendingLocal,
)

fun ProjectDto.toEntity(pendingLocal: Boolean = false) = ProjectEntity(
    id = id,
    workspaceId = workspaceId,
    name = name,
    canonicalName = canonicalName,
    clientId = clientId,
    clientName = clientName,
    notes = notes,
    autoCreated = autoCreated,
    mergedIntoId = mergedIntoId,
    reviewState = reviewState.wire(),
    createdAt = createdAt,
    updatedAt = updatedAt,
    serverRevision = serverRevision,
    deletedAt = deletedAt,
    originDeviceId = originDeviceId,
    pendingLocal = pendingLocal,
)

fun TicketDto.toEntity(pendingLocal: Boolean = false) = TicketEntity(
    id = id,
    workspaceId = workspaceId,
    name = name,
    canonicalName = canonicalName,
    clientId = clientId,
    projectId = projectId,
    clientName = clientName,
    projectName = projectName,
    notes = notes,
    autoCreated = autoCreated,
    mergedIntoId = mergedIntoId,
    reviewState = reviewState.wire(),
    createdAt = createdAt,
    updatedAt = updatedAt,
    serverRevision = serverRevision,
    deletedAt = deletedAt,
    originDeviceId = originDeviceId,
    pendingLocal = pendingLocal,
)

fun TimeSpanDto.toEntity(pendingLocal: Boolean = false) = TimeSpanEntity(
    id = id,
    workspaceId = workspaceId,
    title = title,
    clientId = clientId,
    projectId = projectId,
    ticketId = ticketId,
    clientName = clientName,
    projectName = projectName,
    ticketName = ticketName,
    start = start,
    end = end,
    // A span whose start will not parse is a server bug, but dropping the whole
    // sync page over one row is worse than storing it at epoch 0 where it is
    // visible and obviously wrong.
    startEpochSeconds = epochSecondsOf(start) ?: 0L,
    endEpochSeconds = epochSecondsOf(end),
    source = source.wire(),
    isBillable = isBillable,
    notes = notes,
    reviewState = reviewState.wire(),
    reviewReasonsJson = mapperJson.encodeToString(
        ListSerializer(ReviewReasonDto.serializer()),
        reviewReasons,
    ),
    derivedFromSpanIdsJson = mapperJson.encodeToString(
        ListSerializer(String.serializer()),
        derivedFromSpanIds,
    ),
    lockedAt = lockedAt,
    createdAt = createdAt,
    updatedAt = updatedAt,
    updatedAtEffective = updatedAtEffective,
    serverRevision = serverRevision,
    deletedAt = deletedAt,
    originDeviceId = originDeviceId,
    pendingLocal = pendingLocal,
)

fun TimeSpanEntity.reviewReasons(): List<ReviewReasonDto> =
    runCatching {
        mapperJson.decodeFromString(ListSerializer(ReviewReasonDto.serializer()), reviewReasonsJson)
    }.getOrDefault(emptyList())

fun ScreenshotDto.toEntity() = ScreenshotEntity(
    id = id,
    workspaceId = workspaceId,
    spanId = spanId,
    capturedAt = capturedAt,
    fileName = fileName,
    activeAppName = activeAppName,
    uploadState = uploadState.wire(),
    blobAvailable = blobAvailable,
    blobContentHash = blobContentHash,
    blobByteSize = blobByteSize,
    blobUploadedAt = blobUploadedAt,
    blobUrl = blobUrl,
    createdAt = createdAt,
    updatedAt = updatedAt,
    serverRevision = serverRevision,
    deletedAt = deletedAt,
    originDeviceId = originDeviceId,
)

fun VisionAnalysisDto.toEntity() = VisionAnalysisEntity(
    id = id,
    workspaceId = workspaceId,
    screenshotId = screenshotId,
    analyzedAt = analyzedAt,
    model = model,
    statusUpdate = statusUpdate,
    inferredProject = inferredProject,
    inferredTask = inferredTask,
    projectSwitchDetected = projectSwitchDetected,
    confidence = confidence,
    evidence = evidence,
    privacySensitive = privacySensitive,
    privacyCategory = privacyCategory.wire(),
    // `raw_response` is deliberately NOT persisted. It is the model's verbatim
    // reading of a screenshot and is the most sensitive field in the protocol;
    // the server withholds it by default and a companion has no use for it.
    rawResponseWithheld = rawResponseWithheld,
    errorMessage = errorMessage,
    createdAt = createdAt,
    updatedAt = updatedAt,
    serverRevision = serverRevision,
    deletedAt = deletedAt,
    originDeviceId = originDeviceId,
)

fun CensoredScreenshotDto.toEntity() = CensoredScreenshotEntity(
    id = id,
    workspaceId = workspaceId,
    screenshotId = screenshotId,
    spanId = spanId,
    fileName = fileName,
    activeAppName = activeAppName,
    capturedAt = capturedAt,
    censoredAt = censoredAt,
    model = model,
    category = category.wire(),
    reason = reason,
    confidence = confidence,
    deletedLocalFile = deletedLocalFile,
    createdAt = createdAt,
    updatedAt = updatedAt,
    serverRevision = serverRevision,
    deletedAt = deletedAt,
    originDeviceId = originDeviceId,
)

fun DeviceDto.toEntity() = DeviceEntity(
    id = id,
    workspaceId = workspaceId,
    userId = userId,
    platform = platform.wire(),
    name = name,
    appVersion = appVersion,
    osVersion = osVersion,
    localOnlyScreenshots = localOnlyScreenshots,
    isCaptureAgent = isCaptureAgent,
    lastSeenAt = lastSeenAt,
    lastSyncRevision = lastSyncRevision,
    revokedAt = revokedAt,
    createdAt = createdAt,
    updatedAt = updatedAt,
    serverRevision = serverRevision,
    deletedAt = deletedAt,
    originDeviceId = originDeviceId,
)

fun UserSettingsDto.toEntity(pendingLocal: Boolean = false) = UserSettingsEntity(
    id = id,
    workspaceId = workspaceId,
    userId = userId,
    screenshotIntervalMinutes = screenshotIntervalMinutes,
    screenshotCaptureEnabled = screenshotCaptureEnabled,
    pomodoroWorkMinutes = pomodoroWorkMinutes,
    pomodoroBreakMinutes = pomodoroBreakMinutes,
    localOnlyScreenshots = localOnlyScreenshots,
    retentionDays = retentionDays,
    idleThresholdMinutes = idleThresholdMinutes,
    visionAnalysisEnabled = vision.analysisEnabled,
    visionPrivacyRedactionEnabled = vision.privacyRedactionEnabled,
    visionModel = vision.model,
    visionConfidenceThreshold = vision.confidenceThreshold,
    createdAt = createdAt,
    updatedAt = updatedAt,
    serverRevision = serverRevision,
    deletedAt = deletedAt,
    originDeviceId = originDeviceId,
    pendingLocal = pendingLocal,
)

fun WorkspacePolicyDto.toEntity() = WorkspacePolicyEntity(
    id = id,
    workspaceId = workspaceId,
    screenshotUploadAllowed = screenshotUploadAllowed,
    syncVisionRawResponse = syncVisionRawResponse,
    defaultLocalOnlyScreenshots = defaultLocalOnlyScreenshots,
    screenshotRetentionDays = screenshotRetentionDays,
    blobRetentionDays = blobRetentionDays,
    requireApprovalBeforeExport = requireApprovalBeforeExport,
    idleThresholdMinutes = idleThresholdMinutes,
    lockedThrough = lockedThrough,
    createdAt = createdAt,
    updatedAt = updatedAt,
    serverRevision = serverRevision,
    deletedAt = deletedAt,
    originDeviceId = originDeviceId,
)

/**
 * The wire spelling of an enum constant.
 *
 * Read off the `@SerialName` that kotlinx.serialization already uses, so the
 * stored string and the transmitted string cannot drift apart -- there is no
 * second hand-written table to forget to update.
 */
internal fun Enum<*>.wire(): String {
    val field = javaClass.getDeclaredField(name)
    val annotation = field.getAnnotation(kotlinx.serialization.SerialName::class.java)
    return annotation?.value ?: name.lowercase()
}
