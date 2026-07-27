package com.noizu.timely.local

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.noizu.timely.data.local.ClientEntity
import com.noizu.timely.data.local.PendingMutationEntity
import com.noizu.timely.data.local.ReviewItemEntity
import com.noizu.timely.data.local.SyncStateEntity
import com.noizu.timely.data.local.TimeSpanEntity
import com.noizu.timely.data.local.TimelyDatabase
import com.noizu.timely.data.local.reviewReasons
import com.noizu.timely.data.local.toEntity
import com.noizu.timely.data.remote.dto.ReviewStateDto
import com.noizu.timely.data.remote.dto.TimeSpanDto
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33], manifest = Config.NONE)
class RoomRoundTripTest {

    private lateinit var db: TimelyDatabase
    private val workspaceId = "0192f7a1-2b44-7000-8a10-9d3e4f5a6b7c"

    @Before
    fun setUp() {
        db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext<Context>(),
            TimelyDatabase::class.java,
        ).allowMainThreadQueries().build()
    }

    @After
    fun tearDown() = db.close()

    @Test
    fun `a wire span round-trips through Room unchanged`() = runTest {
        val dto = TimeSpanDto(
            id = "span-1",
            workspaceId = workspaceId,
            title = "Refactor billing",
            clientName = "Acme",
            projectName = "Redesign",
            start = "2026-07-27T09:00:00Z",
            end = "2026-07-27T10:30:00Z",
            isBillable = true,
            notes = "Notes with an apostrophe: Bob's",
            reviewState = ReviewStateDto.NEEDS_REVIEW,
            createdAt = "2026-07-27T09:00:00Z",
            updatedAt = "2026-07-27T10:30:00Z",
            serverRevision = 42,
        )

        db.timeSpans().upsert(dto.toEntity())
        val stored = db.timeSpans().byId("span-1")!!

        assertEquals(dto.title, stored.title)
        assertEquals(dto.notes, stored.notes)
        assertEquals(42L, stored.serverRevision)
        assertTrue(stored.isBillable)
        // Enums are stored as their wire spelling, not an ordinal, so reordering
        // the enum declaration cannot silently change what a stored row means.
        assertEquals("needs_review", stored.reviewState)
        assertEquals(1_785_142_800L, stored.startEpochSeconds)
        assertEquals(1_785_148_200L, stored.endEpochSeconds)
    }

    @Test
    fun `review reasons survive the JSON column`() = runTest {
        val dto = TimeSpanDto(
            id = "span-flagged",
            workspaceId = workspaceId,
            start = "2026-07-27T09:00:00Z",
            createdAt = "2026-07-27T09:00:00Z",
            updatedAt = "2026-07-27T09:00:00Z",
            reviewReasons = listOf(
                com.noizu.timely.data.remote.dto.ReviewReasonDto(
                    code = com.noizu.timely.data.remote.dto.ReviewReasonCodeDto.SUSPECTED_DUPLICATE,
                    raisedAt = "2026-07-27T09:05:00Z",
                    raisedBy = com.noizu.timely.data.remote.dto.RaisedByDto.SERVER,
                    relatedId = "span-other",
                ),
            ),
        )

        db.timeSpans().upsert(dto.toEntity())
        val reasons = db.timeSpans().byId("span-flagged")!!.reviewReasons()

        assertEquals(1, reasons.size)
        assertEquals("span-other", reasons.single().relatedId)
    }

    @Test
    fun `the day query is bounded by start time and excludes tombstones`() = runTest {
        db.timeSpans().upsertAll(
            listOf(
                span("in-range", startEpoch = 1_785_142_800),           // 27 Jul 09:00Z
                span("before", startEpoch = 1_785_056_400),             // 26 Jul 09:00Z
                span("deleted", startEpoch = 1_785_146_400, deleted = true),
            ),
        )

        val day = db.timeSpans().rangeOnce(
            workspaceId,
            fromEpochSeconds = 1_785_110_400, // 27 Jul 00:00Z
            toEpochSeconds = 1_785_196_800,   // 28 Jul 00:00Z
        )

        assertEquals(listOf("in-range"), day.map { it.id })
    }

    @Test
    fun `the unique index collapses two devices vivifying the same client`() = runTest {
        // Both rows carry the same deterministic id, so REPLACE makes the second
        // arrival an update rather than a duplicate.
        val id = "6a3b1c2d-0000-5000-8000-000000000001"
        db.clients().upsert(client(id, name = "Acme"))
        db.clients().upsert(client(id, name = "ACME"))

        val all = db.clients().observeActive(workspaceId).first()
        assertEquals(1, all.size)
        assertEquals("ACME", all.single().name)
    }

    @Test
    fun `the push queue preserves insertion order and dequeues by mutation id`() = runTest {
        val ids = (1..5).map { "mutation-$it" }
        for (id in ids) db.pendingMutations().enqueue(pending(id))

        val batch = db.pendingMutations().nextBatch(workspaceId, 10)
        assertEquals(ids, batch.map { it.mutationId })

        db.pendingMutations().deleteByMutationIds(listOf("mutation-2", "mutation-4"))
        assertEquals(
            listOf("mutation-1", "mutation-3", "mutation-5"),
            db.pendingMutations().nextBatch(workspaceId, 10).map { it.mutationId },
        )
    }

    @Test
    fun `a dead-lettered mutation leaves the batch but stays visible`() = runTest {
        db.pendingMutations().enqueue(pending("mutation-stuck"))
        db.pendingMutations().deadLetter("mutation-stuck", "validation_failed", 0)

        assertTrue(db.pendingMutations().nextBatch(workspaceId, 10).isEmpty())
        assertEquals(0, db.pendingMutations().pendingCount(workspaceId))
        // Still retrievable, so the user can be told what did not sync.
        val dead = db.pendingMutations().observeDeadLettered(workspaceId).first()
        assertEquals(1, dead.size)
        assertEquals("validation_failed", dead.single().deadLetterReason)
    }

    @Test
    fun `sync state round-trips including the resync flag`() = runTest {
        db.syncState().upsert(SyncStateEntity(workspaceId = workspaceId, cursor = 17))
        assertEquals(17L, db.syncState().get(workspaceId)?.cursor)

        db.syncState().upsert(
            db.syncState().get(workspaceId)!!.copy(resyncRequired = true, cursor = 21),
        )
        val state = db.syncState().get(workspaceId)!!
        assertTrue(state.resyncRequired)
        assertEquals(21L, state.cursor)
    }

    @Test
    fun `resolving a review item removes it from the open list without deleting it`() = runTest {
        db.reviewItems().upsert(
            ReviewItemEntity(
                id = "review-1",
                workspaceId = workspaceId,
                entity = "time_span",
                targetId = "span-1",
                code = "suspected_duplicate",
                raisedAt = "2026-07-27T09:05:00Z",
                createdAt = 0,
            ),
        )
        assertEquals(1, db.reviewItems().observeOpen(workspaceId).first().size)

        db.reviewItems().resolve("review-1", "dismissed", "2026-07-27T10:00:00Z")

        assertTrue(db.reviewItems().observeOpen(workspaceId).first().isEmpty())
        // The decision is retained; the audit trail is the product.
        assertEquals(1, db.reviewItems().all(workspaceId).size)
        assertEquals("dismissed", db.reviewItems().all(workspaceId).single().resolution)
    }

    @Test
    fun `an unknown id reads back as null rather than throwing`() = runTest {
        assertNull(db.timeSpans().byId("nope"))
        assertNull(db.clients().byId("nope"))
        assertNull(db.syncState().get("nope"))
    }

    // --------------------------------------------------------------- fixtures

    private fun span(id: String, startEpoch: Long, deleted: Boolean = false) = TimeSpanEntity(
        id = id,
        workspaceId = workspaceId,
        title = id,
        start = "2026-07-27T09:00:00Z",
        startEpochSeconds = startEpoch,
        createdAt = "2026-07-27T09:00:00Z",
        updatedAt = "2026-07-27T09:00:00Z",
        deletedAt = if (deleted) "2026-07-27T11:00:00Z" else null,
    )

    private fun client(id: String, name: String) = ClientEntity(
        id = id,
        workspaceId = workspaceId,
        name = name,
        canonicalName = "acme",
        createdAt = "2026-07-27T09:00:00Z",
        updatedAt = "2026-07-27T09:00:00Z",
    )

    private fun pending(mutationId: String) = PendingMutationEntity(
        mutationId = mutationId,
        workspaceId = workspaceId,
        userId = "user-1",
        entity = "time_span",
        op = "update",
        targetId = "span-1",
        payloadJson = "{}",
        createdAt = 0,
    )
}
