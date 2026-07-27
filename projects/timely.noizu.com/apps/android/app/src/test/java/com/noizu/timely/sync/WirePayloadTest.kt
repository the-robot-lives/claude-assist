package com.noizu.timely.sync

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import com.noizu.timely.data.local.TimelyDatabase
import com.noizu.timely.data.remote.TimelyApi
import com.noizu.timely.data.repo.TimelyRepository
import com.noizu.timely.data.sync.PushQueue
import com.noizu.timely.data.sync.SyncEngine
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.contentOrNull
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.RecordedRequest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import retrofit2.Retrofit
import java.time.Instant

/**
 * The `end` omission-versus-null trap, asserted on real bytes.
 *
 * `"end": null` and an absent `end` are semantically DIFFERENT on the wire:
 *
 *   - `"end": null`  = a deliberate reopen of a closed span (matrix row 7,
 *                      allowed when `base_revision` is current)
 *   - `end` absent   = a partial update that does not touch the field; a stale
 *                      one is rejected as `span_reopen_forbidden` (matrix row 6)
 *
 * A client that always serializes `end` would send an unintended reopen on every
 * ordinary edit of an open span and trip the guard. The failure is invisible in
 * object-level tests because the DTO round-trips identically either way -- only
 * the bytes differ. So these tests read the actual JSON.
 *
 * Both serialization hops are checked, because either one could drop a JsonNull:
 *   1. the payload as stored in the durable push queue, and
 *   2. the payload as it actually leaves the device, taken off MockWebServer.
 *
 * The `Json` instance here is configured identically to the one in `AppModule`
 * (`explicitNulls = false` in particular) -- a test that used a default `Json`
 * would prove nothing about what the app ships.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33], manifest = Config.NONE)
class WirePayloadTest {

    private lateinit var server: MockWebServer
    private lateinit var db: TimelyDatabase
    private lateinit var api: TimelyApi
    private lateinit var queue: PushQueue
    private lateinit var engine: SyncEngine
    private lateinit var repository: TimelyRepository
    private lateinit var session: FakeSessionStore

    /** Mirrors AppModule.json() exactly. */
    private val json = Json {
        ignoreUnknownKeys = true
        explicitNulls = false
        encodeDefaults = true
        coerceInputValues = true
    }

    private val workspaceId = FakeSessionStore.WORKSPACE_ID

    @Before
    fun setUp() {
        server = MockWebServer().apply { start() }
        val context = ApplicationProvider.getApplicationContext<Context>()
        db = Room.inMemoryDatabaseBuilder(context, TimelyDatabase::class.java)
            .allowMainThreadQueries().build()
        api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().build())
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()
            .create(TimelyApi::class.java)
        queue = PushQueue(db, json)
        session = FakeSessionStore()
        repository = TimelyRepository(db, queue, session, json)
        engine = SyncEngine(api, db, queue, session, json)
    }

    @After
    fun tearDown() {
        server.shutdown()
        db.close()
    }

    // ------------------------------------------------------- the queue hop --

    @Test
    fun `an ordinary edit of an OPEN span OMITS end entirely`() = runTest {
        val spanId = openSpan()
        drainQueue()

        repository.updateSpan(spanId = spanId, title = "Renamed")

        val payload = latestPayloadFor(spanId)
        assertFalse(
            "an ordinary edit must not mention `end` at all -- serializing it as " +
                "null would read as a deliberate reopen and trip the guard.\n  payload: $payload",
            payload.containsKey("end"),
        )
        assertTrue(payload.raw.contains("\"title\":\"Renamed\""))
    }

    @Test
    fun `an ordinary edit of a CLOSED span keeps the existing end value`() = runTest {
        val spanId = closedSpan()
        drainQueue()

        repository.updateSpan(spanId = spanId, title = "Renamed")

        val payload = latestPayloadFor(spanId)
        assertTrue("the existing end should be echoed, not dropped", payload.containsKey("end"))
        assertFalse("and it must not be null", payload.isNull("end"))
        assertTrue(payload.raw.contains("\"end\":\"2026-07-27T10:00:00Z\""))
    }

    @Test
    fun `a deliberate reopen sends an EXPLICIT null end`() = runTest {
        val spanId = closedSpan()
        drainQueue()

        repository.updateSpan(spanId = spanId, clearEnd = true)

        val payload = latestPayloadFor(spanId)
        assertTrue(
            "a reopen must carry the key.\n  payload: $payload",
            payload.containsKey("end"),
        )
        assertTrue(
            "explicitNulls=false must NOT strip a JsonNull placed inside a " +
                "JsonObject -- if it does, reopen becomes unexpressible.\n  payload: $payload",
            payload.isNull("end"),
        )
        assertTrue(payload.raw.contains("\"end\":null"))
    }

    @Test
    fun `creating an open span omits end rather than sending null`() = runTest {
        openSpan()
        val payload = allPayloads().last()
        assertFalse(
            "a create for an open span should omit `end`.\n  payload: $payload",
            payload.containsKey("end"),
        )
    }

    // -------------------------------------------------------- the wire hop --

    @Test
    fun `the bytes that actually leave the device preserve omission and null`() = runTest {
        // The queue hop is not the only place a null can be lost: the payload is
        // decoded from the queue and re-serialized by the Retrofit converter on
        // the way out. This asserts the bytes on the socket.
        val open = openSpan()
        val closed = closedSpan()
        drainQueue()

        repository.updateSpan(spanId = open, title = "Ordinary edit")
        repository.updateSpan(spanId = closed, clearEnd = true)

        server.enqueuePushAccepting()
        server.enqueueEmptyChanges()
        engine.sync()

        val body = server.mutationRequestBody()

        // Split the two mutation payloads apart so an assertion cannot pass by
        // finding the other mutation's `end`.
        val ordinary = body.substringAfter(open).substringBefore("mutation_id").let {
            body.extractPayloadContaining(open)
        }
        val reopen = body.extractPayloadContaining(closed)

        assertFalse(
            "ordinary edit leaked an `end` key onto the wire:\n  $ordinary",
            Regex("\"end\"\\s*:").containsMatchIn(ordinary),
        )
        assertTrue(
            "reopen lost its explicit null on the wire:\n  $reopen",
            Regex("\"end\"\\s*:\\s*null").containsMatchIn(reopen),
        )
    }

    @Test
    fun `omitting end is what lets a remote close survive an innocent edit`() = runTest {
        // Reasoning from the server guard:
        //
        //   reopening? = existing.end_at != nil
        //                and Map.has_key?(payload, "end")
        //                and payload["end"] == nil
        //
        // Scenario: this device thinks the span is open; another device closed
        // it; the user retitles. Because the payload has NO `end` key,
        // `Map.has_key?` is false, the guard cannot fire, and the retitle merges
        // while the close survives.
        //
        // Had this client sent `"end": null` here -- an accurate statement of
        // "my copy is open", but an unnecessary one -- the guard WOULD fire and
        // the retitle would come back as span_reopen_forbidden. So omission is
        // not merely harmless, it is what avoids that rejection.
        val spanId = openSpan()
        drainQueue()

        repository.updateSpan(spanId = spanId, title = "Innocent retitle")

        val payload = latestPayloadFor(spanId)
        assertFalse(
            "the guard keys off Map.has_key?, so the key must be ABSENT, not null",
            payload.containsKey("end"),
        )
        assertTrue("...while the rest of the document is still sent", payload.containsKey("title"))
        assertTrue(payload.containsKey("start"))
    }

    @Test
    fun `locked_at is never sent, so this client cannot clear an approval lock`() = runTest {
        // WHY this is never-send has CHANGED. It is no longer "unsafe"; it is
        // "safe but unnecessary."
        //
        // It was unsafe: `guard_locked` had no base_revision check, so an admin
        // whose copy had not yet pulled a lock could clear a billing-approval
        // lock purely by serialization default -- an unconditional
        // `"locked_at": null` sailed through the admin escape hatch.
        //
        // The server has since added a base_revision check symmetric with
        // `guard_reopen`. A stale unlock is now rejected with its own message,
        // and a client whose base_revision IS current has by definition seen the
        // lock -- so its local copy holds the timestamp and it would send that,
        // not null. The accidental path is closed server-side.
        //
        // Never-send remains correct anyway, as the safer default: Android has
        // no deliberate unlock affordance, so it has nothing true to say about
        // this field. Enabling US-068 (admin reopen-after-approval) would need a
        // real affordance plus a confirmation step -- a product decision, not a
        // serialization change. Until then, silence is the honest value.
        exerciseEveryWrite()

        for (payload in allPayloads()) {
            assertFalse(
                "a payload gained a `locked_at` key -- if this is deliberate, it " +
                    "MUST be conditional (omit when absent, explicit null only for " +
                    "an intentional admin unlock), never unconditional.\n  $payload",
                payload.containsKey("locked_at"),
            )
        }
    }

    @Test
    fun `end under a deliberate clear is the ONLY explicit null this client ever sends`() = runTest {
        // The generalization of the locked_at bug class. Rather than audit each
        // presence-sensitive field the server happens to have today, assert the
        // invariant from this side: every nullable field is OMITTED when absent,
        // and the single exception is `end`, which is an explicit null only
        // because a deliberate reopen would otherwise be unexpressible.
        //
        // Any future field that starts serializing an unconditional null fails
        // here, whether or not anyone remembered it was presence-sensitive.
        exerciseEveryWrite()

        val offenders = mutableListOf<String>()
        for (payload in allPayloads()) {
            for (key in payload.explicitNullKeys()) {
                if (key !in ALLOWED_EXPLICIT_NULLS) offenders += "$key in $payload"
            }
        }

        assertTrue(
            "payloads carried unconditional nulls beyond $ALLOWED_EXPLICIT_NULLS.\n" +
                "Each is a candidate instance of the locked_at bug class: if the " +
                "server treats the field as presence-sensitive, an always-null is " +
                "an assertion the user never made.\n  " + offenders.joinToString("\n  "),
            offenders.isEmpty(),
        )
    }

    @Test
    fun `every payload carries a genuine origin_device_id`() = runTest {
        // This asserts a CHOICE, not a server requirement.
        //
        // The server once adjudicated ties on the raw payload, so omitting the
        // key compared "" against a real device id and lost every tie. That has
        // been fixed -- the server now derives once and uses the same value for
        // storage and adjudication (fixtures wire-090..092) -- so omission is no
        // longer a bug.
        //
        // We still send, because sending is correct against both the fixed and
        // the unfixed server while omitting is correct only against the fixed
        // one. This test exists to stop a silent drift back to omission, which
        // would be safe today and unsafe against any deployment that has not
        // taken the fix.
        //
        // Non-emptiness is asserted, not merely presence: `|| ""` collapses a
        // null to the same losing empty string, so a presence-only assertion
        // would pass on a null and prove nothing.
        exerciseEveryWrite()

        val payloads = allPayloads()
        assertTrue("precondition: writes produced payloads", payloads.isNotEmpty())
        for (payload in payloads) {
            assertTrue(
                "payload omits origin_device_id and will LOSE every tie.\n  $payload",
                payload.containsKey("origin_device_id"),
            )
            assertFalse(
                "null origin_device_id is degraded, not neutral -- `|| \"\"` " +
                    "makes it lose exactly as omission does.\n  $payload",
                payload.isNull("origin_device_id"),
            )
            assertTrue(
                "origin_device_id must be a real id, not empty.\n  $payload",
                payload.stringValue("origin_device_id").orEmpty().isNotBlank(),
            )
        }
    }

    @Test
    fun `the wire uses start and end, never start_at or end_at`() = runTest {
        closedSpan()
        server.enqueuePushAccepting()
        server.enqueueEmptyChanges()
        engine.sync()

        val body = server.mutationRequestBody()
        assertTrue("`start` is the wire name", body.contains("\"start\":"))
        assertFalse("`start_at` is a SQL column, not a wire field", body.contains("start_at"))
        assertFalse("`end_at` is a SQL column, not a wire field", body.contains("end_at"))
    }

    @Test
    fun `no pushed payload ever carries a server-owned or server-managed field`() = runTest {
        // `blob_available` is derived server-side from upload_state and is never
        // stored, so a client must not try to set it. On Android this is
        // structurally impossible -- screenshots are not a pushable entity at
        // all -- but assert the bytes rather than the reasoning.
        exerciseEveryWrite()
        server.enqueuePushAccepting()
        server.enqueueEmptyChanges()
        engine.sync()

        val body = server.mutationRequestBody()
        for (forbidden in SERVER_OWNED + SERVER_MANAGED) {
            assertFalse(
                "pushed payload carried server-owned `$forbidden`.\n  $body",
                body.contains("\"$forbidden\""),
            )
        }
    }

    // ----------------------------------------------------------- fixtures ---

    private suspend fun openSpan(): String = repository.createManualSpan(
        title = "Open work",
        clientName = "Acme",
        projectName = "Redesign",
        ticketName = "",
        start = Instant.parse("2026-07-27T09:00:00Z"),
        end = null,
        isBillable = true,
    )!!

    private suspend fun closedSpan(): String = repository.createManualSpan(
        title = "Closed work",
        clientName = "Acme",
        projectName = "Redesign",
        ticketName = "",
        start = Instant.parse("2026-07-27T09:00:00Z"),
        end = Instant.parse("2026-07-27T10:00:00Z"),
        isBillable = true,
    )!!

    /**
     * Every write path that mints a mutation, so the null-audit above sees the
     * whole payload surface rather than whichever operation a test happened to
     * call. If a new write path is added and not listed here, the audit silently
     * stops covering it -- so this list is the thing to update.
     */
    private suspend fun exerciseEveryWrite() {
        val open = openSpan()
        val closed = closedSpan()
        repository.updateSpan(spanId = open, title = "Retitled")
        repository.updateSpan(spanId = closed, isBillable = false)
        repository.updateSpan(spanId = closed, clearEnd = true)
        repository.updateSpan(
            spanId = open,
            clientName = "Globex",
            projectName = "Migration",
            ticketName = "TCK-1",
        )
        repository.updateSpan(spanId = open, end = Instant.parse("2026-07-27T11:00:00Z"))
        repository.approveSpans(listOf(open))
        repository.splitSpan(closed, listOf(Instant.parse("2026-07-27T09:30:00Z")))
        val a = openSpan()
        val b = closedSpan()
        repository.mergeSpans(listOf(a, b))
    }

    /** Forget the creates so a later assertion looks at the edit, not the create. */
    private suspend fun drainQueue() {
        db.pendingMutations().clearForWorkspace(workspaceId)
    }

    private class Payload(val raw: String) {
        private val obj = Json.parseToJsonElement(raw) as kotlinx.serialization.json.JsonObject
        fun containsKey(key: String) = obj.containsKey(key)
        fun isNull(key: String) = obj[key] is kotlinx.serialization.json.JsonNull
        fun stringValue(key: String): String? =
            (obj[key] as? kotlinx.serialization.json.JsonPrimitive)?.contentOrNull

        /** Keys present with a literal JSON null, at any nesting depth. */
        fun explicitNullKeys(): Set<String> = collect(obj)

        private fun collect(
            element: kotlinx.serialization.json.JsonElement,
            into: MutableSet<String> = mutableSetOf(),
        ): Set<String> {
            when (element) {
                is kotlinx.serialization.json.JsonObject ->
                    for ((k, v) in element) {
                        if (v is kotlinx.serialization.json.JsonNull) into += k else collect(v, into)
                    }
                is kotlinx.serialization.json.JsonArray -> element.forEach { collect(it, into) }
                else -> Unit
            }
            return into
        }
        override fun toString() = raw
    }

    private suspend fun allPayloads(): List<Payload> =
        db.pendingMutations().all(workspaceId).map { Payload(it.payloadJson) }

    private suspend fun latestPayloadFor(spanId: String): Payload =
        db.pendingMutations().all(workspaceId)
            .last { it.targetId == spanId }
            .let { Payload(it.payloadJson) }

    /**
     * `end` earns its exception: a deliberate reopen is unexpressible without an
     * explicit null. Nothing else should ever be on this list -- adding to it
     * means claiming the server is NOT presence-sensitive for that field, which
     * is a claim to verify against the backend, not to assume.
     */
    private val ALLOWED_EXPLICIT_NULLS = setOf("end")

    /**
     * The contract's server-owned list, verbatim: "written by the server and
     * only by the server ... Server-owned fields MUST NOT appear in a payload."
     *
     * The contract itself asks clients to assert this at the byte level, on the
     * reasoning that "ignored" is weaker than it sounds -- a client that SENDS
     * one has a model that believes it may set it, and that belief is the bug.
     */
    private val SERVER_OWNED = listOf(
        "server_revision",
        "updated_at_effective",
        "canonical_name",
        "upload_state",
        "blob_available",
        "blob_content_hash",
        "blob_byte_size",
        "blob_uploaded_at",
        "blob_url",
        "raw_response_withheld",
    )

    /**
     * NOT on the contract's list, but server-managed in practice, and both are
     * fields where a client sending its own copy causes a real defect:
     *
     * - `merged_into_id` has no presence check server-side -- a plain cast, so a
     *   null SETS the column. A client that had not pulled a merge would
     *   UN-MERGE the row on its next ordinary edit and break the reference
     *   redirection that `Sync.Resolver` does by following the pointer.
     * `origin_device_id` deliberately is NOT here -- we SEND it. The server has
     * been fixed to adjudicate on the derived value rather than the raw payload
     * (fixtures wire-090..092), so omitting would now be safe too. We send it
     * because sending is correct against both the fixed and the unfixed server
     * while omitting is correct only against the fixed one, and a wrong choice
     * here has no symptom -- a lost tie looks exactly like the other device
     * winning fairly.
     */
    private val SERVER_MANAGED = listOf("merged_into_id")

    private fun MockWebServer.enqueuePushAccepting() {
        // Every mutation is answered `applied` by mutation_id echo. The body is
        // built after the fact from the request, so this responds generically.
        enqueue(
            MockResponse()
                .setHeader("Content-Type", "application/json")
                .setBody("""{"results":[],"next_cursor":0}"""),
        )
    }

    private fun MockWebServer.enqueueEmptyChanges() {
        enqueue(
            MockResponse()
                .setHeader("Content-Type", "application/json")
                .setBody(
                    """{"changes":{},"next_cursor":0,"has_more":false,
                        "tombstone_horizon_revision":0}""".trimIndent(),
                ),
        )
    }

    private fun MockWebServer.mutationRequestBody(): String {
        var request: RecordedRequest? = takeRequest()
        while (request != null && request.path?.contains("mutations") != true) {
            request = takeRequest()
        }
        return request?.body?.readUtf8().orEmpty()
    }

    /** The single mutation object whose payload targets [id]. */
    private fun String.extractPayloadContaining(id: String): String {
        val objects = Regex("\\{\"mutation_id\".*?(?=\\{\"mutation_id\"|]\\})", RegexOption.DOT_MATCHES_ALL)
            .findAll(this).map { it.value }.toList()
        return objects.firstOrNull { it.contains(id) }
            ?: substring(indexOf(id).coerceAtLeast(0))
    }
}
