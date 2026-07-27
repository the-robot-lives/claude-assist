import Foundation

/// Canonical name normalization and the deterministic taxonomy ids derived
/// from it. `SYNC-PROTOCOL.md` §3.3, as amended by `canon-fixtures.json`.
///
/// This is the highest-stakes forty lines in the package. `canon()` is
/// implemented three times — here, in Elixir on the server, and in Kotlin on
/// Android — and a divergence does not throw. It silently mints a second
/// `client` row for the same customer on one platform and not the others, and
/// nobody notices until a report splits a client's billable hours in two.
///
/// The eight steps below are transcribed from `canon_algorithm` in the fixture
/// file, which is the normative artifact — the prose in `SYNC-PROTOCOL.md`
/// §3.3 still describes the pre-amendment seven-step form and omits quote
/// normalization entirely. Every `canon_cases` and `composite_cases` entry is
/// executed against this implementation by `CanonFixtureTests`.
///
/// Four traps are deliberately closed here:
///
/// **Locale-sensitive lowercasing.** `NSString.lowercased(with:)` under a
/// Turkish locale maps `I` to dotless `ı`, so a Turkish-locale device computes
/// a different id for "IBM" than every other device in the workspace. This
/// implementation uses `String.lowercased()`, which performs Unicode's default
/// (locale-independent) full lowercase mapping and matches Kotlin's
/// `lowercase(Locale.ROOT)` and Elixir's `String.downcase/1`.
///
/// **Final sigma.** Java and Python apply Unicode's `Final_Sigma` context rule
/// during lowercasing and emit `ς` for a word-final `Σ`; Swift 6.3.1/Darwin and
/// Elixir's `:default` mode do not, and emit `σ` directly (verified against
/// this toolchain - see `CanonFixtureTests.finalSigma()`). Step 7 rewrites `ς`
/// to `σ` so all four converge regardless of which one lowercasing produced.
/// It is still load-bearing on this platform: an input can already **contain**
/// a literal `ς` with no lowercasing involved (a Greek keyboard emits it
/// directly for a word-final sigma), and only step 7 makes that converge with
/// the uppercase spelling. Without it "ΟΔΥΣΣΕΥΣ" and "οδυσσευς" would mint
/// different ids on any runtime that does apply `Final_Sigma`.
///
/// **An unpinned whitespace set.** `CharacterSet.whitespacesAndNewlines`,
/// Kotlin's `Char.isWhitespace` and Elixir's default trim set disagree on
/// U+0085, U+00A0 and U+180E. The set is therefore hardcoded to the fixture
/// file's `whitespace_code_points` so all three implementations agree.
///
/// **Quote ordering.** Step 3 runs *after* NFKC, not before. U+0149 NFKC
/// -decomposes to U+02BC + U+006E, so a pre-NFKC mapping would leave a U+02BC
/// behind and diverge from the ASCII spelling.
///
/// Two behaviours that look like bugs are pinned by fixtures and MUST NOT be
/// "fixed": this is lowercase and not case folding, so `Straße` != `strasse`;
/// and diacritics are not folded, so `Muñoz` != `Munoz`.
public enum Canon {

    // MARK: - Code point tables (transcribed from canon-fixtures.json)

    /// `strip_code_points` — invisible formatting noise that survives
    /// copy-paste. U+200C ZWNJ and U+200D ZWJ are deliberately **absent**: they
    /// are semantically significant in Indic and Persian text and in emoji ZWJ
    /// sequences, and stripping them would merge distinct names.
    ///
    /// This is the actual table `isStripped(_:)` consults, not a parallel list
    /// - `CanonFixtureTests` diffs it against the fixture's declared
    /// `strip_code_points` directly, so a transcription slip here fails the
    /// build even on a code point no behavioural fixture case happens to touch.
    static let stripCodePoints: Set<UInt32> = {
        var set: Set<UInt32> = [
            0x00AD,             // soft hyphen
            0x200B,             // zero width space
            0x200E, 0x200F,     // LRM, RLM
            0xFEFF              // zero width no-break space / BOM
        ]
        set.formUnion(0x202A...0x202E)   // LRE, RLE, PDF, LRO, RLO
        set.formUnion(0x2066...0x2069)   // LRI, RLI, FSI, PDI
        return set
    }()

    @inline(__always)
    static func isStripped(_ scalar: Unicode.Scalar) -> Bool {
        stripCodePoints.contains(scalar.value)
    }

    /// `quote_code_points` — the marks a keyboard or autocorrect substitutes
    /// *in place of* the ASCII `'` and `"` keys. iOS emits U+2019 where a
    /// desktop keyboard emits U+0027; without this step "Bob's Diner" typed on
    /// an iPhone and on a Mac mint two different clients.
    ///
    /// A fixed closed set, not general punctuation folding: "Acme, Inc." and
    /// "Acme Inc" remain different clients.
    ///
    /// This is the actual table `quoteReplacement(_:)` consults - see the note
    /// on `stripCodePoints` above.
    static let quoteCodePoints: [UInt32: Unicode.Scalar] = [
        0x02BC: "'",   // modifier letter apostrophe
        0x2018: "'",   // left single quotation mark
        0x2019: "'",   // right single quotation mark
        0x201A: "'",   // single low-9 quotation mark
        0x201B: "'",   // single high-reversed-9 quotation mark
        0x201C: "\"",  // left double quotation mark
        0x201D: "\"",  // right double quotation mark
        0x201E: "\"",  // double low-9 quotation mark
        0x201F: "\""   // double high-reversed-9 quotation mark
    ]

    @inline(__always)
    static func quoteReplacement(_ scalar: Unicode.Scalar) -> Unicode.Scalar? {
        quoteCodePoints[scalar.value]
    }

    /// `whitespace_code_points`, enumerated rather than inferred. Note that
    /// NFKC does not map U+1680 OGHAM SPACE MARK, so this step is not
    /// redundant with step 2.
    ///
    /// This is the actual table `isWhitespace(_:)` consults - see the note on
    /// `stripCodePoints` above.
    static let whitespaceCodePoints: Set<UInt32> = {
        var set: Set<UInt32> = [
            0x0020,             // space
            0x0085,             // NEL
            0x00A0,             // no-break space
            0x1680,             // ogham space mark
            0x2028,             // line separator
            0x2029,             // paragraph separator
            0x202F,             // narrow no-break space
            0x205F,             // medium mathematical space
            0x3000              // ideographic space
        ]
        set.formUnion(0x0009...0x000D)   // tab, LF, VT, FF, CR
        set.formUnion(0x2000...0x200A)   // en quad .. hair space
        return set
    }()

    @inline(__always)
    static func isWhitespace(_ scalar: Unicode.Scalar) -> Bool {
        whitespaceCodePoints.contains(scalar.value)
    }

    // MARK: - canon()

    /// `canon(s)` — the eight-step normalization.
    ///
    /// An empty result is not an entity: callers MUST treat `""` as "no
    /// reference" rather than vivifying a row with an empty name. See
    /// ``isEmptyReference(_:)`` and ``clientID(workspaceID:name:)``, which
    /// returns `nil` rather than minting an id from an empty key.
    public static func canon(_ input: String) -> String {
        // 1. Strip the invisible set.
        var stripped = String.UnicodeScalarView()
        for scalar in input.unicodeScalars where !isStripped(scalar) {
            stripped.append(scalar)
        }

        // 2. NFKC.
        let normalized = String(stripped).precomposedStringWithCompatibilityMapping

        // 3-5. Quote mapping, whitespace mapping, run collapse and trim.
        //
        // Steps 3 and 4 operate on disjoint code point sets, so they are folded
        // into the same pass as the collapse. A separator is emitted only once
        // a non-space actually follows it, which trims both ends for free.
        var output = String.UnicodeScalarView()
        var pendingSeparator = false
        var started = false

        for scalar in normalized.unicodeScalars {
            if isWhitespace(scalar) {
                if started { pendingSeparator = true }
                continue
            }
            if pendingSeparator {
                output.append(" ")
                pendingSeparator = false
            }
            output.append(quoteReplacement(scalar) ?? scalar)
            started = true
        }

        // 6. Lowercase, locale-independent.
        let lowered = String(output).lowercased()

        // 7. Final sigma to ordinary sigma.
        let desigmaed: String
        if lowered.unicodeScalars.contains(where: { $0.value == 0x03C2 }) {
            var view = String.UnicodeScalarView()
            for scalar in lowered.unicodeScalars {
                view.append(scalar.value == 0x03C2 ? "\u{03C3}" : scalar)
            }
            desigmaed = String(view)
        } else {
            desigmaed = lowered
        }

        // 8. NFC, to recompose anything the case mapping decomposed.
        return desigmaed.precomposedStringWithCanonicalMapping
    }

    /// True when a name carries no reference after canonicalization.
    public static func isEmptyReference(_ input: String) -> Bool {
        canon(input).isEmpty
    }

    // MARK: - Deterministic taxonomy ids (§3.2)

    /// `uuidv5(workspace_id, "client:" + canon(name))`, or `nil` when the name
    /// canonicalizes to empty.
    ///
    /// `nil` means "no reference" and MUST NOT be coerced into an id. Four
    /// fixture cases pin it: a client named `""`, `"   "`, `"\u{00A0}\u{2003}\t"`
    /// or `"\u{200B}"` is not a client.
    public static func clientID(workspaceID: UUID, name: String) -> UUID? {
        let key = canon(name)
        guard !key.isEmpty else { return nil }
        return UUID.v5(namespace: workspaceID, name: "client:" + key)
    }

    /// `uuidv5(workspace_id, "project:" + canon(client_name) + "/" + canon(name))`
    ///
    /// An absent parent contributes an empty segment — `"project:/internal"` —
    /// which is its own scope, matching the contract's "a null `client_id` is
    /// its own scope" uniqueness rule. The project's *own* name still may not
    /// be empty.
    public static func projectID(workspaceID: UUID, clientName: String, name: String) -> UUID? {
        let key = canon(name)
        guard !key.isEmpty else { return nil }
        return UUID.v5(namespace: workspaceID, name: "project:" + canon(clientName) + "/" + key)
    }

    /// `uuidv5(workspace_id, "ticket:" + canon(client) + "/" + canon(project) + "/" + canon(name))`
    public static func ticketID(
        workspaceID: UUID,
        clientName: String,
        projectName: String,
        name: String
    ) -> UUID? {
        let key = canon(name)
        guard !key.isEmpty else { return nil }
        return UUID.v5(
            namespace: workspaceID,
            name: "ticket:" + canon(clientName) + "/" + canon(projectName) + "/" + key
        )
    }

    /// `uuidv5(workspace_id, "user_settings:" + user_id)`
    ///
    /// Not name-derived, so it is not canonicalized. The user id is rendered in
    /// the contract's lowercase canonical form. Never `nil` — there is always a
    /// user id.
    public static func userSettingsID(workspaceID: UUID, userID: UUID) -> UUID {
        UUID.v5(namespace: workspaceID, name: "user_settings:" + userID.canonicalString)
    }

    // MARK: - Keys (exposed for fixture conformance and diagnostics)

    public static func clientKey(_ name: String) -> String {
        "client:" + canon(name)
    }

    public static func projectKey(clientName: String, name: String) -> String {
        "project:" + canon(clientName) + "/" + canon(name)
    }

    public static func ticketKey(clientName: String, projectName: String, name: String) -> String {
        "ticket:" + canon(clientName) + "/" + canon(projectName) + "/" + canon(name)
    }
}
