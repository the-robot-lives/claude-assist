package com.noizu.timely.sync

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import com.noizu.timely.data.local.PendingMutationEntity
import com.noizu.timely.data.local.TimeSpanEntity
import com.noizu.timely.data.local.TimelyDatabase
import com.noizu.timely.data.remote.TimelyApi
import com.noizu.timely.data.repo.TimelyRepository
import com.noizu.timely.data.sync.PushQueue
import com.noizu.timely.data.sync.SyncEngine
import com.noizu.timely.data.sync.SyncOutcome
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.RecordedRequest
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
import retrofit2.Retrofit
import java.time.Instant

/**
 * Sync engine behaviour against a real HTTP stack and a real (in-memory) Room.
 *
 * Deliberately not built on mocks of [TimelyApi] or the DAOs: the bugs worth
 * catching here are in serialization, transaction boundaries, and what survives
 * a failure, and a mock of the layer under test cannot express any of them.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33], manifest = Config.NONE)
class SyncEngineTest {

    private lateinit var server: MockWebServer
    private lateinit var db: TimelyDatabase
    private lateinit var api: TimelyApi
    private lateinit var queue: PushQueue
    private lateinit var engine: SyncEngine
    private lateinit var sessionStore: FakeSessionStore
    private lateinit var repository: TimelyRepository

    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false; encodeDefaults = true }
    private val workspaceId = FakeSessionStore.WORKSPACE_ID

    @Before
    fun setUp() {
        server = MockWebServer().apply { start() }
        val context = ApplicationProvider.getApplicationContext<Context>()
        db = Room.inMemoryDatabaseBuilder(context, TimelyDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().build())
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()
            .create(TimelyApi::class.java)
        queue = PushQueue(db, json)
        sessionStore = FakeSessionStore()
        repository = TimelyRepository(db, queue, sessionStore, json)
        engine = SyncEngine(api, db, queue, sessionStore, json)
    }

    @After
    fun tearDown() {
        server.shutdown()
        db.close()
    }

    // ============================================================== pull ====

    @Test
    fun `pull applies rows and advances the cursor together`() = runTest {
        server.enqueueChanges(
            spans = listOf(spanJson("span-1", revision = 7)),
            nextCursor = 7,
            hasMore = false,
        )

        val outcome = engine.sync()

        assertTrue("expected success, got $outcome", outcome is SyncOutcome.Success)
        assertNotNull("row was not applied", db.timeSpans().byId("span-1"))
        assertEquals(
            "cursor did not advance with the rows it covers",
            7L,
            db.syncState().get(workspaceId)?.cursor,
        )
    }

    @Test
    fun `pull follows has_more across pages`() = runTest {
        server.enqueueChanges(listOf(spanJson("span-1", revision = 1)), nextCursor = 1, hasMore = true)
        server.enqueueChanges(listOf(spanJson("span-2", revision = 2)), nextCursor = 2, hasMore = false)

        engine.sync()

        assertNotNull(db.timeSpans().byId("span-1"))
        assertNotNull(db.timeSpans().byId("span-2"))
        assertEquals(2L, db.syncState().get(workspaceId)?.cursor)
    }

    @Test
    fun `applying the same page twice is idempotent`() = runTest {
        // At-least-once delivery means a page legitimately arrives twice after a
        // retry. The second application must be a no-op, not a duplicate row or
        // a crash on the unique index.
        server.enqueueChanges(listOf(spanJson("span-1", revision = 3)), nextCursor = 3, hasMore = false)
        engine.sync()

        server.enqueueChanges(listOf(spanJson("span-1", revision = 3)), nextCursor = 3, hasMore = false)
        engine.sync()

        assertEquals(
            1,
            db.timeSpans().rangeOnce(workspaceId, 0, Long.MAX_VALUE).size,
        )
    }

    @Test
    fun `tombstones are applied even for rows never seen`() = runTest {
        server.enqueueChanges(
            listOf(spanJson("never-seen", revision = 4, deletedAt = "2026-07-27T10:00:00Z")),
            nextCursor = 4,
            hasMore = false,
        )

        engine.sync()

        val row = db.timeSpans().byId("never-seen")
        assertNotNull("tombstone for an unknown row should still be stored", row)
        assertNotNull("row was not tombstoned", row?.deletedAt)
        // And it must not appear in the day view.
        assertTrue(db.timeSpans().rangeOnce(workspaceId, 0, Long.MAX_VALUE).isEmpty())
    }

    @Test
    fun `a tombstone horizon past the cursor demands a resync instead of continuing`() = runTest {
        // Get a non-zero cursor first; the horizon check is meaningless at cursor 0.
        server.enqueueChanges(listOf(spanJson("span-1", revision = 5)), nextCursor = 5, hasMore = false)
        engine.sync()

        server.enqueueChanges(
            emptyList(),
            nextCursor = 99,
            hasMore = false,
            tombstoneHorizon = 50,
        )
        val outcome = engine.sync()

        assertEquals(SyncOutcome.ResyncRequired, outcome)
        assertTrue(
            "resyncRequired was not persisted",
            db.syncState().get(workspaceId)?.resyncRequired == true,
        )
    }

    @Test
    fun `server-raised duplicate and overlap flags become review items and are never auto-resolved`() =
        runTest {
            server.enqueueChanges(
                listOf(
                    spanJson(
                        "span-a",
                        revision = 9,
                        reviewState = "needs_review",
                        reviewReasons = """
                        [{"code":"suspected_duplicate","raised_at":"2026-07-27T10:00:00Z",
                          "raised_by":"server","resolution":"pending","related_id":"span-b"},
                         {"code":"billing_overlap","raised_at":"2026-07-27T10:00:00Z",
                          "raised_by":"server","resolution":"pending","related_id":"span-b"}]
                        """.trimIndent(),
                    ),
                ),
                nextCursor = 9,
                hasMore = false,
            )

            engine.sync()

            val items = db.reviewItems().all(workspaceId)
            assertEquals("both flags should surface", 2, items.size)
            assertTrue(items.all { it.resolution == "pending" && it.resolvedAt == null })
            assertTrue(items.any { it.code == "suspected_duplicate" })
            assertTrue(items.any { it.code == "billing_overlap" })
            // Neither span was merged, trimmed, or hidden.
            assertNotNull(db.timeSpans().byId("span-a"))
        }

    // ============================================================== push ====

    @Test
    fun `applied mutations dequeue and conflicts are recorded`() = runTest {
        val applied = enqueueSpanMutation("span-applied")
        val conflicted = enqueueSpanMutation("span-conflict")

        server.enqueuePushResults(
            """
            {"mutation_id":"${applied.mutationId}","status":"applied"},
            {"mutation_id":"${conflicted.mutationId}","status":"conflict","reason":"duplicate_name",
             "message":"That name is taken"}
            """.trimIndent(),
        )
        server.enqueueChanges(emptyList(), nextCursor = 0, hasMore = false)

        val outcome = engine.sync()

        assertTrue(outcome is SyncOutcome.Success)
        assertEquals("both terminal results should dequeue", 0, queue.pendingCount(workspaceId))
        val items = db.reviewItems().all(workspaceId)
        assertTrue(
            "a duplicate_name conflict needs a human, so it must surface",
            items.any { it.code == "duplicate_name" },
        )
    }

    @Test
    fun `a rejected mutation dequeues but is surfaced rather than dropped silently`() = runTest {
        val rejected = enqueueSpanMutation("span-locked")
        server.enqueuePushResults(
            """
            {"mutation_id":"${rejected.mutationId}","status":"rejected","reason":"locked_day",
             "entity_kind":"time_span","message":"That day is locked"}
            """.trimIndent(),
        )
        server.enqueueChanges(emptyList(), nextCursor = 0, hasMore = false)

        engine.sync()

        assertEquals(0, queue.pendingCount(workspaceId))
        assertTrue(
            "the user must be told the edit did not happen",
            db.reviewItems().all(workspaceId).any { it.code == "locked_day" },
        )
    }

    @Test
    fun `entity_kind routes a rejection that carries no row`() = runTest {
        // The case that motivated putting entity_kind on the envelope: a
        // `rejected` result has a null `entity`, so the discriminator is the
        // only thing that says what was refused.
        val rejected = enqueueSpanMutation("span-no-row")
        server.enqueuePushResults(
            """
            {"mutation_id":"${rejected.mutationId}","status":"rejected",
             "reason":"span_reopen_forbidden","entity_kind":"time_span"}
            """.trimIndent(),
        )
        server.enqueueChanges(emptyList(), nextCursor = 0, hasMore = false)

        engine.sync()

        val item = db.reviewItems().all(workspaceId)
            .single { it.code == "span_reopen_forbidden" }
        assertEquals("time_span", item.entity)
        assertEquals("span-no-row", item.targetId)
    }

    @Test
    fun `an echoed row is applied using the envelope entity_kind`() = runTest {
        val applied = enqueueSpanMutation("span-echo")
        server.enqueuePushResults(
            """
            {"mutation_id":"${applied.mutationId}","status":"applied",
             "entity_kind":"time_span",
             "entity":${spanJson("span-echo", revision = 31)}}
            """.trimIndent(),
        )
        server.enqueueChanges(emptyList(), nextCursor = 0, hasMore = false)

        engine.sync()

        assertEquals(
            "the server's echoed revision should have been written back",
            31L,
            db.timeSpans().byId("span-echo")?.serverRevision,
        )
    }

    @Test
    fun `an echoed row with no entity_kind is skipped, never guessed at`() = runTest {
        // The old inferKindFromRow heuristic would have guessed "time_span" from
        // the presence of `start`. Guessing is what was removed: a row whose
        // kind the server did not state is left for the next full pull rather
        // than written into a table chosen by field-shape.
        val applied = enqueueSpanMutation("span-unkinded")
        val before = db.timeSpans().byId("span-unkinded")!!.serverRevision
        server.enqueuePushResults(
            """
            {"mutation_id":"${applied.mutationId}","status":"applied",
             "entity":${spanJson("span-unkinded", revision = 77)}}
            """.trimIndent(),
        )
        server.enqueueChanges(emptyList(), nextCursor = 0, hasMore = false)

        engine.sync()

        assertEquals(
            "a kindless echo must not be applied by guesswork",
            before,
            db.timeSpans().byId("span-unkinded")?.serverRevision,
        )
        // It still dequeues: the result was terminal regardless.
        assertEquals(0, queue.pendingCount(workspaceId))
    }

    @Test
    fun `a mutation absent from results stays queued`() = runTest {
        // Protocol 7.2: absence means "not processed". Treating it as success is
        // how an edit disappears with no trace anywhere.
        val present = enqueueSpanMutation("span-present")
        enqueueSpanMutation("span-absent")

        server.enqueuePushResults("""{"mutation_id":"${present.mutationId}","status":"applied"}""")
        server.enqueueChanges(emptyList(), nextCursor = 0, hasMore = false)

        engine.sync()

        assertEquals("the unanswered mutation must survive", 1, queue.pendingCount(workspaceId))
    }

    @Test
    fun `a replayed mutation keeps its original mutation id`() = runTest {
        // Idempotency depends entirely on the id being minted once. A retry that
        // re-mints would double-apply on the server.
        val row = enqueueSpanMutation("span-replay")
        val originalId = row.mutationId

        // First attempt: the server never answers.
        server.enqueue(MockResponse().setResponseCode(503))
        val first = engine.sync()
        assertTrue("5xx must be retryable, got $first", first is SyncOutcome.Retry)
        assertEquals("a failed push must not dequeue", 1, queue.pendingCount(workspaceId))

        val requeued = queue.nextBatch(workspaceId).single()
        assertEquals("mutation_id changed across a retry", originalId, requeued.mutationId)

        // Second attempt: the server reports it already applied this id.
        server.enqueuePushResults(
            """{"mutation_id":"$originalId","status":"applied","replayed":true}""",
        )
        server.enqueueChanges(emptyList(), nextCursor = 0, hasMore = false)
        engine.sync()

        assertEquals(0, queue.pendingCount(workspaceId))
    }

    @Test
    fun `the pushed batch carries the ids that were queued, in order`() = runTest {
        val first = enqueueSpanMutation("span-1")
        val second = enqueueSpanMutation("span-2")
        val third = enqueueSpanMutation("span-3")

        server.enqueuePushResults(
            listOf(first, second, third).joinToString(",") {
                """{"mutation_id":"${it.mutationId}","status":"applied"}"""
            },
        )
        server.enqueueChanges(emptyList(), nextCursor = 0, hasMore = false)

        engine.sync()

        val body = server.takeRequestBody()
        val order = Regex("\"mutation_id\":\"([^\"]+)\"").findAll(body)
            .map { it.groupValues[1] }.toList()
        assertEquals(
            "FIFO order is required: an update must not overtake its create",
            listOf(first.mutationId, second.mutationId, third.mutationId),
            order,
        )
    }

    @Test
    fun `a pull must NOT clobber a local edit that is still queued`() = runTest {
        // Protocol 7.1: "Applying a change to a row with unpushed local edits:
        // the local edit wins in the UI until it is pushed and answered."
        //
        // The user edits offline. Before the queue drains, a pull arrives
        // carrying the server's OLDER copy of that row. The user must keep
        // seeing their own edit -- watching it silently revert while it is
        // still sitting in the outbox is the worst kind of data-loss illusion.
        val spanId = repository.createManualSpan(
            title = "User's own edit",
            clientName = "Acme",
            projectName = "Redesign",
            ticketName = "",
            start = Instant.parse("2026-07-27T09:00:00Z"),
            end = Instant.parse("2026-07-27T10:00:00Z"),
            isBillable = true,
        )!!
        assertTrue("precondition: the edit is queued", queue.pendingCount(workspaceId) > 0)

        // The server has not seen it yet and echoes its own stale copy.
        server.enqueue(
            MockResponse().setHeader("Content-Type", "application/json").setBody(
                """{"results":[],"next_cursor":0}""",
            ),
        )
        server.enqueueChanges(
            listOf(
                """
                {"id":"$spanId","workspace_id":"$workspaceId","title":"Stale server title",
                 "start":"2026-07-27T09:00:00Z","end":"2026-07-27T10:00:00Z",
                 "is_billable":false,"review_state":"unreviewed","review_reasons":[],
                 "created_at":"2026-07-27T09:00:00Z","updated_at":"2026-07-27T08:00:00Z",
                 "server_revision":12}
                """.trimIndent(),
            ),
            nextCursor = 12,
            hasMore = false,
        )

        engine.sync()

        val row = db.timeSpans().byId(spanId)!!
        assertEquals(
            "the pull overwrote an edit that is STILL IN THE QUEUE -- the user " +
                "watches their change vanish while it is pending",
            "User's own edit",
            row.title,
        )
        assertTrue("and its billable flag was reverted too", row.isBillable)
        assertTrue("while the mutation is still pending", row.pendingLocal)
        assertEquals(
            "the server revision must still be recorded, for base_revision",
            12L,
            row.serverRevision,
        )
    }

    @Test
    fun `a CONFLICT adopts the authoritative row and does NOT defend the local edit`() = runTest {
        // The inverse of the pull-clobber bug, and the reason "row has a pending
        // mutation" is NOT sufficient on its own to decide preservation.
        //
        // On a pull, an unsolicited server row must not overwrite a queued local
        // edit. On a push RESULT, the server is adjudicating THE VERY MUTATION
        // in the queue -- the client's job is to adopt the authoritative row,
        // not defend an edit that just lost. Preserving here would leave a
        // rejected edit on screen looking like it succeeded.
        val spanId = repository.createManualSpan(
            title = "Local edit that will lose",
            clientName = "Acme",
            projectName = "Redesign",
            ticketName = "",
            start = Instant.parse("2026-07-27T09:00:00Z"),
            end = Instant.parse("2026-07-27T10:00:00Z"),
            isBillable = true,
        )!!
        val queued = queue.nextBatch(workspaceId).first { it.targetId == spanId }

        server.enqueuePushResults(
            """
            {"mutation_id":"${queued.mutationId}","status":"conflict","reason":"stale_write",
             "entity_kind":"time_span",
             "entity":{"id":"$spanId","workspace_id":"$workspaceId",
               "title":"Authoritative server title","start":"2026-07-27T09:00:00Z",
               "end":"2026-07-27T10:00:00Z","is_billable":false,
               "review_state":"reviewed","review_reasons":[],
               "created_at":"2026-07-27T09:00:00Z","updated_at":"2026-07-27T09:30:00Z",
               "server_revision":40}}
            """.trimIndent(),
        )
        server.enqueueChanges(emptyList(), nextCursor = 0, hasMore = false)

        engine.sync()

        val row = db.timeSpans().byId(spanId)!!
        assertEquals(
            "a conflict must adopt the server's row -- preserving the local edit " +
                "here would show the user a change the server refused",
            "Authoritative server title",
            row.title,
        )
        assertEquals(false, row.isBillable)
        assertEquals(40L, row.serverRevision)
    }

    @Test
    fun `preservation partitions fields exactly, so a new field must be classified`() = runTest {
        // Table-style assertion over the pull-preservation merge, rather than
        // spot-checking a couple of fields.
        //
        // Every content field on the incoming row differs from the local one.
        // After the pull, each field either changed (adopted from the server) or
        // did not (preserved from the local edit). Both the changed set AND the
        // total field count are pinned, so ADDING a field to TimeSpanEntity
        // fails this test until someone decides which side it belongs on --
        // which is the failure mode a field-by-field merge has and a whole-row
        // JSON merge does not.
        val spanId = repository.createManualSpan(
            title = "Local title",
            clientName = "Acme",
            projectName = "Redesign",
            ticketName = "TCK-1",
            start = Instant.parse("2026-07-27T09:00:00Z"),
            end = Instant.parse("2026-07-27T10:00:00Z"),
            isBillable = true,
            notes = "local notes",
        )!!
        val before = db.timeSpans().byId(spanId)!!

        server.enqueue(
            MockResponse().setHeader("Content-Type", "application/json")
                .setBody("""{"results":[],"next_cursor":0}"""),
        )
        server.enqueueChanges(
            listOf(
                """
                {"id":"$spanId","workspace_id":"$workspaceId","title":"SERVER title",
                 "client_name":"SERVER client","project_name":"SERVER project",
                 "ticket_name":"SERVER ticket","start":"2026-07-26T01:00:00Z",
                 "end":"2026-07-26T02:00:00Z","is_billable":false,"notes":"SERVER notes",
                 "review_state":"needs_review",
                 "review_reasons":[{"code":"billing_overlap","raised_at":"2026-07-27T10:00:00Z",
                   "raised_by":"server","resolution":"pending"}],
                 "locked_at":"2026-07-27T12:00:00Z","source":"timer",
                 "deleted_at":"2026-07-27T13:00:00Z",
                 "created_at":"2026-07-26T01:00:00Z","updated_at":"2026-07-26T01:00:00Z",
                 "updated_at_effective":"2026-07-26T01:00:00Z",
                 "origin_device_id":"other-device","server_revision":99}
                """.trimIndent(),
            ),
            nextCursor = 99,
            hasMore = false,
        )

        engine.sync()
        val after = db.timeSpans().byId(spanId)!!

        val fields = before.javaClass.declaredFields.filterNot { it.isSynthetic }
        val changed = fields.mapNotNull { f ->
            f.isAccessible = true
            f.name.takeIf { f.get(before) != f.get(after) }
        }.toSet()

        assertEquals(
            "the set of fields the server is allowed to win changed. Adopted " +
                "fields are envelope + server-authority; everything else is the " +
                "user's unsynced edit and must survive.",
            setOf(
                "serverRevision",     // base_revision accuracy
                "deletedAt",          // tombstone is absorbing (matrix row 2)
                "originDeviceId",     // LWW tie-break key, server-derived
                "updatedAtEffective", // the value LWW actually compares
                "reviewReasonsJson",  // a server-raised flag must reach the user
                "lockedAt",           // approval lock is the server's to set
            ),
            changed,
        )
        assertEquals(
            "TimeSpanEntity gained or lost a field -- classify it as adopted or " +
                "preserved above, then update this count.",
            28,
            fields.size,
        )
        // And the user's edit is intact.
        assertEquals("Local title", after.title)
        assertEquals("local notes", after.notes)
        assertTrue(after.isBillable)
    }

    // ============================================================== auth ====

    @Test
    fun `a 401 leaves the queue intact and asks for sign-in`() = runTest {
        enqueueSpanMutation("span-offline")
        server.enqueue(MockResponse().setResponseCode(401))

        val outcome = engine.sync()

        assertEquals(SyncOutcome.AuthRequired, outcome)
        assertEquals(
            "an expired session must never delete queued work",
            1,
            queue.pendingCount(workspaceId),
        )
        assertEquals(0, sessionStore.clearTokensCalls)
        assertEquals(0, sessionStore.clearAllCalls)
    }

    @Test
    fun `a transport failure is retryable and loses nothing`() = runTest {
        enqueueSpanMutation("span-net")
        server.shutdown()

        val outcome = engine.sync()

        assertTrue("expected retry, got $outcome", outcome is SyncOutcome.Retry)
        assertEquals(1, queue.pendingCount(workspaceId))
    }

    @Test
    fun `sync with no workspace is idle, not an error`() = runTest {
        val anonymous = FakeSessionStore(workspace = null)
        val idleEngine = SyncEngine(api, db, queue, anonymous, json)
        assertEquals(SyncOutcome.Idle, idleEngine.sync())
    }

    @Test
    fun `backoff is jittered, bounded, and capped at five minutes`() {
        val random = kotlin.random.Random(1234)
        for (attempt in 0..20) {
            val delay = SyncEngine.backoffMillis(attempt, random)
            assertTrue("backoff must be positive", delay > 0)
            assertTrue("backoff exceeded the 5 minute cap: $delay", delay <= 300_000)
        }
        // Full jitter means two draws at the same attempt should differ; without
        // it, every device in an office returns at the same instant.
        val draws = (1..20).map { SyncEngine.backoffMillis(8, random) }.toSet()
        assertTrue("backoff is not jittered", draws.size > 1)
    }

    // =========================================================== helpers ====

    private suspend fun enqueueSpanMutation(spanId: String): PendingMutationEntity {
        db.timeSpans().upsert(
            TimeSpanEntity(
                id = spanId,
                workspaceId = workspaceId,
                title = "Work",
                start = "2026-07-27T09:00:00Z",
                end = "2026-07-27T10:00:00Z",
                startEpochSeconds = 1_785_142_800,
                endEpochSeconds = 1_785_146_400,
                createdAt = "2026-07-27T09:00:00Z",
                updatedAt = "2026-07-27T09:00:00Z",
                pendingLocal = true,
            ),
        )
        return queue.enqueue(
            workspaceId = workspaceId,
            userId = "user-1",
            entity = com.noizu.timely.data.remote.dto.EntityKindDto.TIME_SPAN,
            op = com.noizu.timely.data.remote.dto.MutationOpDto.UPDATE,
            targetId = spanId,
            payload = json.decodeFromString(
                kotlinx.serialization.json.JsonObject.serializer(),
                """{"id":"$spanId","workspace_id":"$workspaceId","title":"Work"}""",
            ),
        )
    }

    private fun MockWebServer.enqueuePushResults(results: String) {
        enqueue(
            MockResponse()
                .setHeader("Content-Type", "application/json")
                .setBody("""{"results":[$results],"next_cursor":0}"""),
        )
    }

    private fun MockWebServer.enqueueChanges(
        spans: List<String>,
        nextCursor: Long,
        hasMore: Boolean,
        tombstoneHorizon: Long = 0,
    ) {
        enqueue(
            MockResponse()
                .setHeader("Content-Type", "application/json")
                .setBody(
                    """
                    {"changes":{"time_spans":[${spans.joinToString(",")}]},
                     "next_cursor":$nextCursor,
                     "has_more":$hasMore,
                     "tombstone_horizon_revision":$tombstoneHorizon}
                    """.trimIndent(),
                ),
        )
    }

    /** The first request whose path is the mutations endpoint. */
    private fun MockWebServer.takeRequestBody(): String {
        var request: RecordedRequest? = takeRequest()
        while (request != null && request.path?.contains("mutations") != true) {
            request = takeRequest()
        }
        return request?.body?.readUtf8().orEmpty()
    }

    private fun spanJson(
        id: String,
        revision: Long,
        deletedAt: String? = null,
        reviewState: String = "unreviewed",
        reviewReasons: String = "[]",
    ): String = """
        {"id":"$id","workspace_id":"$workspaceId","title":"Imported",
         "start":"2026-07-27T09:00:00Z","end":"2026-07-27T10:00:00Z",
         "review_state":"$reviewState","review_reasons":$reviewReasons,
         "created_at":"2026-07-27T09:00:00Z","updated_at":"2026-07-27T09:00:00Z",
         "server_revision":$revision
         ${deletedAt?.let { ""","deleted_at":"$it"""" } ?: ""}}
    """.trimIndent()
}
