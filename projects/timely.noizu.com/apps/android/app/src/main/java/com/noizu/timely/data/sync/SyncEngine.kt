package com.noizu.timely.data.sync

import androidx.room.withTransaction
import com.noizu.timely.core.identity.Uuids
import com.noizu.timely.data.auth.SessionStore
import com.noizu.timely.data.local.PendingMutationEntity
import com.noizu.timely.data.local.ReviewItemEntity
import com.noizu.timely.data.local.SyncStateEntity
import com.noizu.timely.data.local.TimelyDatabase
import com.noizu.timely.data.local.toEntity
import com.noizu.timely.data.remote.TimelyApi
import com.noizu.timely.data.remote.dto.ChangeSetDto
import com.noizu.timely.data.remote.dto.MutationDto
import com.noizu.timely.data.remote.dto.MutationReasonDto
import com.noizu.timely.data.remote.dto.MutationRequestDto
import com.noizu.timely.data.remote.dto.MutationResultDto
import com.noizu.timely.data.remote.dto.MutationStatusDto
import com.noizu.timely.data.remote.dto.TimeSpanDto
import com.noizu.timely.data.remote.dto.UserSettingsDto
import com.noizu.timely.data.remote.dto.WorkspacePolicyDto
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.contentOrNull
import retrofit2.Response
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.min
import kotlin.math.pow
import kotlin.random.Random

/** What a sync attempt did, for the UI status line and for the worker's retry decision. */
sealed interface SyncOutcome {
    data class Success(
        val pulled: Int,
        val pushed: Int,
        val conflicts: Int,
        val reviewItems: Int,
    ) : SyncOutcome

    /** Retryable. The worker should back off and try again. */
    data class Retry(val reason: String, val cause: Throwable? = null) : SyncOutcome

    /**
     * The token is not usable and refresh did not fix it.
     *
     * NOT a failure of the app: local reads and writes carry on exactly as
     * before, and the queue is untouched. The user is shown a "sign in to sync"
     * affordance and nothing else changes (protocol 11.3).
     */
    data object AuthRequired : SyncOutcome

    /** Not signed in / no workspace yet. Nothing to do, not an error. */
    data object Idle : SyncOutcome

    /** The device slept past the tombstone horizon; a full resync is required. */
    data object ResyncRequired : SyncOutcome
}

/**
 * The sync loop (protocol 7).
 *
 * One instance, one mutex: protocol 7.2 requires at most one in-flight batch per
 * device, and a later mutation must never overtake an earlier one for the same
 * row. The periodic worker and a manual pull-to-refresh both land here, and
 * without the lock a hand-triggered refresh during a scheduled sync would
 * interleave two batches and reorder a create ahead of its update.
 */
@Singleton
class SyncEngine @Inject constructor(
    private val api: TimelyApi,
    private val db: TimelyDatabase,
    private val queue: PushQueue,
    private val tokenStore: SessionStore,
    private val json: Json,
) {

    private val mutex = Mutex()

    /**
     * Push then pull, which is the required order (protocol 7.2 "pull after
     * push"): the server produces side effects on rows the pusher never touched
     * -- auto-vivified projects, duplicate flags raised on *other* spans -- so
     * the push response alone never leaves the device consistent.
     */
    suspend fun sync(): SyncOutcome = mutex.withLock {
        val workspaceId = tokenStore.workspaceId() ?: return SyncOutcome.Idle

        val pushResult = runCatching { push(workspaceId) }
        pushResult.exceptionOrNull()?.let { return it.toOutcome() }
        val pushed = pushResult.getOrThrow()

        val pullResult = runCatching { pull(workspaceId) }
        pullResult.exceptionOrNull()?.let { return it.toOutcome() }
        val pulled = pullResult.getOrThrow()

        if (pulled.resyncRequired) return SyncOutcome.ResyncRequired

        db.syncState().get(workspaceId)?.let {
            db.syncState().upsert(
                it.copy(lastSuccessAt = System.currentTimeMillis(), lastError = null),
            )
        }

        SyncOutcome.Success(
            pulled = pulled.rowCount,
            pushed = pushed.dequeued,
            conflicts = pushed.conflicts,
            reviewItems = pulled.reviewItems + pushed.reviewItems,
        )
    }

    /** Manual pull-to-refresh. Same path, so there is only one sync implementation to trust. */
    suspend fun refresh(): SyncOutcome = sync()

    // =========================================================== PULL =======

    private data class PullResult(
        val rowCount: Int,
        val reviewItems: Int,
        val resyncRequired: Boolean,
    )

    /**
     * Cursor-paged pull (protocol 7.1).
     *
     * The rows and the watermark they cover are persisted in ONE transaction.
     * Persisting the cursor first loses data on a crash -- the rows are gone and
     * the device will never ask for that revision range again. Persisting the
     * rows first only costs a replay, and replay is harmless because apply is
     * idempotent. So: rows and cursor together, or neither.
     */
    private suspend fun pull(workspaceId: String): PullResult {
        var state = db.syncState().get(workspaceId)
            ?: SyncStateEntity(workspaceId = workspaceId).also { db.syncState().upsert(it) }

        if (state.resyncRequired) return PullResult(0, 0, resyncRequired = true)

        var cursor = state.cursor
        var totalRows = 0
        var totalReviewItems = 0
        var pages = 0

        while (true) {
            val response = api.pullChanges(
                workspaceId = workspaceId,
                since = cursor,
                limit = PAGE_LIMIT,
            ).orThrow()

            // The device slept past the retention window: it can no longer learn
            // which rows were deleted, so continuing would silently keep
            // resurrected rows forever. A full resync is the only correct move
            // (protocol 7.6), and it is the user's data, so it is surfaced
            // rather than performed silently.
            if (response.tombstoneHorizonRevision > cursor && cursor > 0) {
                db.syncState().upsert(
                    (db.syncState().get(workspaceId) ?: state).copy(
                        resyncRequired = true,
                        tombstoneHorizonRevision = response.tombstoneHorizonRevision,
                        lastError = "tombstone horizon ${response.tombstoneHorizonRevision} passed cursor $cursor",
                    ),
                )
                return PullResult(totalRows, totalReviewItems, resyncRequired = true)
            }

            val nextCursor = response.nextCursor
            var pageReviewItems = 0

            db.withTransaction {
                pageReviewItems = applyChanges(workspaceId, response.changes)
                db.syncState().upsert(
                    (db.syncState().get(workspaceId) ?: state).copy(
                        cursor = nextCursor,
                        tombstoneHorizonRevision = response.tombstoneHorizonRevision,
                        lastPullAt = System.currentTimeMillis(),
                    ),
                )
            }

            totalRows += response.changes.rowCount()
            totalReviewItems += pageReviewItems
            cursor = nextCursor
            state = db.syncState().get(workspaceId) ?: state
            pages++

            if (!response.hasMore) break
            // A server that always answers has_more=true would spin here
            // forever, holding the sync mutex and the user's battery.
            if (pages >= MAX_PAGES_PER_RUN) break
        }

        return PullResult(totalRows, totalReviewItems, resyncRequired = false)
    }

    /**
     * Apply a page.
     *
     * Tombstones are applied even for rows never seen, which is a no-op upsert
     * of a deleted row rather than a special case -- the row arrives with
     * `deleted_at` set and is stored that way.
     *
     * A row with unpushed local edits keeps the local value visible in the UI
     * (`pendingLocal` stays true), while the server's version is written
     * underneath so `base_revision` can be reported accurately on the next push
     * (protocol 7.1). The local edit is still in the queue and still wins the
     * display until it is answered.
     */
    private suspend fun applyChanges(workspaceId: String, changes: ChangeSetDto): Int {
        val pendingTargets = db.pendingMutations().all(workspaceId)
            .filterNot { it.deadLettered }
            .map { it.targetId }
            .toSet()

        // For rows with an unpushed local edit, the server's row is NOT written
        // over the user's. See [adoptEnvelope].
        db.clients().upsertAll(
            changes.clients.map { dto ->
                val incoming = dto.toEntity(pendingLocal = dto.id in pendingTargets)
                if (dto.id !in pendingTargets) incoming
                else db.clients().byId(dto.id)?.adoptEnvelope(incoming) ?: incoming
            },
        )
        db.projects().upsertAll(
            changes.projects.map { dto ->
                val incoming = dto.toEntity(pendingLocal = dto.id in pendingTargets)
                if (dto.id !in pendingTargets) incoming
                else db.projects().byId(dto.id)?.adoptEnvelope(incoming) ?: incoming
            },
        )
        db.tickets().upsertAll(
            changes.tickets.map { dto ->
                val incoming = dto.toEntity(pendingLocal = dto.id in pendingTargets)
                if (dto.id !in pendingTargets) incoming
                else db.tickets().byId(dto.id)?.adoptEnvelope(incoming) ?: incoming
            },
        )
        db.timeSpans().upsertAll(
            changes.timeSpans.map { dto ->
                val incoming = dto.toEntity(pendingLocal = dto.id in pendingTargets)
                if (dto.id !in pendingTargets) incoming
                else db.timeSpans().byId(dto.id)?.adoptEnvelope(incoming) ?: incoming
            },
        )
        db.screenshots().upsertAll(changes.screenshots.map { it.toEntity() })
        db.visionAnalyses().upsertAll(changes.visionAnalyses.map { it.toEntity() })
        db.censoredScreenshots().upsertAll(changes.censoredScreenshots.map { it.toEntity() })
        db.devices().upsertAll(changes.devices.map { it.toEntity() })

        // `settings` is a discriminated union on `kind`, split here.
        val userSettings = mutableListOf<UserSettingsDto>()
        val policies = mutableListOf<WorkspacePolicyDto>()
        for (raw in changes.settings) {
            when (raw["kind"]?.jsonPrimitive?.contentOrNull) {
                "workspace_policy" -> runCatching {
                    json.decodeFromJsonElement(WorkspacePolicyDto.serializer(), raw)
                }.getOrNull()?.let(policies::add)
                // Absent `kind` is treated as user_settings, which is what the
                // contract's default says it is.
                else -> runCatching {
                    json.decodeFromJsonElement(UserSettingsDto.serializer(), raw)
                }.getOrNull()?.let(userSettings::add)
            }
        }
        if (userSettings.isNotEmpty()) {
            db.settings().upsertUserSettings(
                userSettings.map { dto ->
                    val incoming = dto.toEntity(pendingLocal = dto.id in pendingTargets)
                    if (dto.id !in pendingTargets) incoming
                    else db.settings().userSettingsOnce(workspaceId)
                        ?.takeIf { it.id == dto.id }?.adoptEnvelope(incoming) ?: incoming
                },
            )
        }
        if (policies.isNotEmpty()) db.settings().upsertPolicy(policies.map { it.toEntity() })

        return harvestReviewItems(workspaceId, changes.timeSpans)
    }

    /**
     * Turn server-raised `review_reasons` into review items.
     *
     * `suspected_duplicate` and `billing_overlap` are the two that matter and
     * they are NEVER auto-resolved. Both mean "these hours may be billed twice",
     * and a client that silently picks a winner is how a customer gets invoiced
     * wrong. The server deliberately does not merge, trim, or hide either row
     * (protocol 8.3), and neither does this.
     */
    private suspend fun harvestReviewItems(workspaceId: String, spans: List<TimeSpanDto>): Int {
        val items = mutableListOf<ReviewItemEntity>()
        val now = System.currentTimeMillis()
        for (span in spans) {
            for (reason in span.reviewReasons) {
                // Deterministic id so the same reason arriving on a later page
                // updates the row instead of duplicating the user's to-do list.
                val id = Uuids.v5(
                    NAMESPACE_REVIEW,
                    "${span.id}:${reason.code.name}:${reason.raisedAt}:${reason.relatedId.orEmpty()}",
                ).let(Uuids::format)
                items += ReviewItemEntity(
                    id = id,
                    workspaceId = workspaceId,
                    entity = "time_span",
                    targetId = span.id,
                    code = reason.code.name.lowercase(),
                    detail = reason.detail,
                    relatedId = reason.relatedId,
                    raisedAt = reason.raisedAt,
                    raisedBy = reason.raisedBy.name.lowercase(),
                    resolution = reason.resolution.name.lowercase(),
                    resolvedAt = reason.resolvedAt,
                    createdAt = now,
                )
            }
        }
        if (items.isNotEmpty()) db.reviewItems().upsertAll(items)
        return items.count { it.resolvedAt == null }
    }

    // =========================================================== PUSH =======

    // ------------------------------------------- local-edit preservation ----
    //
    // Protocol 7.1: "Applying a change to a row with unpushed local edits: the
    // local edit wins in the UI until it is pushed and answered. Clients MUST
    // keep the server's version alongside (a shadow) so `base_revision` can be
    // reported accurately."
    //
    // So a pulled row does NOT overwrite a row the user has edited but not yet
    // synced. The local content stays visible and the SERVER ENVELOPE is adopted
    // underneath it -- which is the half of the shadow that has a job to do,
    // since `base_revision` is read from `serverRevision`. Without this, a pull
    // that lands before the queue drains silently reverts the user's edit on
    // screen while the mutation is still sitting in the outbox: the change looks
    // lost, the user redoes it, and now there are two.
    //
    // `deletedAt` is taken from the server unconditionally. A tombstone is
    // absorbing (matrix row 2) and beats a concurrent local edit, so it is the
    // one field the local copy may not win.
    //
    // LIMITATION, stated rather than hidden: this keeps the server's revision,
    // not the server's field VALUES. That is everything `base_revision` needs,
    // but it means there is no stored "theirs" side to render a field-level
    // conflict diff from. If a merge UI is ever wanted, that needs real shadow
    // columns.

    private fun com.noizu.timely.data.local.ClientEntity.adoptEnvelope(
        server: com.noizu.timely.data.local.ClientEntity,
    ) = copy(
        serverRevision = server.serverRevision,
        deletedAt = server.deletedAt,
        originDeviceId = server.originDeviceId,
        canonicalName = server.canonicalName,
        pendingLocal = true,
    )

    private fun com.noizu.timely.data.local.ProjectEntity.adoptEnvelope(
        server: com.noizu.timely.data.local.ProjectEntity,
    ) = copy(
        serverRevision = server.serverRevision,
        deletedAt = server.deletedAt,
        originDeviceId = server.originDeviceId,
        canonicalName = server.canonicalName,
        pendingLocal = true,
    )

    private fun com.noizu.timely.data.local.TicketEntity.adoptEnvelope(
        server: com.noizu.timely.data.local.TicketEntity,
    ) = copy(
        serverRevision = server.serverRevision,
        deletedAt = server.deletedAt,
        originDeviceId = server.originDeviceId,
        canonicalName = server.canonicalName,
        pendingLocal = true,
    )

    private fun com.noizu.timely.data.local.TimeSpanEntity.adoptEnvelope(
        server: com.noizu.timely.data.local.TimeSpanEntity,
    ) = copy(
        serverRevision = server.serverRevision,
        deletedAt = server.deletedAt,
        originDeviceId = server.originDeviceId,
        updatedAtEffective = server.updatedAtEffective,
        // Server-raised review flags are the server's to set, not the user's to
        // overwrite: a `suspected_duplicate` raised while the user was editing
        // must still reach them.
        reviewReasonsJson = server.reviewReasonsJson,
        lockedAt = server.lockedAt,
        pendingLocal = true,
    )

    private fun com.noizu.timely.data.local.UserSettingsEntity.adoptEnvelope(
        server: com.noizu.timely.data.local.UserSettingsEntity,
    ) = copy(
        serverRevision = server.serverRevision,
        deletedAt = server.deletedAt,
        originDeviceId = server.originDeviceId,
        pendingLocal = true,
    )

    // =========================================================== PUSH =======

    private data class PushResult(val dequeued: Int, val conflicts: Int, val reviewItems: Int)

    /**
     * Drain the queue, oldest first, one batch at a time.
     *
     * Only transport errors, 5xx and 429 are retried; `applied`, `conflict` and
     * `rejected` are all terminal and all dequeue (protocol 7.2). A mutation
     * absent from `results` was not processed and stays queued -- treating
     * absence as success is how an edit disappears with no trace.
     */
    private suspend fun push(workspaceId: String): PushResult {
        val deviceId = tokenStore.deviceId() ?: return PushResult(0, 0, 0)
        val currentUser = tokenStore.userId()

        var dequeued = 0
        var conflicts = 0
        var reviewItems = 0
        var batches = 0

        while (batches < MAX_BATCHES_PER_RUN) {
            val raw = queue.nextBatch(workspaceId, PushQueue.MAX_BATCH)
            if (raw.isEmpty()) break

            // An account switch must not flush one user's queued edits under
            // another's token. These rows are held, not dropped: the data still
            // belongs to whoever authored it.
            val batch = queue.capToByteBudget(
                raw.filter { it.userId == null || it.userId == currentUser },
            )
            if (batch.isEmpty()) break

            val request = MutationRequestDto(
                workspaceId = workspaceId,
                deviceId = deviceId,
                atomic = false,
                mutations = batch.map { it.toDto() },
            )

            val response = api.pushMutations(request).orThrow()
            val byId = response.results.associateBy { it.mutationId }

            val toDequeue = mutableListOf<String>()
            for (row in batch) {
                val result = byId[row.mutationId]
                if (result == null) {
                    // Not processed. Stays queued, deliberately.
                    continue
                }
                when (result.status) {
                    MutationStatusDto.APPLIED -> {
                        toDequeue += row.mutationId
                        applyServerEcho(workspaceId, result)
                        clearPendingFlag(row)
                    }
                    MutationStatusDto.CONFLICT -> {
                        conflicts++
                        toDequeue += row.mutationId
                        reviewItems += handleConflict(workspaceId, row, result)
                        clearPendingFlag(row)
                    }
                    MutationStatusDto.REJECTED -> {
                        toDequeue += row.mutationId
                        reviewItems += handleRejection(workspaceId, row, result)
                        clearPendingFlag(row)
                    }
                }
            }

            queue.dequeue(toDequeue)
            dequeued += toDequeue.size
            batches++

            // Nothing moved: every mutation in the batch was absent from
            // results. Retrying the same batch immediately would spin.
            if (toDequeue.isEmpty()) {
                queue.recordFailure(batch.map { it.mutationId }, "absent from results")
                break
            }
        }

        if (dequeued > 0) {
            db.syncState().get(workspaceId)?.let {
                db.syncState().upsert(it.copy(lastPushAt = System.currentTimeMillis()))
            }
        }
        return PushResult(dequeued, conflicts, reviewItems)
    }

    /**
     * Write back the server's version of the row we just changed, plus any side
     * effects (auto-vivified clients and projects, cascade tombstones).
     */
    private suspend fun applyServerEcho(workspaceId: String, result: MutationResultDto) {
        val rows = buildList {
            // `entity_kind` comes off the envelope. A row that arrives with no
            // kind is not guessed at -- see applyEchoRow.
            result.entity?.let { add(result.entityKind?.wireName() to it) }
            result.sideEffects.forEach { add(it.entity.wireName() to it.row) }
        }
        if (rows.isEmpty()) return
        db.withTransaction {
            for ((kind, row) in rows) applyEchoRow(workspaceId, kind, row)
        }
    }

    private suspend fun applyEchoRow(workspaceId: String, kind: String?, row: JsonObject) {
        runCatching {
            when (kind) {
                "client" -> db.clients().upsert(json.decodeFromJsonElement(com.noizu.timely.data.remote.dto.ClientDto.serializer(), row).toEntity())
                "project" -> db.projects().upsert(json.decodeFromJsonElement(com.noizu.timely.data.remote.dto.ProjectDto.serializer(), row).toEntity())
                "ticket" -> db.tickets().upsert(json.decodeFromJsonElement(com.noizu.timely.data.remote.dto.TicketDto.serializer(), row).toEntity())
                "time_span" -> {
                    val dto = json.decodeFromJsonElement(TimeSpanDto.serializer(), row)
                    db.timeSpans().upsert(dto.toEntity())
                    harvestReviewItems(workspaceId, listOf(dto))
                }
                "screenshot" -> db.screenshots().upsertAll(
                    listOf(json.decodeFromJsonElement(com.noizu.timely.data.remote.dto.ScreenshotDto.serializer(), row).toEntity()),
                )
                "vision_analysis" -> db.visionAnalyses().upsertAll(
                    listOf(json.decodeFromJsonElement(com.noizu.timely.data.remote.dto.VisionAnalysisDto.serializer(), row).toEntity()),
                )
                "censored_screenshot" -> db.censoredScreenshots().upsertAll(
                    listOf(json.decodeFromJsonElement(com.noizu.timely.data.remote.dto.CensoredScreenshotDto.serializer(), row).toEntity()),
                )
                "user_settings" -> db.settings().upsertUserSettings(
                    json.decodeFromJsonElement(UserSettingsDto.serializer(), row).toEntity(),
                )
                // Includes the null case: a row with no `entity_kind` is SKIPPED,
                // never guessed at. An earlier version of this method inferred
                // the kind from which fields the row happened to carry, which
                // distinguished project from ticket by the presence of
                // `client_name` vs `project_name` -- a guess that would have
                // started silently writing rows into the wrong table the moment
                // either entity gained a field. The next full pull delivers the
                // row through the normal path anyway, so skipping costs nothing
                // and guessing could cost a table.
                else -> Unit
            }
        }
        // A row shape this client cannot decode is a forward-compatible server
        // change, not a reason to fail the whole sync.
    }

    /**
     * A conflict is applied back to local state, never dropped.
     *
     * `tombstoned`: the delete won and is absorbing (matrix row 2), so the
     * server's tombstone is what the device keeps -- the local edit loses and
     * the row goes away.
     *
     * `duplicate_name`: the name maps to a different id than the one we minted
     * (matrix rows 12 and 13). This needs a reference rewrite or a user-chosen
     * merge, so it becomes a review item rather than being guessed at.
     */
    private suspend fun handleConflict(
        workspaceId: String,
        row: PendingMutationEntity,
        result: MutationResultDto,
    ): Int {
        applyServerEcho(workspaceId, result)

        val code = result.reason?.name?.lowercase() ?: "conflict"
        val needsHuman = result.reason == MutationReasonDto.DUPLICATE_NAME
        if (!needsHuman && result.reason == MutationReasonDto.TOMBSTONED) {
            // Nothing for the user to decide: delete wins, unconditionally.
            return 0
        }

        db.reviewItems().upsert(
            ReviewItemEntity(
                id = Uuids.v5(NAMESPACE_REVIEW, "conflict:${row.mutationId}").let(Uuids::format),
                workspaceId = workspaceId,
                // The server's word where it gave one, else the kind we queued
                // it under. `entity_kind` rides the envelope precisely so this
                // works when `entity` is null.
                entity = result.entityKind?.wireName() ?: row.entity,
                targetId = row.targetId,
                code = code,
                detail = result.message,
                relatedId = null,
                raisedAt = nowIso(),
                raisedBy = "server",
                resolution = "pending",
                resolvedAt = null,
                createdAt = System.currentTimeMillis(),
            ),
        )
        return 1
    }

    /**
     * A rejection is terminal for the mutation but must be visible to the user.
     *
     * `span_reopen_forbidden` and `locked_day` in particular mean the user's
     * edit did not happen. Dropping it silently would leave the UI showing an
     * edit the server refused.
     */
    private suspend fun handleRejection(
        workspaceId: String,
        row: PendingMutationEntity,
        result: MutationResultDto,
    ): Int {
        applyServerEcho(workspaceId, result)

        db.reviewItems().upsert(
            ReviewItemEntity(
                id = Uuids.v5(NAMESPACE_REVIEW, "rejected:${row.mutationId}").let(Uuids::format),
                workspaceId = workspaceId,
                // A `rejected` result carries no row at all, so `entity_kind` on
                // the envelope is the only thing that says what was refused.
                entity = result.entityKind?.wireName() ?: row.entity,
                targetId = row.targetId,
                code = result.reason?.name?.lowercase() ?: "rejected",
                detail = result.message ?: "The server rejected this change.",
                relatedId = null,
                raisedAt = nowIso(),
                raisedBy = "server",
                resolution = "pending",
                resolvedAt = null,
                createdAt = System.currentTimeMillis(),
            ),
        )
        return 1
    }

    private suspend fun clearPendingFlag(row: PendingMutationEntity) {
        // Only clear if this was the last queued edit for that row; an earlier
        // create answered while a later update is still queued must keep the
        // row marked pending.
        val stillQueued = db.pendingMutations().all(row.workspaceId)
            .any { it.targetId == row.targetId && it.mutationId != row.mutationId && !it.deadLettered }
        if (stillQueued) return
        when (row.entity) {
            "client" -> db.clients().markPending(row.targetId, false)
            "project" -> db.projects().markPending(row.targetId, false)
            "ticket" -> db.tickets().markPending(row.targetId, false)
            "time_span" -> db.timeSpans().markPending(row.targetId, false)
        }
    }

    private fun PendingMutationEntity.toDto() = MutationDto(
        mutationId = mutationId,
        entity = entity.toEntityKind(),
        op = op.toMutationOp(),
        baseRevision = baseRevision,
        payload = json.decodeFromString(JsonObject.serializer(), payloadJson),
    )

    // `inferKindFromRow` lived here. It guessed an entity kind from which fields
    // a row happened to carry, because the mutation result echoed a row with no
    // discriminator. The server now sends `entity_kind` on the result envelope,
    // so the guess is gone rather than kept as a fallback -- a dead heuristic in
    // a sync write path is how a future entity ends up in the wrong table.

    // ========================================================== helpers =====

    private fun <T> Response<T>.orThrow(): T {
        if (isSuccessful) return body() ?: throw SyncHttpException(code(), "empty body")
        throw SyncHttpException(code(), errorBody()?.string())
    }

    private fun Throwable.toOutcome(): SyncOutcome = when {
        this is SyncHttpException && code == 401 -> SyncOutcome.AuthRequired
        this is SyncHttpException && code == 403 -> SyncOutcome.AuthRequired
        this is SyncHttpException && (code == 429 || code >= 500) ->
            SyncOutcome.Retry("http $code", this)
        this is SyncHttpException ->
            // 4xx other than 401/403/429 is a client bug; retrying will not fix
            // it, but the queue is left intact so nothing is lost.
            SyncOutcome.Retry("http $code", this)
        this is IOException -> SyncOutcome.Retry("transport", this)
        else -> SyncOutcome.Retry(this::class.simpleName ?: "unknown", this)
    }

    private fun nowIso(): String =
        java.time.format.DateTimeFormatter.ISO_INSTANT.format(java.time.Instant.now())

    private fun ChangeSetDto.rowCount(): Int =
        clients.size + projects.size + tickets.size + timeSpans.size + screenshots.size +
            visionAnalyses.size + censoredScreenshots.size + devices.size + settings.size

    companion object {
        const val PAGE_LIMIT = 500
        private const val MAX_PAGES_PER_RUN = 200
        private const val MAX_BATCHES_PER_RUN = 50

        /** Stable namespace for locally derived review-item ids. */
        private val NAMESPACE_REVIEW =
            java.util.UUID.fromString("6ba7b812-9dad-11d1-80b4-00c04fd430c8")

        /**
         * Full-jitter exponential backoff (protocol 7.2): base 2s, cap 5m.
         *
         * Full jitter rather than plain exponential because every device in a
         * workspace loses connectivity at the same moment -- an office wifi
         * blip -- and un-jittered backoff marches them all back in lockstep,
         * turning one outage into a repeating thundering herd.
         */
        fun backoffMillis(attempt: Int, random: Random = Random.Default): Long {
            val exponential = 2_000.0 * 2.0.pow(attempt.coerceAtMost(30))
            val capped = min(exponential, 300_000.0)
            return random.nextLong(1, capped.toLong().coerceAtLeast(2))
        }
    }
}

class SyncHttpException(val code: Int, val bodySnippet: String?) :
    IOException("sync HTTP $code${bodySnippet?.let { ": ${it.take(300)}" }.orEmpty()}")
