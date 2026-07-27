package com.noizu.timely.core

import com.noizu.timely.core.identity.Canon
import com.noizu.timely.core.identity.TaxonomyIds
import com.noizu.timely.core.identity.Uuids
import com.noizu.timely.core.identity.canon
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.contentOrNull
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.UUID

/**
 * SYNC-PROTOCOL.md section 14 conformance gate.
 *
 * This suite is the reason `canon()` can be trusted across three independent
 * implementations. It reads `apps/shared/contracts/canon-fixtures.json`
 * *directly* -- the file is on the test resource path via a `srcDir` in
 * build.gradle.kts rather than being copied into the module, because a copied
 * fixture silently rots the moment the contract is amended and the gate then
 * passes against a stale rule.
 *
 * A failure here is never "fix the test". It is either a real divergence in
 * `canon()` or a contract change that has not been read yet.
 */
class CanonConformanceTest {

    private val fixtures: JsonObject by lazy {
        val stream = checkNotNull(
            javaClass.classLoader?.getResourceAsStream(FIXTURE_RESOURCE),
        ) {
            "$FIXTURE_RESOURCE is not on the test classpath. It is contributed by " +
                "the `sourceSets { getByName(\"test\") { resources.srcDir(...) } }` " +
                "block in app/build.gradle.kts, which points at apps/shared/contracts."
        }
        Json.parseToJsonElement(stream.bufferedReader().readText()).jsonObject
    }

    private val workspaceId: UUID by lazy {
        UUID.fromString(fixtures["workspace_id"]!!.jsonPrimitive.content)
    }

    // ------------------------------------------------------------------------
    // The fixture file declares the code point tables that canon() must use.
    // Asserting the implementation's tables against the declaration catches a
    // transcription slip (a missed range, a fat-fingered hex digit) that the
    // behavioural cases below would only catch if some case happened to exercise
    // that exact code point.
    // ------------------------------------------------------------------------

    @Test
    fun `strip code point table matches the contract`() {
        assertEquals(
            "Canon.STRIP disagrees with strip_code_points in the fixture file",
            fixtures.codePointSet("strip_code_points"),
            Canon.stripCodePoints(),
        )
    }

    @Test
    fun `whitespace code point table matches the contract`() {
        assertEquals(
            "Canon.WHITESPACE disagrees with whitespace_code_points in the fixture file",
            fixtures.codePointSet("whitespace_code_points"),
            Canon.whitespaceCodePoints(),
        )
    }

    @Test
    fun `quote code point table matches the contract`() {
        val declared = fixtures["quote_code_points"]!!.jsonObject
            .entries.associate { (key, value) ->
                parseCodePoint(key) to value.jsonPrimitive.content.single()
            }
        assertEquals(
            "Canon.QUOTES disagrees with quote_code_points in the fixture file",
            declared,
            Canon.quoteCodePoints(),
        )
    }

    @Test
    fun `ZWNJ and ZWJ are never stripped`() {
        // Called out explicitly because stripping them is the intuitive-but-wrong
        // reading of "remove invisible characters", and the damage (a broken
        // emoji ZWJ sequence, two merged Persian names) is invisible in review.
        assertTrue(0x200C !in Canon.stripCodePoints())
        assertTrue(0x200D !in Canon.stripCodePoints())
    }

    // ------------------------------------------------------------------------
    // Every canon case the fixture carries. The count is deliberately not
    // written down here -- the corpus grows, and a number in a comment is the
    // same coupling the floor assertion below exists to avoid.
    // ------------------------------------------------------------------------

    @Test
    fun `all canon cases conform`() {
        val cases = fixtures["canon_cases"]!!.jsonArray

        // A FLOOR, not an equality.
        //
        // The property worth protecting is "every case in the fixture passes",
        // and "there are exactly N" is not that property -- it just couples this
        // file to the corpus, so growing the contract breaks a green suite for
        // no safety benefit. The floor still catches the failure that an
        // equality was really guarding against: a fixture that failed to load,
        // got truncated, or silently emptied, which would otherwise make this
        // test pass by iterating nothing.
        assertTrue(
            "canon corpus SHRANK to ${cases.size} (floor $MIN_CANON_CASES). " +
                "Growth is fine and needs no change here; shrinkage means the " +
                "fixture is truncated or failed to parse.",
            cases.size >= MIN_CANON_CASES,
        )

        val failures = mutableListOf<String>()

        for (element in cases) {
            val case = element.jsonObject
            val id = case.str("id")
            val group = case.str("group")
            val input = case.str("input")
            val expectedOutput = case.str("expected_output")

            val actual = canon(input)
            if (actual != expectedOutput) {
                failures += "$id [$group] canon(${input.describe()})\n" +
                    "    expected ${expectedOutput.describe()}\n" +
                    "    actual   ${actual.describe()}"
                continue
            }

            // The fixture spells out the expected code points as well as the
            // string. They cannot disagree, but asserting both means a failure
            // report names the offending code point instead of printing two
            // strings that look identical in a terminal.
            val expectedCodePoints = case["expected_output_codepoints"]!!.jsonArray
                .map { parseCodePoint(it.jsonPrimitive.content) }
            if (actual.codePoints().toArray().toList() != expectedCodePoints) {
                failures += "$id [$group] code point mismatch\n" +
                    "    expected ${expectedCodePoints.joinToString(" ") { formatCodePoint(it) }}\n" +
                    "    actual   ${actual.codePointNames()}"
                continue
            }

            // The derived client key, and the id minted from it.
            val expectedKey = case.str("expected_client_key")
            val actualKey = TaxonomyIds.clientKey(input)
            if (actualKey != expectedKey) {
                failures += "$id [$group] client key: expected '$expectedKey', got '$actualKey'"
                continue
            }

            val expectedId = case["expected_client_id"]
            val actualId = TaxonomyIds.clientIdOrNull(workspaceId, input)
            if (expectedId == null || expectedId is JsonNull) {
                // The four empty/whitespace-only cases. "No reference", not an
                // entity named "". Minting an id here would create a junk row
                // on every device that saw a blank name.
                if (actualId != null) {
                    failures += "$id [$group] MINTED AN ENTITY FOR A BLANK NAME: " +
                        "expected null, got ${Uuids.format(actualId)}"
                }
            } else {
                val want = expectedId.jsonPrimitive.content
                if (actualId == null || Uuids.format(actualId) != want) {
                    failures += "$id [$group] client id: expected $want, got " +
                        (actualId?.let(Uuids::format) ?: "null")
                }
            }
        }

        assertTrue(
            "${failures.size} of ${cases.size} canon fixture cases failed:\n\n" +
                failures.joinToString("\n\n"),
            failures.isEmpty(),
        )
    }

    // ------------------------------------------------------------------------
    // Composite (project / ticket) keys.
    // ------------------------------------------------------------------------

    @Test
    fun `all composite cases conform`() {
        val cases = fixtures["composite_cases"]!!.jsonArray
        assertTrue(
            "composite corpus SHRANK to ${cases.size} (floor $MIN_COMPOSITE_CASES).",
            cases.size >= MIN_COMPOSITE_CASES,
        )
        val failures = mutableListOf<String>()

        for (element in cases) {
            val case = element.jsonObject
            val id = case.str("id")
            val kind = case.str("kind")
            val input = case["input"]!!.jsonObject

            val clientName = input.strOrNull("client_name")
            val projectName = input.strOrNull("project_name")
            val name = input.str("name")

            val actualKey: String
            val actualId: UUID?
            when (kind) {
                "project" -> {
                    actualKey = TaxonomyIds.projectKey(clientName ?: "", name)
                    actualId = TaxonomyIds.projectIdOrNull(workspaceId, clientName, name)
                }
                "ticket" -> {
                    actualKey = TaxonomyIds.ticketKey(clientName ?: "", projectName ?: "", name)
                    actualId = TaxonomyIds.ticketIdOrNull(workspaceId, clientName, projectName, name)
                }
                else -> {
                    failures += "$id unknown composite kind '$kind'"
                    continue
                }
            }

            val expectedKey = case.str("expected_key")
            if (actualKey != expectedKey) {
                failures += "$id [$kind] key: expected '$expectedKey', got '$actualKey'"
                continue
            }

            val expectedId = case["expected_id"]
            if (expectedId == null || expectedId is JsonNull) {
                if (actualId != null) {
                    failures += "$id [$kind] expected no entity, got ${Uuids.format(actualId)}"
                }
            } else {
                val want = expectedId.jsonPrimitive.content
                if (actualId == null || Uuids.format(actualId) != want) {
                    failures += "$id [$kind] id: expected $want, got " +
                        (actualId?.let(Uuids::format) ?: "null")
                }
            }
        }

        assertTrue(
            "${failures.size} of ${cases.size} composite fixture cases failed:\n\n" +
                failures.joinToString("\n\n"),
            failures.isEmpty(),
        )
    }

    // ------------------------------------------------------------------------
    // Properties the fixtures imply but do not state case-by-case.
    // ------------------------------------------------------------------------

    @Test
    fun `canon is idempotent across every fixture input`() {
        // canon(canon(s)) == canon(s). The server stores canonical_name and the
        // client re-canonicalizes on edit; if the function were not idempotent,
        // a name would drift a little on every round trip.
        for (element in fixtures["canon_cases"]!!.jsonArray) {
            val input = element.jsonObject.str("input")
            val once = canon(input)
            assertEquals("canon is not idempotent for ${input.describe()}", once, canon(once))
        }
    }

    @Test
    fun `lowercasing does not depend on the default locale`() {
        // The Turkish trap, exercised directly rather than trusted. Locale.ROOT
        // is passed explicitly inside canon(), but a future refactor that drops
        // the argument would still pass every fixture case on a US machine and
        // fail only on a Turkish handset.
        val original = java.util.Locale.getDefault()
        try {
            java.util.Locale.setDefault(java.util.Locale.forLanguageTag("tr-TR"))
            assertEquals("istanbul", canon("ISTANBUL"))
            assertEquals("acme", canon("ACME"))
            assertEquals("invoice", canon("INVOICE"))
        } finally {
            java.util.Locale.setDefault(original)
        }
    }

    @Test
    fun `final sigma converges regardless of position`() {
        // Fixtures 028 and 029 in one assertion, stated as the property they
        // exist to protect: Java's Final_Sigma context rule must not fork the id.
        assertEquals(canon("ΟΔΥΣΣΕΥΣ"), canon("οδυσσευς"))
        assertEquals(
            TaxonomyIds.clientIdOrNull(workspaceId, "ΟΔΥΣΣΕΥΣ"),
            TaxonomyIds.clientIdOrNull(workspaceId, "οδυσσευς"),
        )
        assertTrue("final sigma survived canon()", canon("ΟΔΥΣΣΕΥΣ").none { it == 'ς' })
    }

    @Test
    fun `smart apostrophes converge with the ASCII spelling`() {
        // The cross-device duplicate generator this product actually has: iOS
        // autocorrect emits U+2019 where an Android soft keyboard emits U+0027.
        val ascii = TaxonomyIds.clientIdOrNull(workspaceId, "Bob's Diner")
        assertNotNull(ascii)
        for (smart in listOf('‘', '’', '‚', '‛', 'ʼ')) {
            assertEquals(
                "U+%04X did not converge with U+0027".format(smart.code),
                ascii,
                TaxonomyIds.clientIdOrNull(workspaceId, "Bob${smart}s Diner"),
            )
        }
    }

    @Test
    fun `blank names never mint an entity`() {
        for (blank in listOf("", "   ", "\t\n", "​", "﻿­", "　 ")) {
            assertNull(
                "canon(${blank.describe()}) minted a client",
                TaxonomyIds.clientIdOrNull(workspaceId, blank),
            )
            assertTrue(Canon.isBlank(blank))
            assertNull(Canon.canonOrNull(blank))
        }
    }

    // ------------------------------------------------------------- helpers ----

    private fun JsonObject.str(key: String): String =
        this[key]!!.jsonPrimitive.content

    private fun JsonObject.strOrNull(key: String): String? =
        this[key]?.jsonPrimitive?.contentOrNull

    private fun JsonObject.codePointSet(key: String): Set<Int> =
        this[key]!!.jsonArray.map { parseCodePoint(it.jsonPrimitive.content) }.toSet()

    /** "U+00AD" -> 0x00AD. */
    private fun parseCodePoint(token: String): Int =
        token.removePrefix("U+").toInt(16)

    private fun formatCodePoint(codePoint: Int): String = "U+%04X".format(codePoint)

    private fun String.codePointNames(): String =
        codePoints().toArray().joinToString(" ") { formatCodePoint(it) }

    /** Render a string so invisible differences are visible in a failure message. */
    private fun String.describe(): String =
        if (isEmpty()) "\"\" (empty)" else "\"$this\" [${codePointNames()}]"

    private companion object {
        const val FIXTURE_RESOURCE = "canon-fixtures.json"

        /**
         * Floors, deliberately not exact counts.
         *
         * These were the corpus sizes when the §14 gate was first met. They
         * exist to catch a fixture that did not load, not to pin a number that
         * the contract is expected to grow past.
         */
        const val MIN_CANON_CASES = 65
        const val MIN_COMPOSITE_CASES = 8
    }
}
