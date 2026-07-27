import Foundation
import Testing
@testable import TimelyKit

/// The §14 conformance gate. Every case in `canon-fixtures.json` runs against
/// this platform's `canon()`; nothing else in the sync stack is trustworthy
/// until all of them pass.
///
/// A failure here is never "the test is wrong". The fixture file is the
/// normative artifact and is shared byte-for-byte with the Elixir and Kotlin
/// implementations — a red case means this platform would mint a taxonomy id
/// the other two would not.
@Suite("canon() contract conformance")
struct CanonFixtureTests {

    static let fixtures: CanonFixtureFile = {
        do { return try ContractFixtures.loadCanonFixtures() }
        catch { fatalError("Could not load canon-fixtures.json: \(error)") }
    }()

    static var canonCases: [CanonCase] { fixtures.canonCases }
    static var compositeCases: [CompositeCase] { fixtures.compositeCases }

    // MARK: - The gate

    @Test("canon() output matches the fixture", arguments: CanonFixtureTests.canonCases)
    func canonOutput(_ testCase: CanonCase) {
        let actual = Canon.canon(testCase.input)

        #expect(
            actual == testCase.expectedOutput,
            """
            \(testCase.id) [\(testCase.group)] canon() output diverged.
              input:    \(testCase.input.fixtureCodepoints)
              expected: \(testCase.expectedOutput.fixtureCodepoints)
              actual:   \(actual.fixtureCodepoints)
              note:     \(testCase.note ?? "-")
            """
        )
    }

    /// The fixture spells the expected output twice — once as a string, once as
    /// a code point list. Checking both catches a case where the JSON string
    /// itself is normalized in transit by an editor.
    @Test("canon() output codepoints match", arguments: CanonFixtureTests.canonCases)
    func canonCodepoints(_ testCase: CanonCase) {
        guard !testCase.expectedOutputCodepoints.isEmpty else { return }
        let actual = Canon.canon(testCase.input).fixtureCodepoints
        #expect(
            actual == testCase.expectedOutputCodepoints,
            "\(testCase.id) codepoints: expected \(testCase.expectedOutputCodepoints), got \(actual)"
        )
    }

    @Test("client key matches the fixture", arguments: CanonFixtureTests.canonCases)
    func clientKey(_ testCase: CanonCase) {
        guard let expected = testCase.expectedClientKey else { return }
        #expect(
            Canon.clientKey(testCase.input) == expected,
            "\(testCase.id) client key: expected \(expected), got \(Canon.clientKey(testCase.input))"
        )
    }

    /// The one that actually costs money when it is wrong.
    @Test("client id matches the fixture", arguments: CanonFixtureTests.canonCases)
    func clientID(_ testCase: CanonCase) {
        let actual = Canon.clientID(
            workspaceID: CanonFixtureTests.fixtures.workspaceID,
            name: testCase.input
        )

        if let expected = testCase.expectedClientID {
            #expect(
                actual == expected,
                """
                \(testCase.id) [\(testCase.group)] client id diverged — this platform \
                would mint a duplicate taxonomy row.
                  input:    \(testCase.input.fixtureCodepoints)
                  canon:    \(Canon.canon(testCase.input))
                  expected: \(expected.canonicalString)
                  actual:   \(actual?.canonicalString ?? "nil")
                """
            )
        } else {
            // A null id in the fixture is "no reference". Minting anything here
            // vivifies a client with an empty name.
            #expect(
                actual == nil,
                """
                \(testCase.id) minted an entity for a name that is not a reference.
                  input:  \(testCase.input.fixtureCodepoints)
                  minted: \(actual?.canonicalString ?? "nil")
                """
            )
        }
    }

    @Test("composite keys and ids match", arguments: CanonFixtureTests.compositeCases)
    func composite(_ testCase: CompositeCase) {
        let workspaceID = CanonFixtureTests.fixtures.workspaceID
        let input = testCase.input

        let actualKey: String
        let actualID: UUID?

        switch testCase.kind {
        case "project":
            actualKey = Canon.projectKey(
                clientName: input.clientName ?? "",
                name: input.name ?? ""
            )
            actualID = Canon.projectID(
                workspaceID: workspaceID,
                clientName: input.clientName ?? "",
                name: input.name ?? ""
            )
        case "ticket":
            actualKey = Canon.ticketKey(
                clientName: input.clientName ?? "",
                projectName: input.projectName ?? "",
                name: input.name ?? ""
            )
            actualID = Canon.ticketID(
                workspaceID: workspaceID,
                clientName: input.clientName ?? "",
                projectName: input.projectName ?? "",
                name: input.name ?? ""
            )
        case "client":
            actualKey = Canon.clientKey(input.name ?? "")
            actualID = Canon.clientID(workspaceID: workspaceID, name: input.name ?? "")
        case "user_settings":
            let userID = UUID(uuidString: input.userID ?? "") ?? UUID()
            actualKey = "user_settings:" + userID.canonicalString
            actualID = Canon.userSettingsID(workspaceID: workspaceID, userID: userID)
        default:
            Issue.record("\(testCase.id): unhandled composite kind '\(testCase.kind)'")
            return
        }

        #expect(
            actualKey == testCase.expectedKey,
            "\(testCase.id) key: expected \(testCase.expectedKey), got \(actualKey)"
        )
        #expect(
            actualID == testCase.expectedID,
            """
            \(testCase.id) id: expected \(testCase.expectedID?.canonicalString ?? "nil"), \
            got \(actualID?.canonicalString ?? "nil")  [\(testCase.note ?? "-")]
            """
        )
    }

    // MARK: - Table conformance
    //
    // The tests above only exercise the code points the behavioural cases
    // happen to touch. A transcription slip on a code point no case covers
    // would pass every test above and still silently mint a duplicate on this
    // platform. These three tests diff Canon's actual tables - the same ones
    // `isStripped`/`quoteReplacement`/`isWhitespace` consult, not a second
    // hand-copied list - against the fixture's declared blocks directly.

    @Test("strip code point table matches the contract")
    func stripTableMatchesContract() {
        #expect(
            Canon.stripCodePoints == CanonFixtureTests.fixtures.stripCodePoints,
            "Canon.stripCodePoints disagrees with strip_code_points in the fixture file"
        )
    }

    @Test("whitespace code point table matches the contract")
    func whitespaceTableMatchesContract() {
        #expect(
            Canon.whitespaceCodePoints == CanonFixtureTests.fixtures.whitespaceCodePoints,
            "Canon.whitespaceCodePoints disagrees with whitespace_code_points in the fixture file"
        )
    }

    @Test("quote code point table matches the contract")
    func quoteTableMatchesContract() {
        let actual = Dictionary(
            uniqueKeysWithValues: Canon.quoteCodePoints.map { ($0.key, Character($0.value)) }
        )
        #expect(
            actual == CanonFixtureTests.fixtures.quoteCodePoints,
            "Canon.quoteCodePoints disagrees with quote_code_points in the fixture file"
        )
    }

    @Test("ZWNJ and ZWJ are never in the strip table")
    func joinersNeverStripped() {
        #expect(!Canon.stripCodePoints.contains(0x200C))
        #expect(!Canon.stripCodePoints.contains(0x200D))
    }

    // MARK: - Coverage guards

    /// A FLOOR, not an equality. Guards against a fixture file that silently
    /// shrinks, truncates, or fails to parse - and against this suite quietly
    /// testing nothing - without coupling this file to the exact corpus size.
    /// Growing the fixture (adding cases) needs no change here; only
    /// shrinkage below the floor is a failure.
    @Test("the fixture file has not shrunk below its known coverage floor")
    func fixtureCoverage() {
        #expect(CanonFixtureTests.canonCases.count >= 65)
        #expect(CanonFixtureTests.compositeCases.count >= 8)
        #expect(
            CanonFixtureTests.fixtures.workspaceID
                == UUID(uuidString: "0192f7a1-2b44-7000-8a10-9d3e4f5a6b7c")
        )
    }

    /// Exactly four cases pin "not a reference".
    @Test("empty-reference cases mint nothing")
    func emptyReferenceCount() {
        let nullCases = CanonFixtureTests.canonCases.filter { $0.expectedClientID == nil }
        #expect(nullCases.count == 4, "expected 4 empty-reference cases, found \(nullCases.count)")
        for testCase in nullCases {
            #expect(Canon.isEmptyReference(testCase.input), "\(testCase.id) should be empty")
        }
    }

    // MARK: - Traps that are cheap to regress and expensive to notice

    /// Step 7, the final-sigma normalization.
    ///
    /// The spec and the fixture note both assert that Swift's `.lowercased()`
    /// applies Unicode's `Final_Sigma` context rule and emits `ς`. **On Swift
    /// 6.3 / Darwin it does not** — `"ΟΔΥΣΣΕΥΣ".lowercased()` yields
    /// `οδυσσευσ`, with U+03C3 throughout. The assertion below pins the real
    /// behaviour so a future toolchain that starts applying the rule fails
    /// loudly here rather than silently forking the workspace.
    ///
    /// Step 7 is still load-bearing on this platform, just for the other
    /// direction: fixture canon-029 feeds in text that **already** contains a
    /// literal `ς` (as a Greek keyboard emits for a word-final sigma), and only
    /// step 7 makes it converge with the uppercase spelling in canon-028.
    @Test("final sigma is normalized to ordinary sigma")
    func finalSigma() {
        // canon-028 / canon-029 must agree, in both spellings.
        #expect(Canon.canon("ΟΔΥΣΣΕΥΣ") == Canon.canon("οδυσσευς"))
        #expect(!Canon.canon("ΟΔΥΣΣΕΥΣ").unicodeScalars.contains { $0.value == 0x03C2 })
        #expect(!Canon.canon("οδυσσευς").unicodeScalars.contains { $0.value == 0x03C2 })

        // Where the step actually does work on Swift: pre-lowercased input.
        #expect("οδυσσευς".unicodeScalars.contains { $0.value == 0x03C2 })
        #expect("οδυσσευς".lowercased().unicodeScalars.contains { $0.value == 0x03C2 })

        // Documented divergence from the spec's prose: Swift does NOT apply
        // Final_Sigma when lowercasing. If this flips, revisit step 7's comment.
        #expect(
            !"ΟΔΥΣΣΕΥΣ".lowercased().unicodeScalars.contains { $0.value == 0x03C2 },
            "Swift began applying Final_Sigma during lowercasing — the spec's premise now holds and the §3.3 note should be re-read."
        )
    }

    /// ZWJ and ZWNJ are semantically significant. Stripping them would merge a
    /// Persian verb with a different word and collapse emoji families.
    @Test("ZWJ and ZWNJ survive canonicalization")
    func joinersSurvive() {
        #expect(Canon.canon("a\u{200D}b").unicodeScalars.contains { $0.value == 0x200D })
        #expect(Canon.canon("a\u{200C}b").unicodeScalars.contains { $0.value == 0x200C })
        #expect(Canon.canon("a\u{200B}b") == "ab")   // ZWSP, by contrast, is stripped
    }

    /// This is lowercase, not case folding. Pinned deliberately; see the
    /// fixture file's `known_limitations`. Do not "fix" it.
    @Test("sharp s is not folded to ss")
    func sharpSIsNotFolded() {
        #expect(Canon.canon("Straße") != Canon.canon("strasse"))
        #expect(Canon.canon("Straße") == "straße")
    }

    /// Diacritics are not folded — usually different names.
    @Test("diacritics are not folded")
    func diacriticsSurvive() {
        #expect(Canon.canon("Muñoz") != Canon.canon("Munoz"))
    }

    /// U+0149 NFKC-decomposes to U+02BC + U+006E. Mapping quotes before NFKC
    /// would leave the U+02BC behind. This pins step 3 after step 2.
    @Test("quote mapping runs after NFKC")
    func quoteMappingOrder() {
        let canonicalized = Canon.canon("\u{0149}")
        #expect(!canonicalized.unicodeScalars.contains { $0.value == 0x02BC })
        #expect(canonicalized == "'n")
    }

    /// The iOS autocorrect case: the same client typed on a phone and a laptop.
    @Test("smart apostrophes collapse to ASCII")
    func smartApostrophes() {
        let workspaceID = CanonFixtureTests.fixtures.workspaceID
        let typed = Canon.clientID(workspaceID: workspaceID, name: "Bob's Diner")
        for variant in ["Bob\u{2019}s Diner", "Bob\u{2018}s Diner",
                        "Bob\u{201B}s Diner", "Bob\u{02BC}s Diner"] {
            #expect(
                Canon.clientID(workspaceID: workspaceID, name: variant) == typed,
                "\(variant.fixtureCodepoints) should mint the same client as \"Bob's Diner\""
            )
        }
    }

    /// Locale independence. A Turkish-locale device must not fork the workspace.
    @Test("lowercasing is locale independent")
    func localeIndependentLowercasing() {
        #expect(Canon.canon("IBM") == "ibm")
        #expect(!Canon.canon("IBM").unicodeScalars.contains { $0.value == 0x0131 })
    }
}
