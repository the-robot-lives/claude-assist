package com.noizu.timely.core.identity

import java.text.Normalizer
import java.util.Locale

/**
 * Canonical name normalization, per SYNC-PROTOCOL.md section 3.3 and the
 * executable fixtures in `apps/shared/contracts/canon-fixtures.json`.
 *
 * This function MUST behave identically here, in Elixir, and in Swift. Any
 * divergence silently produces duplicate taxonomy rows: two devices vivifying
 * "Acme" compute different UUIDv5s and the server happily stores both. Nothing
 * throws and nothing logs -- the workspace just grows a second row.
 *
 * The eight steps, in order (fixture `canon_algorithm`):
 *   1. Strip the enumerated invisible formatting code points.
 *   2. NFKC normalization.
 *   3. Map the enumerated smart-quote code points to their ASCII equivalents.
 *   4. Replace every enumerated whitespace code point with U+0020.
 *   5. Collapse runs of U+0020 to one; trim leading and trailing U+0020.
 *   6. Lowercase, locale-independent.
 *   7. Map U+03C2 FINAL SIGMA to U+03C3.
 *   8. NFC normalization.
 *
 * Deliberate non-goals, each pinned by a fixture (do not "fix" these):
 *   - This is *lowercase*, not case folding. "Straße" != "strasse".
 *   - Diacritics are not folded. "Muñoz" != "Munoz".
 *   - Quote mapping is a fixed closed set, not general punctuation folding.
 *     "Acme, Inc." != "Acme Inc".
 */
object Canon {

    /**
     * Step 1. Invisible formatting noise that survives copy-paste: soft hyphen,
     * zero-width space, the LTR/RTL marks, the bidi embedding/override controls,
     * the bidi isolates, and the byte-order mark.
     *
     * U+200C ZWNJ and U+200D ZWJ are deliberately absent. They are semantically
     * significant in Indic and Persian text and they hold emoji ZWJ sequences
     * together -- stripping them would turn a family emoji into three people and
     * would merge two genuinely different Persian names.
     */
    private val STRIP: Set<Int> = buildSet {
        add(0x00AD)                       // SOFT HYPHEN
        add(0x200B)                       // ZERO WIDTH SPACE
        add(0x200E); add(0x200F)          // LRM, RLM
        addAll(0x202A..0x202E)            // LRE, RLE, PDF, LRO, RLO
        addAll(0x2066..0x2069)            // LRI, RLI, FSI, PDI
        add(0xFEFF)                       // ZERO WIDTH NO-BREAK SPACE / BOM
    }

    /**
     * Step 3. Smart-quote substitution is what a keyboard or autocorrect emits
     * *in place of* the plain ASCII key, so these are the same character as far
     * as a human naming a client is concerned. iOS emits U+2019 where a desktop
     * keyboard emits U+0027; without this step "Bob's Diner" typed on an iPhone
     * and on a Mac mint two different clients.
     *
     * U+02BC is included even though in a few orthographies it is a letter (a
     * glottal stop) rather than punctuation. That conflation is accepted and
     * recorded in the fixture's `known_limitations`.
     */
    private val QUOTES: Map<Int, Char> = mapOf(
        0x02BC to '\'',   // MODIFIER LETTER APOSTROPHE
        0x2018 to '\'',   // LEFT SINGLE QUOTATION MARK
        0x2019 to '\'',   // RIGHT SINGLE QUOTATION MARK
        0x201A to '\'',   // SINGLE LOW-9 QUOTATION MARK
        0x201B to '\'',   // SINGLE HIGH-REVERSED-9 QUOTATION MARK
        0x201C to '"',    // LEFT DOUBLE QUOTATION MARK
        0x201D to '"',    // RIGHT DOUBLE QUOTATION MARK
        0x201E to '"',    // DOUBLE LOW-9 QUOTATION MARK
        0x201F to '"',    // DOUBLE HIGH-REVERSED-9 QUOTATION MARK
    )

    /**
     * Step 4. The Unicode `White_Space=Yes` set, enumerated explicitly.
     *
     * It is spelled out rather than delegated to [Character.isWhitespace] or
     * [Character.isSpaceChar] because those predicates disagree with each other
     * and with the other two runtimes: `isWhitespace` excludes the no-break
     * spaces (U+00A0, U+202F) while `isSpaceChar` excludes the control-ish ones
     * (tab, LF, CR, U+0085). Neither alone is the spec's set, and "the union
     * happens to match" is not a property any of the three runtimes promises.
     *
     * Note U+1680 OGHAM SPACE MARK: NFKC does not map it, so step 2 does not
     * make this step redundant.
     */
    private val WHITESPACE: Set<Int> = buildSet {
        addAll(0x0009..0x000D)            // TAB, LF, VT, FF, CR
        add(0x0020)                       // SPACE
        add(0x0085)                       // NEXT LINE
        add(0x00A0)                       // NO-BREAK SPACE
        add(0x1680)                       // OGHAM SPACE MARK
        addAll(0x2000..0x200A)            // EN QUAD .. HAIR SPACE
        add(0x2028); add(0x2029)          // LINE / PARAGRAPH SEPARATOR
        add(0x202F)                       // NARROW NO-BREAK SPACE
        add(0x205F)                       // MEDIUM MATHEMATICAL SPACE
        add(0x3000)                       // IDEOGRAPHIC SPACE
    }

    private const val FINAL_SIGMA = 'ς'
    private const val SIGMA = 'σ'

    /**
     * The Turkish trap.
     *
     * `String.lowercase()` with no argument uses the *default locale*. On a
     * device set to Turkish or Azeri, 'I' (U+0049) lowercases to 'ı' (U+0131,
     * dotless i) rather than 'i'. `canon("INVOICE")` would then be "ınvoice" on
     * that device and "invoice" everywhere else, so the two compute different
     * UUIDv5s for the same client and the workspace grows a duplicate row.
     *
     * Nothing throws, nothing logs, and the bug only reproduces on a Turkish
     * handset. [Locale.ROOT] is the fix and is not optional.
     */
    private val CASE_LOCALE: Locale = Locale.ROOT

    fun canon(input: String): String {
        // Step 2 (NFKC) must run BETWEEN strip and quote-map: U+0149 LATIN SMALL
        // LETTER N PRECEDED BY APOSTROPHE NFKC-decomposes to U+02BC + U+006E, so
        // a quote map applied before NFKC would leave that U+02BC behind and
        // diverge from the ASCII spelling. U+0149 is the only code point Unicode
        // NFKC maps into the quote target set, and a fixture pins it.
        //
        // Steps 3, 4 and 5 then fuse into one pass: the quote set and the
        // whitespace set are disjoint, so their relative order is free.
        val stripped = stripInvisibles(input)
        val normalized = Normalizer.normalize(stripped, Normalizer.Form.NFKC)
        val squeezed = mapQuotesAndSqueezeWhitespace(normalized)

        // Step 6, then step 7. Order matters: Java applies the Unicode
        // Final_Sigma context rule during lowercasing and emits U+03C2, so the
        // mapping has to come after, not before. Elixir's :default downcase does
        // not apply Final_Sigma and emits U+03C3 directly; this step is what
        // makes the two agree.
        val lowered = squeezed.lowercase(CASE_LOCALE).replace(FINAL_SIGMA, SIGMA)

        // Step 8. Recompose anything the case mapping decomposed.
        return Normalizer.normalize(lowered, Normalizer.Form.NFC)
    }

    /** Step 1, as its own pass so it lands before NFKC. */
    private fun stripInvisibles(input: String): String {
        // Fast path: the overwhelming majority of names contain none of these,
        // and this runs on every keystroke in the manual-entry screen.
        var index = 0
        var found = false
        while (index < input.length) {
            val codePoint = input.codePointAt(index)
            if (codePoint in STRIP) { found = true; break }
            index += Character.charCount(codePoint)
        }
        if (!found) return input

        val builder = StringBuilder(input.length)
        index = 0
        while (index < input.length) {
            val codePoint = input.codePointAt(index)
            index += Character.charCount(codePoint)
            if (codePoint !in STRIP) builder.appendCodePoint(codePoint)
        }
        return builder.toString()
    }

    /** Steps 3, 4 and 5 in a single pass. */
    private fun mapQuotesAndSqueezeWhitespace(input: String): String {
        val builder = StringBuilder(input.length)
        var pendingSpace = false
        var emitted = false
        var index = 0
        while (index < input.length) {
            val codePoint = input.codePointAt(index)
            index += Character.charCount(codePoint)

            if (codePoint in WHITESPACE) {
                // Only remember that a gap occurred; emit lazily. Trailing
                // whitespace therefore never reaches the output and interior
                // runs collapse to one, so steps 4 and 5 need no second pass.
                if (emitted) pendingSpace = true
                continue
            }

            if (pendingSpace) {
                builder.append(' ')
                pendingSpace = false
            }

            val quote = QUOTES[codePoint]
            if (quote != null) builder.append(quote) else builder.appendCodePoint(codePoint)
            emitted = true
        }
        return builder.toString()
    }

    /**
     * An empty name after canonicalization is not an entity (protocol 3.3, 6.1
     * step 5). Callers use this to distinguish "no reference" from "a row named
     * nothing" -- the server treats `""` as the former and MUST NOT create a row.
     */
    fun isBlank(input: String?): Boolean = input == null || canon(input).isEmpty()

    /** `canon()`, but folds the empty result to null so "no reference" is unmissable in the type. */
    fun canonOrNull(input: String?): String? =
        input?.let { canon(it) }?.takeIf { it.isNotEmpty() }

    // Exposed so the conformance test can assert these tables against the ones
    // declared in canon-fixtures.json rather than trusting that they were
    // transcribed correctly by hand.
    internal fun stripCodePoints(): Set<Int> = STRIP
    internal fun quoteCodePoints(): Map<Int, Char> = QUOTES
    internal fun whitespaceCodePoints(): Set<Int> = WHITESPACE
}

/** Convenience alias so call sites read like the spec. */
fun canon(input: String): String = Canon.canon(input)
