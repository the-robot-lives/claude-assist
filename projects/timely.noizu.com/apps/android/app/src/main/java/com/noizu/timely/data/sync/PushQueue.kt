package com.noizu.timely.data.sync

import androidx.room.withTransaction
import com.noizu.timely.core.identity.Uuids
import com.noizu.timely.data.local.PendingMutationEntity
import com.noizu.timely.data.local.TimelyDatabase
import com.noizu.timely.data.local.wire
import com.noizu.timely.data.privacy.ScreenshotGate
import com.noizu.timely.data.remote.dto.EntityKindDto
import com.noizu.timely.data.remote.dto.MutationOpDto
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

/**
 * The durable, ordered, at-least-once push queue (protocol 7.2).
 *
 * Everything the user changes goes in here first and is pushed later. There is
 * deliberately no "write straight through when online" fast path: a second code
 * path would be exercised only on a good network, so the offline path -- the one
 * that actually needs to be reliable -- would be the less tested of the two.
 */
@Singleton
class PushQueue @Inject constructor(
    private val db: TimelyDatabase,
    private val json: Json,
) {

    /**
     * Enqueue a mutation, minting its `mutation_id` here and now.
     *
     * The id is minted **before the first attempt** and never changes across
     * retries. That is the whole idempotency story: a request that times out
     * after the server committed it is retried with the same id, and the server
     * replays the recorded outcome instead of applying the change twice
     * (protocol 9). Minting a fresh id per attempt would turn every flaky
     * network into duplicate time entries.
     *
     * @param baseRevision the `server_revision` the edit was made against, or
     *   null for a create. Advisory for LWW, decisive for the closed-span guard.
     */
    suspend fun enqueue(
        workspaceId: String,
        userId: String?,
        entity: EntityKindDto,
        op: MutationOpDto,
        targetId: String,
        payload: JsonObject,
        baseRevision: Long? = null,
        now: Long = System.currentTimeMillis(),
    ): PendingMutationEntity {
        // Structural privacy gate. Throws rather than returning false: a caller
        // reaching here with a screenshot has a logic error, and "silently did
        // nothing" is how a privacy regression ships unnoticed.
        ScreenshotGate.require(entity)

        val row = PendingMutationEntity(
            mutationId = Uuids.v7String(now),
            workspaceId = workspaceId,
            userId = userId,
            entity = entity.wireName(),
            op = op.wireName(),
            targetId = targetId,
            baseRevision = baseRevision,
            payloadJson = json.encodeToString(JsonObject.serializer(), payload),
            createdAt = now,
        )
        db.pendingMutations().enqueue(row)
        return row
    }

    /**
     * Enqueue several mutations as one unit of local work.
     *
     * Used by split and merge, which are N creates plus M deletes that only make
     * sense together (protocol 7.3). The transaction is local durability; the
     * server-side all-or-nothing comes from pushing them with `atomic: true`.
     */
    suspend fun enqueueAll(rows: List<PendingMutationEntity>) {
        rows.forEach { ScreenshotGate.require(it.entity.toEntityKind()) }
        db.withTransaction {
            rows.forEach { db.pendingMutations().enqueue(it) }
        }
    }

    suspend fun nextBatch(workspaceId: String, limit: Int = MAX_BATCH): List<PendingMutationEntity> =
        db.pendingMutations().nextBatch(workspaceId, limit)

    /**
     * Trim a batch to the byte cap.
     *
     * 200 mutations is the count cap, but a handful of spans with long notes can
     * blow past 1 MiB well before that, and the server answers 413 for the whole
     * batch -- which retries forever at the same size unless the client shrinks
     * it. Always leaves at least one mutation, so an oversized single mutation
     * still gets sent (and gets a terminal rejection) rather than wedging the
     * queue head forever.
     */
    fun capToByteBudget(batch: List<PendingMutationEntity>): List<PendingMutationEntity> {
        var budget = MAX_BATCH_BYTES
        val out = mutableListOf<PendingMutationEntity>()
        for (row in batch) {
            val size = row.payloadJson.toByteArray(Charsets.UTF_8).size + ENVELOPE_OVERHEAD_BYTES
            if (out.isNotEmpty() && size > budget) break
            budget -= size
            out += row
        }
        return out
    }

    suspend fun byMutationId(mutationId: String) = db.pendingMutations().byMutationId(mutationId)

    suspend fun dequeue(mutationIds: List<String>) {
        if (mutationIds.isNotEmpty()) db.pendingMutations().deleteByMutationIds(mutationIds)
    }

    suspend fun recordFailure(mutationIds: List<String>, error: String?, now: Long = System.currentTimeMillis()) {
        if (mutationIds.isNotEmpty()) db.pendingMutations().recordFailure(mutationIds, now, error)
    }

    suspend fun deadLetter(mutationId: String, reason: String, now: Long = System.currentTimeMillis()) {
        db.pendingMutations().deadLetter(mutationId, reason, now)
    }

    suspend fun rebase(mutationId: String, baseRevision: Long?) {
        db.pendingMutations().rebase(mutationId, baseRevision)
    }

    fun observePendingCount(workspaceId: String): Flow<Int> =
        db.pendingMutations().observePendingCount(workspaceId)

    suspend fun pendingCount(workspaceId: String): Int =
        db.pendingMutations().pendingCount(workspaceId)

    fun observeDeadLettered(workspaceId: String) =
        db.pendingMutations().observeDeadLettered(workspaceId)

    /**
     * Only on an explicit account switch.
     *
     * Never on sign-out and never on a failed refresh: an access token aging out
     * overnight must not delete the user's unsynced workday (protocol 11.2
     * step 3). The `userId` recorded on each row is what lets a later sign-in
     * decide whether the queue is still the same principal's to flush.
     */
    suspend fun clearForAccountSwitch(workspaceId: String) {
        db.pendingMutations().clearForWorkspace(workspaceId)
    }

    companion object {
        /** Protocol 7.2: at most 200 mutations per batch, 50 when atomic. */
        const val MAX_BATCH = 200
        const val MAX_ATOMIC_BATCH = 50
        const val MAX_BATCH_BYTES = 1024 * 1024
        private const val ENVELOPE_OVERHEAD_BYTES = 256

        /**
         * Give up retrying and dead-letter.
         *
         * Only reached for errors the protocol says are retryable, so a mutation
         * that has failed this many times is failing for a reason retrying will
         * not fix. It stays in the table, flagged, so the user can be told what
         * did not sync -- an edit that evaporates silently is worse than one
         * that reports itself stuck.
         */
        const val MAX_ATTEMPTS = 12
    }
}

/** The `@SerialName` spelling, so stored and transmitted strings cannot drift. */
internal fun EntityKindDto.wireName(): String = wire()

internal fun MutationOpDto.wireName(): String = wire()

internal fun String.toEntityKind(): EntityKindDto =
    EntityKindDto.entries.first { it.wireName() == this }

internal fun String.toMutationOp(): MutationOpDto =
    MutationOpDto.entries.first { it.wireName() == this }
