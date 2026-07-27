package com.noizu.timely.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

/**
 * Note the upsert strategy throughout: `OnConflictStrategy.REPLACE`.
 *
 * Sync is at-least-once, so the same server row legitimately arrives twice (a
 * retried page, an overlapping cursor after a resume). Replace makes that a
 * no-op instead of a crash. The *ordering* guarantee that makes replace safe
 * lives in the sync engine, which only writes a row whose `server_revision` is
 * at least the one already stored.
 */

@Dao
interface ClientDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(rows: List<ClientEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(row: ClientEntity)

    @Query("SELECT * FROM clients WHERE workspaceId = :workspaceId AND deletedAt IS NULL AND mergedIntoId IS NULL ORDER BY name COLLATE NOCASE")
    fun observeActive(workspaceId: String): Flow<List<ClientEntity>>

    @Query("SELECT * FROM clients WHERE id = :id")
    suspend fun byId(id: String): ClientEntity?

    @Query("SELECT * FROM clients WHERE workspaceId = :workspaceId AND canonicalName = :canonicalName LIMIT 1")
    suspend fun byCanonicalName(workspaceId: String, canonicalName: String): ClientEntity?

    @Query("SELECT serverRevision FROM clients WHERE id = :id")
    suspend fun revisionOf(id: String): Long?

    @Query("UPDATE clients SET pendingLocal = :pending WHERE id = :id")
    suspend fun markPending(id: String, pending: Boolean)
}

@Dao
interface ProjectDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(rows: List<ProjectEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(row: ProjectEntity)

    @Query("SELECT * FROM projects WHERE workspaceId = :workspaceId AND deletedAt IS NULL AND mergedIntoId IS NULL ORDER BY name COLLATE NOCASE")
    fun observeActive(workspaceId: String): Flow<List<ProjectEntity>>

    @Query("SELECT * FROM projects WHERE id = :id")
    suspend fun byId(id: String): ProjectEntity?

    @Query("SELECT serverRevision FROM projects WHERE id = :id")
    suspend fun revisionOf(id: String): Long?

    @Query("UPDATE projects SET pendingLocal = :pending WHERE id = :id")
    suspend fun markPending(id: String, pending: Boolean)
}

@Dao
interface TicketDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(rows: List<TicketEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(row: TicketEntity)

    @Query("SELECT * FROM tickets WHERE workspaceId = :workspaceId AND deletedAt IS NULL AND mergedIntoId IS NULL ORDER BY name COLLATE NOCASE")
    fun observeActive(workspaceId: String): Flow<List<TicketEntity>>

    @Query("SELECT * FROM tickets WHERE projectId = :projectId AND deletedAt IS NULL ORDER BY name COLLATE NOCASE")
    fun observeForProject(projectId: String): Flow<List<TicketEntity>>

    @Query("SELECT * FROM tickets WHERE id = :id")
    suspend fun byId(id: String): TicketEntity?

    @Query("SELECT serverRevision FROM tickets WHERE id = :id")
    suspend fun revisionOf(id: String): Long?

    @Query("UPDATE tickets SET pendingLocal = :pending WHERE id = :id")
    suspend fun markPending(id: String, pending: Boolean)
}

@Dao
interface TimeSpanDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(rows: List<TimeSpanEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(row: TimeSpanEntity)

    @Update
    suspend fun update(row: TimeSpanEntity)

    /** A day, in the user's zone: the caller resolves the boundaries to epoch seconds. */
    @Query(
        """
        SELECT * FROM time_spans
        WHERE workspaceId = :workspaceId
          AND deletedAt IS NULL
          AND startEpochSeconds >= :fromEpochSeconds
          AND startEpochSeconds < :toEpochSeconds
        ORDER BY startEpochSeconds ASC, id ASC
        """,
    )
    fun observeRange(
        workspaceId: String,
        fromEpochSeconds: Long,
        toEpochSeconds: Long,
    ): Flow<List<TimeSpanEntity>>

    @Query(
        """
        SELECT * FROM time_spans
        WHERE workspaceId = :workspaceId AND deletedAt IS NULL
          AND (reviewState IN ('needs_review', 'disputed') OR reviewReasonsJson LIKE '%"resolution":"pending"%')
        ORDER BY startEpochSeconds DESC
        """,
    )
    fun observeNeedingReview(workspaceId: String): Flow<List<TimeSpanEntity>>

    /** An open span is one with no end. The idle prompt resolves these. */
    @Query("SELECT * FROM time_spans WHERE workspaceId = :workspaceId AND deletedAt IS NULL AND end IS NULL ORDER BY startEpochSeconds DESC")
    fun observeOpen(workspaceId: String): Flow<List<TimeSpanEntity>>

    @Query("SELECT * FROM time_spans WHERE id = :id")
    suspend fun byId(id: String): TimeSpanEntity?

    @Query("SELECT * FROM time_spans WHERE id = :id")
    fun observeById(id: String): Flow<TimeSpanEntity?>

    @Query("SELECT serverRevision FROM time_spans WHERE id = :id")
    suspend fun revisionOf(id: String): Long?

    @Query("UPDATE time_spans SET pendingLocal = :pending WHERE id = :id")
    suspend fun markPending(id: String, pending: Boolean)

    @Query(
        """
        SELECT * FROM time_spans
        WHERE workspaceId = :workspaceId AND deletedAt IS NULL
          AND startEpochSeconds >= :fromEpochSeconds AND startEpochSeconds < :toEpochSeconds
        ORDER BY startEpochSeconds ASC
        """,
    )
    suspend fun rangeOnce(
        workspaceId: String,
        fromEpochSeconds: Long,
        toEpochSeconds: Long,
    ): List<TimeSpanEntity>
}

@Dao
interface ScreenshotDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(rows: List<ScreenshotEntity>)

    @Query("SELECT * FROM screenshots WHERE spanId = :spanId AND deletedAt IS NULL ORDER BY capturedAt")
    fun observeForSpan(spanId: String): Flow<List<ScreenshotEntity>>

    @Query("SELECT COUNT(*) FROM screenshots WHERE workspaceId = :workspaceId AND deletedAt IS NULL")
    fun observeCount(workspaceId: String): Flow<Int>
}

@Dao
interface VisionAnalysisDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(rows: List<VisionAnalysisEntity>)

    @Query("SELECT * FROM vision_analyses WHERE screenshotId IN (:screenshotIds) AND deletedAt IS NULL")
    suspend fun forScreenshots(screenshotIds: List<String>): List<VisionAnalysisEntity>
}

@Dao
interface CensoredScreenshotDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(rows: List<CensoredScreenshotEntity>)

    @Query("SELECT COUNT(*) FROM censored_screenshots WHERE workspaceId = :workspaceId AND deletedAt IS NULL")
    fun observeCount(workspaceId: String): Flow<Int>
}

@Dao
interface DeviceDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(rows: List<DeviceEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(row: DeviceEntity)

    @Query("SELECT * FROM devices WHERE workspaceId = :workspaceId AND deletedAt IS NULL ORDER BY lastSeenAt DESC")
    fun observeAll(workspaceId: String): Flow<List<DeviceEntity>>

    @Query("SELECT * FROM devices WHERE id = :id")
    suspend fun byId(id: String): DeviceEntity?
}

@Dao
interface SettingsDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertUserSettings(rows: List<UserSettingsEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertUserSettings(row: UserSettingsEntity)

    @Query("SELECT * FROM user_settings WHERE workspaceId = :workspaceId LIMIT 1")
    fun observeUserSettings(workspaceId: String): Flow<UserSettingsEntity?>

    @Query("SELECT * FROM user_settings WHERE workspaceId = :workspaceId LIMIT 1")
    suspend fun userSettingsOnce(workspaceId: String): UserSettingsEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertPolicy(rows: List<WorkspacePolicyEntity>)

    @Query("SELECT * FROM workspace_policy WHERE workspaceId = :workspaceId LIMIT 1")
    fun observePolicy(workspaceId: String): Flow<WorkspacePolicyEntity?>

    @Query("SELECT * FROM workspace_policy WHERE workspaceId = :workspaceId LIMIT 1")
    suspend fun policyOnce(workspaceId: String): WorkspacePolicyEntity?
}

@Dao
interface PendingMutationDao {

    @Insert
    suspend fun enqueue(row: PendingMutationEntity): Long

    /**
     * The next batch to push, in authored order.
     *
     * Order is not cosmetic: a create and the update that follows it must reach
     * the server in that sequence, or the update lands as `unknown_entity` and
     * the user's edit is silently dropped.
     */
    @Query(
        """
        SELECT * FROM pending_mutations
        WHERE workspaceId = :workspaceId AND deadLettered = 0
        ORDER BY seq ASC
        LIMIT :limit
        """,
    )
    suspend fun nextBatch(workspaceId: String, limit: Int): List<PendingMutationEntity>

    @Query("SELECT * FROM pending_mutations WHERE mutationId = :mutationId")
    suspend fun byMutationId(mutationId: String): PendingMutationEntity?

    @Query("DELETE FROM pending_mutations WHERE mutationId IN (:mutationIds)")
    suspend fun deleteByMutationIds(mutationIds: List<String>)

    @Query(
        """
        UPDATE pending_mutations
        SET attempts = attempts + 1, lastAttemptAt = :at, lastError = :error
        WHERE mutationId IN (:mutationIds)
        """,
    )
    suspend fun recordFailure(mutationIds: List<String>, at: Long, error: String?)

    @Query(
        """
        UPDATE pending_mutations
        SET deadLettered = 1, deadLetterReason = :reason, lastAttemptAt = :at
        WHERE mutationId = :mutationId
        """,
    )
    suspend fun deadLetter(mutationId: String, reason: String, at: Long)

    @Query("UPDATE pending_mutations SET baseRevision = :baseRevision WHERE mutationId = :mutationId")
    suspend fun rebase(mutationId: String, baseRevision: Long?)

    @Query("SELECT COUNT(*) FROM pending_mutations WHERE workspaceId = :workspaceId AND deadLettered = 0")
    fun observePendingCount(workspaceId: String): Flow<Int>

    @Query("SELECT COUNT(*) FROM pending_mutations WHERE workspaceId = :workspaceId AND deadLettered = 0")
    suspend fun pendingCount(workspaceId: String): Int

    @Query("SELECT * FROM pending_mutations WHERE deadLettered = 1 AND workspaceId = :workspaceId ORDER BY seq DESC")
    fun observeDeadLettered(workspaceId: String): Flow<List<PendingMutationEntity>>

    @Query("SELECT * FROM pending_mutations WHERE workspaceId = :workspaceId ORDER BY seq ASC")
    suspend fun all(workspaceId: String): List<PendingMutationEntity>

    /**
     * Only ever called on an explicit account switch. Sign-out does NOT clear
     * the queue -- a token expiring overnight must not delete a day's work.
     */
    @Query("DELETE FROM pending_mutations WHERE workspaceId = :workspaceId")
    suspend fun clearForWorkspace(workspaceId: String)
}

@Dao
interface SyncStateDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(row: SyncStateEntity)

    @Query("SELECT * FROM sync_state WHERE workspaceId = :workspaceId")
    suspend fun get(workspaceId: String): SyncStateEntity?

    @Query("SELECT * FROM sync_state WHERE workspaceId = :workspaceId")
    fun observe(workspaceId: String): Flow<SyncStateEntity?>

    @Query("UPDATE sync_state SET cursor = :cursor, lastPullAt = :at WHERE workspaceId = :workspaceId")
    suspend fun advanceCursor(workspaceId: String, cursor: Long, at: Long)
}

@Dao
interface ReviewItemDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(rows: List<ReviewItemEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(row: ReviewItemEntity)

    @Query("SELECT * FROM review_items WHERE workspaceId = :workspaceId AND resolvedAt IS NULL ORDER BY createdAt DESC")
    fun observeOpen(workspaceId: String): Flow<List<ReviewItemEntity>>

    @Query("SELECT COUNT(*) FROM review_items WHERE workspaceId = :workspaceId AND resolvedAt IS NULL")
    fun observeOpenCount(workspaceId: String): Flow<Int>

    @Query("UPDATE review_items SET resolution = :resolution, resolvedAt = :at WHERE id = :id")
    suspend fun resolve(id: String, resolution: String, at: String)

    @Query("SELECT * FROM review_items WHERE workspaceId = :workspaceId ORDER BY createdAt DESC")
    suspend fun all(workspaceId: String): List<ReviewItemEntity>
}

// The write path that has to be atomic -- the optimistic row and its queued
// mutation must land together, or a crash between them either loses the user's
// edit (row written, mutation lost) or pushes a change the UI never showed
// (mutation written, row lost) -- is expressed with `db.withTransaction { }` at
// the repository layer rather than with a @Transaction DAO method, because it
// spans two DAOs.
