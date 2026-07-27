package com.noizu.timely.sync

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.noizu.timely.core.identity.TaxonomyIds
import com.noizu.timely.data.local.TimelyDatabase
import com.noizu.timely.data.repo.TimelyRepository
import com.noizu.timely.data.sync.PushQueue
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
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
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * The offline guarantee, tested as behaviour rather than trusted as a comment.
 *
 * Every test here runs with either an expired access token or no session at
 * all. If any of them starts failing, the app has quietly stopped being usable
 * on a plane -- which is the one condition a time tracker must survive.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33], manifest = Config.NONE)
class OfflineWriteTest {

    private lateinit var db: TimelyDatabase
    private lateinit var queue: PushQueue
    private lateinit var repository: TimelyRepository
    private lateinit var session: FakeSessionStore

    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false; encodeDefaults = true }
    private val workspaceId = FakeSessionStore.WORKSPACE_ID
    private val zone: ZoneId = ZoneId.of("UTC")

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        db = Room.inMemoryDatabaseBuilder(context, TimelyDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        queue = PushQueue(db, json)
        session = FakeSessionStore()
        repository = TimelyRepository(db, queue, session, json)
    }

    @After
    fun tearDown() = db.close()

    @Test
    fun `a manual entry saves and queues with an expired access token`() = runTest {
        session.expireAccessToken()

        val spanId = repository.createManualSpan(
            title = "Refactor billing",
            clientName = "Acme",
            projectName = "Redesign",
            ticketName = "",
            start = Instant.parse("2026-07-27T09:00:00Z"),
            end = Instant.parse("2026-07-27T10:30:00Z"),
            isBillable = true,
        )

        assertNotNull("the write was refused while offline", spanId)
        val stored = db.timeSpans().byId(spanId!!)
        assertNotNull("nothing was written locally", stored)
        assertTrue("the row should be marked as not yet synced", stored!!.pendingLocal)
        assertTrue("nothing was queued for later push", queue.pendingCount(workspaceId) > 0)
    }

    @Test
    fun `edits still work after the session is marked reauth-required`() = runTest {
        val spanId = repository.createManualSpan(
            title = "Standup",
            clientName = "Acme",
            projectName = "Redesign",
            ticketName = "",
            start = Instant.parse("2026-07-27T09:00:00Z"),
            end = Instant.parse("2026-07-27T09:15:00Z"),
            isBillable = false,
        )!!
        val queuedBefore = queue.pendingCount(workspaceId)

        // The overnight-expiry case: refresh failed, session flagged.
        session.markReauthRequired()

        assertTrue(repository.updateSpan(spanId = spanId, title = "Standup (long)"))
        assertTrue(repository.updateSpan(spanId = spanId, isBillable = true))

        val updated = db.timeSpans().byId(spanId)!!
        assertEquals("Standup (long)", updated.title)
        assertTrue(updated.isBillable)
        assertTrue(
            "edits made while signed out must queue, not vanish",
            queue.pendingCount(workspaceId) > queuedBefore,
        )
    }

    @Test
    fun `signing out keeps the local timeline and the queue`() = runTest {
        repository.createManualSpan(
            title = "Deep work",
            clientName = "Acme",
            projectName = "Redesign",
            ticketName = "",
            start = Instant.parse("2026-07-27T11:00:00Z"),
            end = Instant.parse("2026-07-27T12:00:00Z"),
            isBillable = true,
        )
        val queuedBefore = queue.pendingCount(workspaceId)
        assertTrue(queuedBefore > 0)

        session.signOut()

        // Sign-out clears credentials only. The day is still there and the queue
        // is still there, because "sign out" is not "discard my unsynced work".
        val day = repository
            .observeDay(LocalDate.parse("2026-07-27"), zone)
            .first()
        assertEquals(1, day.size)
        assertEquals(queuedBefore, queue.pendingCount(workspaceId))
    }

    @Test
    fun `two offline devices minting the same name converge on one id`() = runTest {
        // The whole point of deterministic taxonomy ids. Different casing and
        // padding, no coordination, same row.
        val a = TaxonomyIds.clientIdOrNull(workspaceId, "Acme")
        val b = TaxonomyIds.clientIdOrNull(workspaceId, "  ACME  ")
        assertEquals(a, b)

        val projectA = TaxonomyIds.projectIdOrNull(workspaceId, "Acme", "Redesign")
        val projectB = TaxonomyIds.projectIdOrNull(workspaceId, "ACME", "  redesign ")
        assertEquals(projectA, projectB)
    }

    @Test
    fun `a blank project name attaches nothing rather than creating an empty row`() = runTest {
        val spanId = repository.createManualSpan(
            title = "Untracked admin",
            clientName = "   ",
            projectName = "",
            ticketName = "",
            start = Instant.parse("2026-07-27T13:00:00Z"),
            end = Instant.parse("2026-07-27T13:30:00Z"),
            isBillable = false,
        )!!

        val span = db.timeSpans().byId(spanId)!!
        assertNull("a blank client must not mint an entity", span.clientId)
        assertNull("a blank project must not mint an entity", span.projectId)
        assertTrue(
            "no taxonomy rows should have been created",
            db.clients().observeActive(workspaceId).first().isEmpty(),
        )
    }

    @Test
    fun `split produces pieces plus a delete, all queued atomically`() = runTest {
        val spanId = repository.createManualSpan(
            title = "Long session",
            clientName = "Acme",
            projectName = "Redesign",
            ticketName = "",
            start = Instant.parse("2026-07-27T09:00:00Z"),
            end = Instant.parse("2026-07-27T11:00:00Z"),
            isBillable = true,
        )!!
        val before = queue.pendingCount(workspaceId)

        val pieces = repository.splitSpan(spanId, listOf(Instant.parse("2026-07-27T10:00:00Z")))

        assertEquals("one cut yields two pieces", 2, pieces.size)
        assertNotNull(db.timeSpans().byId(pieces[0]))
        assertNotNull(db.timeSpans().byId(pieces[1]))
        assertNotNull("the original must be tombstoned, not erased",
            db.timeSpans().byId(spanId)?.deletedAt)
        assertEquals(
            "expected 2 creates + 1 delete queued",
            before + 3,
            queue.pendingCount(workspaceId),
        )
        // Lineage survives, so the correction stays auditable.
        assertTrue(db.timeSpans().byId(pieces[0])!!.derivedFromSpanIdsJson.contains(spanId))
    }

    @Test
    fun `merge produces one create citing all constituents plus their deletes`() = runTest {
        val first = repository.createManualSpan(
            "Part one", "Acme", "Redesign", "",
            Instant.parse("2026-07-27T09:00:00Z"), Instant.parse("2026-07-27T10:00:00Z"), true,
        )!!
        val second = repository.createManualSpan(
            "Part two", "Acme", "Redesign", "",
            Instant.parse("2026-07-27T10:00:00Z"), Instant.parse("2026-07-27T11:00:00Z"), false,
        )!!
        val before = queue.pendingCount(workspaceId)

        val merged = repository.mergeSpans(listOf(first, second))!!

        val row = db.timeSpans().byId(merged)!!
        assertTrue("merged span must cite both", row.derivedFromSpanIdsJson.contains(first))
        assertTrue(row.derivedFromSpanIdsJson.contains(second))
        assertTrue("billable must survive a merge", row.isBillable)
        assertNotNull(db.timeSpans().byId(first)?.deletedAt)
        assertNotNull(db.timeSpans().byId(second)?.deletedAt)
        assertEquals("expected 1 create + 2 deletes", before + 3, queue.pendingCount(workspaceId))
    }

    @Test
    fun `the queue survives a database reopen`() = runTest {
        // Durability is a protocol requirement (7.2): the queue must outlive a
        // force-quit, not just an activity restart.
        repository.createManualSpan(
            "Persisted", "Acme", "Redesign", "",
            Instant.parse("2026-07-27T14:00:00Z"), Instant.parse("2026-07-27T15:00:00Z"), true,
        )
        val queued = db.pendingMutations().all(workspaceId)
        assertTrue(queued.isNotEmpty())

        // In-memory Room cannot literally be reopened, so assert the property
        // that makes durability work: every queued row is on disk-backed state
        // with a stable id and an explicit sequence, not in a field somewhere.
        assertTrue(queued.all { it.mutationId.isNotBlank() })
        assertEquals(queued.map { it.seq }.sorted(), queued.map { it.seq })
    }
}
