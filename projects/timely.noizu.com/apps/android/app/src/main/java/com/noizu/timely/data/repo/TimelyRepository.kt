package com.noizu.timely.data.repo

import androidx.room.withTransaction
import com.noizu.timely.core.identity.Canon
import com.noizu.timely.core.identity.TaxonomyIds
import com.noizu.timely.core.identity.Uuids
import com.noizu.timely.core.identity.canon
import com.noizu.timely.core.time.toWireString
import com.noizu.timely.data.auth.SessionStore
import com.noizu.timely.data.local.ClientEntity
import com.noizu.timely.data.local.PendingMutationEntity
import com.noizu.timely.data.local.ProjectEntity
import com.noizu.timely.data.local.ReviewItemEntity
import com.noizu.timely.data.local.TicketEntity
import com.noizu.timely.data.local.TimeSpanEntity
import com.noizu.timely.data.local.TimelyDatabase
import com.noizu.timely.data.local.UserSettingsEntity
import com.noizu.timely.data.local.reviewReasons
import com.noizu.timely.data.privacy.ScreenshotGate
import com.noizu.timely.data.remote.dto.EntityKindDto
import com.noizu.timely.data.remote.dto.MutationOpDto
import com.noizu.timely.data.sync.PushQueue
import com.noizu.timely.data.sync.wireName
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.add
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Every user-visible write goes through here.
 *
 * The invariant that matters most in this file: **a local write never consults
 * the auth state.** Not the token's presence, not its expiry, not
 * `reauth_required`. The row is written to Room and the mutation is queued, and
 * that is the whole operation as far as the user is concerned. Whether the
 * device can currently talk to the server is the sync engine's problem, and a
 * problem that resolves itself later.
 *
 * Gating writes on token freshness is the single most common way an
 * offline-capable app stops being one: it works in every test, on every desk,
 * and fails on a plane, which is exactly when a time tracker is being used.
 */
@Singleton
class TimelyRepository @Inject constructor(
    private val db: TimelyDatabase,
    private val queue: PushQueue,
    private val tokenStore: SessionStore,
    private val json: Json,
) {

    private fun workspaceId(): String? = tokenStore.workspaceId()

    // ======================================================== observation ===

    fun observeDay(day: LocalDate, zone: ZoneId): Flow<List<TimeSpanEntity>> {
        val workspaceId = workspaceId().orEmpty()
        val from = day.atStartOfDay(zone).toEpochSecond()
        val to = day.plusDays(1).atStartOfDay(zone).toEpochSecond()
        return db.timeSpans().observeRange(workspaceId, from, to)
    }

    fun observeNeedingReview(): Flow<List<TimeSpanEntity>> =
        db.timeSpans().observeNeedingReview(workspaceId().orEmpty())

    fun observeOpenSpans(): Flow<List<TimeSpanEntity>> =
        db.timeSpans().observeOpen(workspaceId().orEmpty())

    fun observeClients(): Flow<List<ClientEntity>> =
        db.clients().observeActive(workspaceId().orEmpty())

    fun observeProjects(): Flow<List<ProjectEntity>> =
        db.projects().observeActive(workspaceId().orEmpty())

    fun observeTickets(): Flow<List<TicketEntity>> =
        db.tickets().observeActive(workspaceId().orEmpty())

    fun observeReviewItems(): Flow<List<ReviewItemEntity>> =
        db.reviewItems().observeOpen(workspaceId().orEmpty())

    fun observeReviewItemCount(): Flow<Int> =
        db.reviewItems().observeOpenCount(workspaceId().orEmpty())

    fun observePendingCount(): Flow<Int> =
        queue.observePendingCount(workspaceId().orEmpty())

    fun observeSettings(): Flow<UserSettingsEntity?> =
        db.settings().observeUserSettings(workspaceId().orEmpty())

    fun observePolicy() = db.settings().observePolicy(workspaceId().orEmpty())

    fun observeSyncState() = db.syncState().observe(workspaceId().orEmpty())

    fun observeDeadLettered() = queue.observeDeadLettered(workspaceId().orEmpty())

    suspend fun spanById(id: String) = db.timeSpans().byId(id)

    // ============================================================= writes ===

    /**
     * Manual time entry.
     *
     * Names are vivified into deterministic ids here rather than being sent as
     * bare strings, so a phone and a Mac that both type "Acme / Redesign" while
     * offline converge on one row instead of two (protocol 3.2). A name that
     * canons to empty yields a null id -- "no reference", not a row named ""
     * -- which is why the OrNull variants are the ones used.
     */
    suspend fun createManualSpan(
        title: String,
        clientName: String,
        projectName: String,
        ticketName: String,
        start: Instant,
        end: Instant?,
        isBillable: Boolean,
        notes: String = "",
    ): String? {
        val workspaceId = workspaceId() ?: return null
        val now = Instant.now()
        val spanId = Uuids.v7String(start.toEpochMilli())

        val clientId = TaxonomyIds.clientIdOrNull(workspaceId, clientName)
        val projectId = TaxonomyIds.projectIdOrNull(workspaceId, clientName, projectName)
        val ticketId = TaxonomyIds.ticketIdOrNull(workspaceId, clientName, projectName, ticketName)

        val span = TimeSpanEntity(
            id = spanId,
            workspaceId = workspaceId,
            title = title,
            clientId = clientId,
            projectId = projectId,
            ticketId = ticketId,
            clientName = clientName,
            projectName = projectName,
            ticketName = ticketName,
            start = start.toWireString(),
            end = end?.toWireString(),
            startEpochSeconds = start.epochSecond,
            endEpochSeconds = end?.epochSecond,
            source = "manual",
            isBillable = isBillable,
            notes = notes,
            // A hand-entered span is the user's own assertion, so it starts as
            // reviewed rather than needing a human to confirm what a human just
            // typed.
            reviewState = "reviewed",
            createdAt = now.toWireString(),
            updatedAt = now.toWireString(),
            updatedAtEffective = now.toWireString(),
            pendingLocal = true,
        )

        val mutations = mutableListOf<PendingMutationEntity>()

        // Vivify the taxonomy alongside the span. The server auto-creates these
        // too, but sending them explicitly means the local UI can show the
        // project name immediately instead of waiting for a pull.
        vivifyClient(workspaceId, clientName, clientId, now)?.let { (row, mutation) ->
            db.clients().upsert(row); mutations += mutation
        }
        vivifyProject(workspaceId, clientName, projectName, clientId, projectId, now)?.let { (row, mutation) ->
            db.projects().upsert(row); mutations += mutation
        }
        vivifyTicket(workspaceId, clientName, projectName, ticketName, clientId, projectId, ticketId, now)
            ?.let { (row, mutation) -> db.tickets().upsert(row); mutations += mutation }

        mutations += pendingMutation(
            workspaceId = workspaceId,
            entity = EntityKindDto.TIME_SPAN,
            op = MutationOpDto.CREATE,
            targetId = spanId,
            payload = span.toCreatePayload(),
        )

        db.withTransaction {
            db.timeSpans().upsert(span)
            queue.enqueueAll(mutations)
        }
        return spanId
    }

    /** Retitle, reassign, toggle billable, adjust boundaries, resolve an idle gap. */
    suspend fun updateSpan(
        spanId: String,
        title: String? = null,
        clientName: String? = null,
        projectName: String? = null,
        ticketName: String? = null,
        start: Instant? = null,
        end: Instant? = null,
        clearEnd: Boolean = false,
        isBillable: Boolean? = null,
        notes: String? = null,
        reviewState: String? = null,
    ): Boolean {
        val workspaceId = workspaceId() ?: return false
        val existing = db.timeSpans().byId(spanId) ?: return false
        val now = Instant.now()

        val newClientName = clientName ?: existing.clientName
        val newProjectName = projectName ?: existing.projectName
        val newTicketName = ticketName ?: existing.ticketName

        val reassigned = clientName != null || projectName != null || ticketName != null
        val newClientId = if (reassigned) {
            TaxonomyIds.clientIdOrNull(workspaceId, newClientName)
        } else {
            existing.clientId
        }
        val newProjectId = if (reassigned) {
            TaxonomyIds.projectIdOrNull(workspaceId, newClientName, newProjectName)
        } else {
            existing.projectId
        }
        val newTicketId = if (reassigned) {
            TaxonomyIds.ticketIdOrNull(workspaceId, newClientName, newProjectName, newTicketName)
        } else {
            existing.ticketId
        }

        val newEnd = when {
            clearEnd -> null
            end != null -> end
            else -> existing.endEpochSeconds?.let { Instant.ofEpochSecond(it) }
        }

        val updated = existing.copy(
            title = title ?: existing.title,
            clientId = newClientId,
            projectId = newProjectId,
            ticketId = newTicketId,
            clientName = newClientName,
            projectName = newProjectName,
            ticketName = newTicketName,
            start = start?.toWireString() ?: existing.start,
            startEpochSeconds = start?.epochSecond ?: existing.startEpochSeconds,
            end = newEnd?.toWireString(),
            endEpochSeconds = newEnd?.epochSecond,
            isBillable = isBillable ?: existing.isBillable,
            notes = notes ?: existing.notes,
            reviewState = reviewState ?: existing.reviewState,
            updatedAt = now.toWireString(),
            updatedAtEffective = now.toWireString(),
            pendingLocal = true,
        )

        val mutations = mutableListOf<PendingMutationEntity>()
        if (reassigned) {
            vivifyClient(workspaceId, newClientName, newClientId, now)?.let { (row, m) ->
                db.clients().upsert(row); mutations += m
            }
            vivifyProject(workspaceId, newClientName, newProjectName, newClientId, newProjectId, now)
                ?.let { (row, m) -> db.projects().upsert(row); mutations += m }
            vivifyTicket(
                workspaceId, newClientName, newProjectName, newTicketName,
                newClientId, newProjectId, newTicketId, now,
            )?.let { (row, m) -> db.tickets().upsert(row); mutations += m }
        }

        mutations += pendingMutation(
            workspaceId = workspaceId,
            entity = EntityKindDto.TIME_SPAN,
            op = MutationOpDto.UPDATE,
            targetId = spanId,
            payload = updated.toUpdatePayload(clearEnd = clearEnd),
            // `base_revision` is what lets the server tell a deliberate reopen
            // (matrix row 7) from a stale device undoing a close it never saw
            // (row 6, rejected). Sending the revision we actually read is the
            // whole guard.
            baseRevision = existing.serverRevision.takeIf { it > 0 },
        )

        db.withTransaction {
            db.timeSpans().upsert(updated)
            queue.enqueueAll(mutations)
        }
        return true
    }

    /**
     * Split one span into N (protocol 7.3).
     *
     * N creates citing the original in `derived_from_span_ids`, plus one delete
     * of the original, pushed as one atomic batch. Expressed as ordinary
     * mutations rather than a bespoke "split" operation, so the conflict rules
     * need no special case and the lineage survives.
     */
    suspend fun splitSpan(spanId: String, boundaries: List<Instant>): List<String> {
        val workspaceId = workspaceId() ?: return emptyList()
        val original = db.timeSpans().byId(spanId) ?: return emptyList()
        val now = Instant.now()

        val start = Instant.ofEpochSecond(original.startEpochSeconds)
        val end = original.endEpochSeconds?.let { Instant.ofEpochSecond(it) } ?: return emptyList()

        val cuts = boundaries
            .filter { it.isAfter(start) && it.isBefore(end) }
            .distinct()
            .sorted()
        if (cuts.isEmpty()) return emptyList()

        val edges = buildList { add(start); addAll(cuts); add(end) }
        val created = mutableListOf<TimeSpanEntity>()
        val mutations = mutableListOf<PendingMutationEntity>()

        for (i in 0 until edges.size - 1) {
            val pieceStart = edges[i]
            val pieceEnd = edges[i + 1]
            val piece = original.copy(
                id = Uuids.v7String(pieceStart.toEpochMilli()),
                start = pieceStart.toWireString(),
                end = pieceEnd.toWireString(),
                startEpochSeconds = pieceStart.epochSecond,
                endEpochSeconds = pieceEnd.epochSecond,
                derivedFromSpanIdsJson = """["${original.id}"]""",
                createdAt = now.toWireString(),
                updatedAt = now.toWireString(),
                updatedAtEffective = now.toWireString(),
                serverRevision = 0,
                pendingLocal = true,
            )
            created += piece
            mutations += pendingMutation(
                workspaceId = workspaceId,
                entity = EntityKindDto.TIME_SPAN,
                op = MutationOpDto.CREATE,
                targetId = piece.id,
                payload = piece.toCreatePayload(derivedFrom = listOf(original.id)),
            )
        }

        mutations += pendingMutation(
            workspaceId = workspaceId,
            entity = EntityKindDto.TIME_SPAN,
            op = MutationOpDto.DELETE,
            targetId = original.id,
            payload = buildJsonObject {
                put("id", original.id)
                put("workspace_id", workspaceId)
            },
            baseRevision = original.serverRevision.takeIf { it > 0 },
        )

        db.withTransaction {
            db.timeSpans().upsertAll(created)
            db.timeSpans().upsert(original.copy(deletedAt = now.toWireString(), pendingLocal = true))
            queue.enqueueAll(mutations)
        }
        return created.map { it.id }
    }

    /** Merge N spans into one: one create citing all N, plus N deletes (protocol 7.3). */
    suspend fun mergeSpans(spanIds: List<String>): String? {
        val workspaceId = workspaceId() ?: return null
        if (spanIds.size < 2) return null
        val spans = spanIds.mapNotNull { db.timeSpans().byId(it) }
        if (spans.size < 2) return null
        val now = Instant.now()

        val earliest = spans.minBy { it.startEpochSeconds }
        val latestEnd = spans.mapNotNull { it.endEpochSeconds }.maxOrNull()
        val mergedStart = Instant.ofEpochSecond(earliest.startEpochSeconds)
        val mergedEnd = latestEnd?.let { Instant.ofEpochSecond(it) }

        val merged = earliest.copy(
            id = Uuids.v7String(mergedStart.toEpochMilli()),
            start = mergedStart.toWireString(),
            end = mergedEnd?.toWireString(),
            startEpochSeconds = mergedStart.epochSecond,
            endEpochSeconds = mergedEnd?.epochSecond,
            // Billable if any constituent was: dropping a billable flag during a
            // merge quietly loses revenue, and the user can always turn it off.
            isBillable = spans.any { it.isBillable },
            notes = spans.map { it.notes }.filter { it.isNotBlank() }.distinct().joinToString("\n"),
            derivedFromSpanIdsJson = json.encodeToString(
                ListSerializer(String.serializer()),
                spans.map { it.id },
            ),
            createdAt = now.toWireString(),
            updatedAt = now.toWireString(),
            updatedAtEffective = now.toWireString(),
            serverRevision = 0,
            pendingLocal = true,
        )

        val mutations = mutableListOf<PendingMutationEntity>()
        mutations += pendingMutation(
            workspaceId = workspaceId,
            entity = EntityKindDto.TIME_SPAN,
            op = MutationOpDto.CREATE,
            targetId = merged.id,
            payload = merged.toCreatePayload(derivedFrom = spans.map { it.id }),
        )
        for (span in spans) {
            mutations += pendingMutation(
                workspaceId = workspaceId,
                entity = EntityKindDto.TIME_SPAN,
                op = MutationOpDto.DELETE,
                targetId = span.id,
                payload = buildJsonObject {
                    put("id", span.id)
                    put("workspace_id", workspaceId)
                },
                baseRevision = span.serverRevision.takeIf { it > 0 },
            )
        }

        db.withTransaction {
            db.timeSpans().upsert(merged)
            db.timeSpans().upsertAll(
                spans.map { it.copy(deletedAt = now.toWireString(), pendingLocal = true) },
            )
            queue.enqueueAll(mutations)
        }
        return merged.id
    }

    /**
     * Resolve a review item.
     *
     * Only ever called from an explicit user action. Nothing in this class
     * resolves a `suspected_duplicate` or `billing_overlap` on its own -- the
     * server refuses to guess for good reason (protocol 8.3) and so does the
     * client.
     */
    suspend fun resolveReviewItem(itemId: String, resolution: String) {
        val workspaceId = workspaceId() ?: return
        val now = Instant.now().toWireString()
        db.reviewItems().resolve(itemId, resolution, now)

        val item = db.reviewItems().all(workspaceId).firstOrNull { it.id == itemId } ?: return
        if (item.entity != "time_span") return
        val span = db.timeSpans().byId(item.targetId) ?: return

        // Routed through pendingMutation, not queue.enqueue directly, so this
        // path gets the same origin_device_id stamp as every other. A second
        // funnel is a second thing to remember.
        queue.enqueueAll(
            listOf(
                pendingMutation(
                    workspaceId = workspaceId,
                    entity = EntityKindDto.TIME_SPAN,
                    op = MutationOpDto.UPDATE,
                    targetId = span.id,
                    payload = buildJsonObject {
                        put("id", span.id)
                        put("workspace_id", workspaceId)
                        put("updated_at", now)
                        putJsonArray("review_reasons") {
                            for (reason in span.reviewReasons()) {
                                add(
                                    buildJsonObject {
                                        put("code", reason.code.name.lowercase())
                                        put("raised_at", reason.raisedAt)
                                        put("raised_by", reason.raisedBy.name.lowercase())
                                        put(
                                            "resolution",
                                            if (reason.code.name.lowercase() == item.code) {
                                                resolution
                                            } else {
                                                reason.resolution.name.lowercase()
                                            },
                                        )
                                        reason.relatedId?.let { put("related_id", it) }
                                        put("resolved_at", now)
                                    },
                                )
                            }
                        }
                    },
                    baseRevision = span.serverRevision.takeIf { it > 0 },
                ),
            ),
        )
    }

    /** Approve a day's worth of spans. */
    suspend fun approveSpans(spanIds: List<String>) {
        for (id in spanIds) updateSpan(spanId = id, reviewState = "approved")
    }

    suspend fun updateSettings(transform: (UserSettingsEntity) -> UserSettingsEntity): Boolean {
        val workspaceId = workspaceId() ?: return false
        val current = db.settings().userSettingsOnce(workspaceId) ?: return false
        val now = Instant.now().toWireString()
        val updated = transform(current).copy(updatedAt = now, pendingLocal = true)

        db.withTransaction {
            db.settings().upsertUserSettings(updated)
            queue.enqueueAll(
                listOf(
                    pendingMutation(
                        workspaceId = workspaceId,
                        entity = EntityKindDto.USER_SETTINGS,
                        op = MutationOpDto.UPDATE,
                        targetId = updated.id,
                        payload = buildJsonObject {
                            put("id", updated.id)
                            put("workspace_id", workspaceId)
                            put("kind", "user_settings")
                            put("user_id", updated.userId)
                            put("screenshot_interval_minutes", updated.screenshotIntervalMinutes)
                            put("screenshot_capture_enabled", updated.screenshotCaptureEnabled)
                            put("local_only_screenshots", updated.localOnlyScreenshots)
                            put("retention_days", updated.retentionDays)
                            put("idle_threshold_minutes", updated.idleThresholdMinutes)
                            put("updated_at", now)
                        },
                        baseRevision = current.serverRevision.takeIf { it > 0 },
                    ),
                ),
            )
        }
        return true
    }

    // =========================================================== helpers ====

    private fun pendingMutation(
        workspaceId: String,
        entity: EntityKindDto,
        op: MutationOpDto,
        targetId: String,
        payload: JsonObject,
        baseRevision: Long? = null,
        now: Long = System.currentTimeMillis(),
    ): PendingMutationEntity {
        ScreenshotGate.require(entity)
        return PendingMutationEntity(
            mutationId = Uuids.v7String(now),
            workspaceId = workspaceId,
            userId = tokenStore.userId(),
            entity = entity.wireName(),
            op = op.wireName(),
            targetId = targetId,
            baseRevision = baseRevision,
            payloadJson = json.encodeToString(
                JsonObject.serializer(),
                payload.withOriginDeviceId(),
            ),
            createdAt = now,
        )
    }

    /**
     * Stamp `origin_device_id` onto every outgoing payload.
     *
     * NO LONGER REQUIRED FOR CORRECTNESS, and kept deliberately.
     *
     * It once was required: `wins?/3` compared the RAW payload, so an omitted
     * key was read as `""` and lost every exact-`updated_at_effective` tie,
     * silently. The server has since been fixed to derive the value once and use
     * that same value for both storage and adjudication, and fixtures wire-090
     * through wire-092 pin the new behaviour -- a request that omits the field
     * still wins a tie on merit, and still loses one it should lose.
     *
     * So why keep sending it? Because sending a genuine id is correct under BOTH
     * the old and the new server, while omitting is correct only under the new
     * one. The cost of keeping it is one redundant key; the cost of omitting
     * against a server that has not taken the fix is losing ties invisibly. That
     * asymmetry is the whole argument -- there is no symptom to notice if we get
     * it wrong.
     *
     * Note also that the derivation is `payload["origin_device_id"] ||
     * ctx.device_id`, so a client-sent value is still HONOURED rather than
     * overridden. Sending our true device id is therefore identical in effect to
     * omitting. It is only when every client omits that the tie-break becomes
     * genuinely client-independent, which is what §8.1 claims it already is.
     *
     * NB the contract (`SyncEnvelope.origin_device_id`) still documents the
     * pre-fix behaviour and instructs clients to always send. Reported as stale;
     * until it is amended, sending is also the contract-conformant choice.
     */
    private fun JsonObject.withOriginDeviceId(): JsonObject {
        if (containsKey("origin_device_id")) return this
        return JsonObject(this + ("origin_device_id" to JsonPrimitive(tokenStore.deviceId())))
    }

    /** Returns null when the name canons to empty -- "no reference", not a row named "". */
    private suspend fun vivifyClient(
        workspaceId: String,
        name: String,
        id: String?,
        now: Instant,
    ): Pair<ClientEntity, PendingMutationEntity>? {
        if (id == null || Canon.isBlank(name)) return null
        if (db.clients().byId(id) != null) return null
        val row = ClientEntity(
            id = id,
            workspaceId = workspaceId,
            name = name.trim(),
            canonicalName = canon(name),
            autoCreated = true,
            createdAt = now.toWireString(),
            updatedAt = now.toWireString(),
            pendingLocal = true,
        )
        return row to pendingMutation(
            workspaceId = workspaceId,
            entity = EntityKindDto.CLIENT,
            op = MutationOpDto.CREATE,
            targetId = id,
            payload = buildJsonObject {
                put("id", id)
                put("workspace_id", workspaceId)
                put("name", row.name)
                // `canonical_name` is NOT sent. The server derives it via
                // canon() and never trusts a client's copy; the contract lists
                // it as server-owned and says such fields MUST NOT appear in a
                // payload. Sending it was harmless -- the server ignores it --
                // but a client that sends a field is asserting it may set it,
                // and that belief is the thing worth not having.
                put("auto_created", true)
            },
        )
    }

    private suspend fun vivifyProject(
        workspaceId: String,
        clientName: String,
        name: String,
        clientId: String?,
        id: String?,
        now: Instant,
    ): Pair<ProjectEntity, PendingMutationEntity>? {
        if (id == null || Canon.isBlank(name)) return null
        if (db.projects().byId(id) != null) return null
        val row = ProjectEntity(
            id = id,
            workspaceId = workspaceId,
            name = name.trim(),
            canonicalName = canon(name),
            clientId = clientId,
            clientName = clientName.trim(),
            autoCreated = true,
            createdAt = now.toWireString(),
            updatedAt = now.toWireString(),
            pendingLocal = true,
        )
        return row to pendingMutation(
            workspaceId = workspaceId,
            entity = EntityKindDto.PROJECT,
            op = MutationOpDto.CREATE,
            targetId = id,
            payload = buildJsonObject {
                put("id", id)
                put("workspace_id", workspaceId)
                put("name", row.name)
                // `canonical_name` is NOT sent. The server derives it via
                // canon() and never trusts a client's copy; the contract lists
                // it as server-owned and says such fields MUST NOT appear in a
                // payload. Sending it was harmless -- the server ignores it --
                // but a client that sends a field is asserting it may set it,
                // and that belief is the thing worth not having.
                clientId?.let { put("client_id", it) }
                put("client_name", row.clientName)
                put("auto_created", true)
            },
        )
    }

    private suspend fun vivifyTicket(
        workspaceId: String,
        clientName: String,
        projectName: String,
        name: String,
        clientId: String?,
        projectId: String?,
        id: String?,
        now: Instant,
    ): Pair<TicketEntity, PendingMutationEntity>? {
        if (id == null || Canon.isBlank(name)) return null
        if (db.tickets().byId(id) != null) return null
        val row = TicketEntity(
            id = id,
            workspaceId = workspaceId,
            name = name.trim(),
            canonicalName = canon(name),
            clientId = clientId,
            projectId = projectId,
            clientName = clientName.trim(),
            projectName = projectName.trim(),
            autoCreated = true,
            createdAt = now.toWireString(),
            updatedAt = now.toWireString(),
            pendingLocal = true,
        )
        return row to pendingMutation(
            workspaceId = workspaceId,
            entity = EntityKindDto.TICKET,
            op = MutationOpDto.CREATE,
            targetId = id,
            payload = buildJsonObject {
                put("id", id)
                put("workspace_id", workspaceId)
                put("name", row.name)
                // `canonical_name` is NOT sent. The server derives it via
                // canon() and never trusts a client's copy; the contract lists
                // it as server-owned and says such fields MUST NOT appear in a
                // payload. Sending it was harmless -- the server ignores it --
                // but a client that sends a field is asserting it may set it,
                // and that belief is the thing worth not having.
                clientId?.let { put("client_id", it) }
                projectId?.let { put("project_id", it) }
                put("auto_created", true)
            },
        )
    }

    private fun TimeSpanEntity.toCreatePayload(derivedFrom: List<String> = emptyList()): JsonObject =
        buildJsonObject {
            put("id", id)
            put("workspace_id", workspaceId)
            put("title", title)
            clientId?.let { put("client_id", it) }
            projectId?.let { put("project_id", it) }
            ticketId?.let { put("ticket_id", it) }
            put("client_name", clientName)
            put("project_name", projectName)
            put("ticket_name", ticketName)
            put("start", start)
            end?.let { put("end", it) }
            put("source", source)
            put("is_billable", isBillable)
            put("notes", notes)
            put("review_state", reviewState)
            put("created_at", createdAt)
            put("updated_at", updatedAt)
            if (derivedFrom.isNotEmpty()) {
                putJsonArray("derived_from_span_ids") { derivedFrom.forEach { add(it) } }
            }
        }

    /**
     * `clearEnd` is carried as an explicit null; an untouched `end` is OMITTED.
     *
     * The server's reopen guard is, in effect:
     *
     * ```
     * reopening? = existing.end_at != nil
     *              and Map.has_key?(payload, "end")
     *              and payload["end"] == nil
     * ```
     *
     * Two consequences, and the second is the reason omission is worth keeping:
     *
     * 1. A deliberate reopen MUST send an explicit null, or the guard cannot see
     *    it and the reopen is unexpressible. So `clearEnd` writes `JsonNull`
     *    rather than dropping the key.
     *
     * 2. An ordinary edit of a span THIS DEVICE believes is open must omit the
     *    key. If it sent `"end": null` instead, then whenever another device had
     *    already closed that span, `Map.has_key?` would be true and the guard
     *    would fire -- turning an innocent retitle into a
     *    `span_reopen_forbidden` rejection. Omitting means the title merges and
     *    the remote close survives, which is the partial-update behaviour matrix
     *    row 6 describes.
     *
     * Everything else here is a full document, so this is the only field whose
     * presence is conditional -- and it is conditional on what the field means,
     * not on whether it happens to be null.
     */
    private fun TimeSpanEntity.toUpdatePayload(clearEnd: Boolean): JsonObject = buildJsonObject {
        put("id", id)
        put("workspace_id", workspaceId)
        put("title", title)
        clientId?.let { put("client_id", it) }
        projectId?.let { put("project_id", it) }
        ticketId?.let { put("ticket_id", it) }
        put("client_name", clientName)
        put("project_name", projectName)
        put("ticket_name", ticketName)
        put("start", start)
        when {
            clearEnd -> put("end", kotlinx.serialization.json.JsonNull)
            end != null -> put("end", end)
        }
        put("is_billable", isBillable)
        put("notes", notes)
        put("review_state", reviewState)
        put("updated_at", updatedAt)
    }
}
