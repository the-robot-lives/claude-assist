package com.noizu.timely.data.local

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * The local mirror.
 *
 * Room is the UI's only source of truth. Screens never read from the network;
 * they observe these tables, and the sync engine is the only writer of
 * server-derived state. That is what makes the app fully usable offline --
 * there is no code path where a stale token can make a screen go blank.
 *
 * Every table carries the sync envelope columns (`server_revision`,
 * `deleted_at`, `origin_device_id`) because the conflict rules in section 8.2
 * are expressed in terms of them. `deleted_at` is a tombstone: rows are never
 * hard-deleted by sync, only marked, so that a delete replayed after a local
 * edit still resolves deterministically.
 *
 * `pending_*` columns hold local, not-yet-acknowledged edits. A row can be both
 * server-derived and locally dirty at once; the UI shows the local value and a
 * "not yet synced" affordance.
 */

@Entity(
    tableName = "clients",
    indices = [Index(value = ["workspaceId", "canonicalName"], unique = true)],
)
data class ClientEntity(
    @PrimaryKey val id: String,
    val workspaceId: String,
    val name: String,
    val canonicalName: String,
    val notes: String = "",
    val autoCreated: Boolean = false,
    val mergedIntoId: String? = null,
    val reviewState: String = "unreviewed",
    val createdAt: String,
    val updatedAt: String,
    val serverRevision: Long = 0,
    val deletedAt: String? = null,
    val originDeviceId: String? = null,
    /** True while a local create/edit for this row is still in the push queue. */
    val pendingLocal: Boolean = false,
)

@Entity(
    tableName = "projects",
    indices = [
        Index(value = ["workspaceId", "clientId", "canonicalName"], unique = true),
        Index(value = ["clientId"]),
    ],
)
data class ProjectEntity(
    @PrimaryKey val id: String,
    val workspaceId: String,
    val name: String,
    val canonicalName: String,
    val clientId: String? = null,
    val clientName: String = "",
    val notes: String = "",
    val autoCreated: Boolean = false,
    val mergedIntoId: String? = null,
    val reviewState: String = "unreviewed",
    val createdAt: String,
    val updatedAt: String,
    val serverRevision: Long = 0,
    val deletedAt: String? = null,
    val originDeviceId: String? = null,
    val pendingLocal: Boolean = false,
)

@Entity(
    tableName = "tickets",
    indices = [
        Index(value = ["workspaceId", "projectId", "canonicalName"], unique = true),
        Index(value = ["projectId"]),
    ],
)
data class TicketEntity(
    @PrimaryKey val id: String,
    val workspaceId: String,
    val name: String,
    val canonicalName: String,
    val clientId: String? = null,
    val projectId: String? = null,
    val clientName: String = "",
    val projectName: String = "",
    val notes: String = "",
    val autoCreated: Boolean = false,
    val mergedIntoId: String? = null,
    val reviewState: String = "unreviewed",
    val createdAt: String,
    val updatedAt: String,
    val serverRevision: Long = 0,
    val deletedAt: String? = null,
    val originDeviceId: String? = null,
    val pendingLocal: Boolean = false,
)

@Entity(
    tableName = "time_spans",
    indices = [
        Index(value = ["workspaceId", "startEpochSeconds"]),
        Index(value = ["projectId"]),
        Index(value = ["reviewState"]),
    ],
)
data class TimeSpanEntity(
    @PrimaryKey val id: String,
    val workspaceId: String,
    val title: String = "",
    val clientId: String? = null,
    val projectId: String? = null,
    val ticketId: String? = null,
    val clientName: String = "",
    val projectName: String = "",
    val ticketName: String = "",
    val start: String,
    val end: String? = null,
    /**
     * Denormalized epoch seconds for the two things the timeline actually does:
     * order by time, and filter to a day. Sorting on the ISO string would be
     * correct only for `Z`-suffixed instants of identical precision, which is
     * exactly the assumption a server upgrade quietly breaks.
     */
    val startEpochSeconds: Long,
    val endEpochSeconds: Long? = null,
    val source: String = "manual",
    val isBillable: Boolean = false,
    val notes: String = "",
    val reviewState: String = "unreviewed",
    /** `ReviewReasonDto` list, stored as the raw JSON array. */
    val reviewReasonsJson: String = "[]",
    val derivedFromSpanIdsJson: String = "[]",
    val lockedAt: String? = null,
    val createdAt: String,
    val updatedAt: String,
    val updatedAtEffective: String? = null,
    val serverRevision: Long = 0,
    val deletedAt: String? = null,
    val originDeviceId: String? = null,
    val pendingLocal: Boolean = false,
)

@Entity(
    tableName = "screenshots",
    indices = [Index(value = ["spanId"]), Index(value = ["workspaceId", "capturedAt"])],
)
data class ScreenshotEntity(
    @PrimaryKey val id: String,
    val workspaceId: String,
    val spanId: String? = null,
    val capturedAt: String,
    val fileName: String = "",
    val activeAppName: String = "",
    val uploadState: String = "local_only",
    val blobAvailable: Boolean = false,
    val blobContentHash: String? = null,
    val blobByteSize: Long? = null,
    val blobUploadedAt: String? = null,
    val blobUrl: String? = null,
    val createdAt: String,
    val updatedAt: String,
    val serverRevision: Long = 0,
    val deletedAt: String? = null,
    val originDeviceId: String? = null,
)

@Entity(tableName = "vision_analyses", indices = [Index(value = ["screenshotId"])])
data class VisionAnalysisEntity(
    @PrimaryKey val id: String,
    val workspaceId: String,
    val screenshotId: String,
    val analyzedAt: String,
    val model: String = "",
    val statusUpdate: String = "",
    val inferredProject: String = "",
    val inferredTask: String = "",
    val projectSwitchDetected: Boolean = false,
    val confidence: Double = 0.0,
    val evidence: String = "",
    val privacySensitive: Boolean = false,
    val privacyCategory: String = "none",
    val rawResponseWithheld: Boolean = true,
    val errorMessage: String? = null,
    val createdAt: String,
    val updatedAt: String,
    val serverRevision: Long = 0,
    val deletedAt: String? = null,
    val originDeviceId: String? = null,
)

@Entity(tableName = "censored_screenshots", indices = [Index(value = ["screenshotId"])])
data class CensoredScreenshotEntity(
    @PrimaryKey val id: String,
    val workspaceId: String,
    val screenshotId: String,
    val spanId: String? = null,
    val fileName: String = "",
    val activeAppName: String = "",
    val capturedAt: String,
    val censoredAt: String,
    val model: String = "",
    val category: String = "none",
    val reason: String = "",
    val confidence: Double = 0.0,
    val deletedLocalFile: Boolean = false,
    val createdAt: String,
    val updatedAt: String,
    val serverRevision: Long = 0,
    val deletedAt: String? = null,
    val originDeviceId: String? = null,
)

@Entity(tableName = "devices")
data class DeviceEntity(
    @PrimaryKey val id: String,
    val workspaceId: String,
    val userId: String? = null,
    val platform: String,
    val name: String,
    val appVersion: String = "",
    val osVersion: String? = null,
    val localOnlyScreenshots: Boolean = true,
    val isCaptureAgent: Boolean = false,
    val lastSeenAt: String? = null,
    val lastSyncRevision: Long = 0,
    val revokedAt: String? = null,
    val createdAt: String,
    val updatedAt: String,
    val serverRevision: Long = 0,
    val deletedAt: String? = null,
    val originDeviceId: String? = null,
)

@Entity(tableName = "user_settings")
data class UserSettingsEntity(
    @PrimaryKey val id: String,
    val workspaceId: String,
    val userId: String,
    val screenshotIntervalMinutes: Double = 5.0,
    val screenshotCaptureEnabled: Boolean = true,
    val pomodoroWorkMinutes: Double = 25.0,
    val pomodoroBreakMinutes: Double = 5.0,
    val localOnlyScreenshots: Boolean = true,
    val retentionDays: Int = 0,
    val idleThresholdMinutes: Double = 5.0,
    val visionAnalysisEnabled: Boolean = false,
    val visionPrivacyRedactionEnabled: Boolean = true,
    val visionModel: String = "",
    val visionConfidenceThreshold: Double = 0.72,
    val createdAt: String,
    val updatedAt: String,
    val serverRevision: Long = 0,
    val deletedAt: String? = null,
    val originDeviceId: String? = null,
    val pendingLocal: Boolean = false,
)

@Entity(tableName = "workspace_policy")
data class WorkspacePolicyEntity(
    @PrimaryKey val id: String,
    val workspaceId: String,
    val screenshotUploadAllowed: Boolean = false,
    val syncVisionRawResponse: Boolean = false,
    val defaultLocalOnlyScreenshots: Boolean = true,
    val screenshotRetentionDays: Int = 0,
    val blobRetentionDays: Int = 30,
    val requireApprovalBeforeExport: Boolean = false,
    val idleThresholdMinutes: Double = 5.0,
    val lockedThrough: String? = null,
    val createdAt: String,
    val updatedAt: String,
    val serverRevision: Long = 0,
    val deletedAt: String? = null,
    val originDeviceId: String? = null,
)

// ---------------------------------------------------------------- sync ----

/**
 * The push queue.
 *
 * Ordered (by [seq]), at-least-once, and idempotent on replay because
 * [mutationId] is minted on the client before the first attempt and never
 * changes. A retry after an ambiguous failure re-sends the *same* id, and the
 * server answers `replayed: true` with the original outcome instead of applying
 * the change twice (protocol 7.4).
 *
 * [userId] records the principal the mutation was authored under. A queue built
 * by one user must never be flushed under another's token after an account
 * switch; that is a data-leak bug, not a merge conflict.
 */
@Entity(
    tableName = "pending_mutations",
    indices = [Index(value = ["mutationId"], unique = true), Index(value = ["workspaceId", "seq"])],
)
data class PendingMutationEntity(
    @PrimaryKey(autoGenerate = true) val seq: Long = 0,
    val mutationId: String,
    val workspaceId: String,
    val userId: String?,
    val entity: String,
    val op: String,
    /** The row this mutation targets, so the UI can mark it pending. */
    val targetId: String,
    /**
     * The `server_revision` the edit was made against, or null for a create.
     * The server compares it and answers `stale_write` if the row moved on.
     */
    val baseRevision: Long? = null,
    val payloadJson: String,
    val createdAt: Long,
    val attempts: Int = 0,
    val lastAttemptAt: Long? = null,
    val lastError: String? = null,
    /**
     * Set when the server answered `rejected` with a terminal reason. The row
     * stays in the table so the user can be shown what was dropped and why,
     * rather than the edit evaporating.
     */
    val deadLettered: Boolean = false,
    val deadLetterReason: String? = null,
)

/** One row per workspace. The pull cursor and its bookkeeping. */
@Entity(tableName = "sync_state")
data class SyncStateEntity(
    @PrimaryKey val workspaceId: String,
    /** `server_revision` high-water mark. The next pull asks for `since=cursor`. */
    val cursor: Long = 0,
    val tombstoneHorizonRevision: Long = 0,
    val lastPullAt: Long? = null,
    val lastPushAt: Long? = null,
    val lastSuccessAt: Long? = null,
    val lastError: String? = null,
    /**
     * Set when the server's tombstone horizon has advanced past our cursor: the
     * device slept through the retention window and can no longer learn which
     * rows were deleted. The only correct response is a full resync (protocol
     * 7.6), not a silent continue.
     */
    val resyncRequired: Boolean = false,
)

/**
 * Conflicts and server-raised concerns that a human has to look at.
 *
 * `suspected_duplicate` and `billing_overlap` land here and are NEVER
 * auto-resolved: both mean "these hours may be billed twice", and a client
 * silently picking a winner is how a customer gets invoiced wrong. The device
 * surfaces them and the user decides.
 */
@Entity(tableName = "review_items", indices = [Index(value = ["workspaceId", "resolvedAt"])])
data class ReviewItemEntity(
    @PrimaryKey val id: String,
    val workspaceId: String,
    val entity: String,
    val targetId: String,
    /** `ReviewReasonCodeDto`, or a mutation `reason` for a push conflict. */
    val code: String,
    val detail: String? = null,
    val relatedId: String? = null,
    val raisedAt: String,
    val raisedBy: String = "server",
    val resolution: String = "pending",
    val resolvedAt: String? = null,
    val createdAt: Long,
)
