#!/usr/bin/env python3
"""Generate canon-fixtures.json: the cross-platform conformance suite for canon()
and the deterministic UUIDv5 taxonomy-id derivation.

The canon() here is the REFERENCE implementation. It must match
docs/SYNC-PROTOCOL.md section 3.3 exactly.
"""
import json
import os
import unicodedata
import uuid

WORKSPACE_ID = "0192f7a1-2b44-7000-8a10-9d3e4f5a6b7c"
NS = uuid.UUID(WORKSPACE_ID)

# Step 1: enumerated invisible / format characters that are pure copy-paste noise.
# NOTE: U+200C ZWNJ and U+200D ZWJ are deliberately NOT stripped - they are
# semantically significant in Indic/Persian text and in emoji ZWJ sequences.
STRIP = {
    0x00AD,                                  # SOFT HYPHEN
    0x200B,                                  # ZERO WIDTH SPACE
    0x200E, 0x200F,                          # LRM, RLM
    0x202A, 0x202B, 0x202C, 0x202D, 0x202E,  # bidi embedding/override
    0x2066, 0x2067, 0x2068, 0x2069,          # bidi isolates
    0xFEFF,                                  # ZERO WIDTH NO-BREAK SPACE / BOM
}

# Step 3: quote normalization. Smart-quote substitution is what a keyboard or
# autocorrect emits IN PLACE OF the plain ASCII key, so these are the same
# character as far as a human naming a client is concerned. iOS emits U+2019
# where a desktop keyboard emits U+0027; without this step "Bob's Diner" typed
# on an iPhone and on a Mac mint two different clients.
#
# MUST run AFTER NFKC: U+0149 LATIN SMALL LETTER N PRECEDED BY APOSTROPHE
# NFKC-decomposes to U+02BC + n, so a pre-NFKC mapping would miss it. It is the
# only code point in all of Unicode that NFKC maps into this target set - see
# fixture case in the "punctuation" group.
QUOTES = {
    0x2018: "'", 0x2019: "'", 0x201A: "'", 0x201B: "'", 0x02BC: "'",
    0x201C: '"', 0x201D: '"', 0x201E: '"', 0x201F: '"',
}

# Step 4: Unicode White_Space=Yes, enumerated so three implementations agree.
WHITESPACE = (
    {0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x0020, 0x0085, 0x00A0,
     0x1680, 0x2028, 0x2029, 0x202F, 0x205F, 0x3000}
    | set(range(0x2000, 0x200B))
)


def canon(s: str) -> str:
    s = "".join(ch for ch in s if ord(ch) not in STRIP)            # 1
    s = unicodedata.normalize("NFKC", s)                            # 2
    s = "".join(QUOTES.get(ord(ch), ch) for ch in s)                # 3
    s = "".join(" " if ord(ch) in WHITESPACE else ch for ch in s)   # 4
    s = " ".join(p for p in s.split(" ") if p != "")                # 5
    s = s.lower()                                                   # 6
    s = s.replace("ς", "σ")                               # 7 final sigma
    s = unicodedata.normalize("NFC", s)                             # 8
    return s


def cps(s: str):
    return [f"U+{ord(c):04X}" for c in s]


def client_key(name):
    return "client:" + canon(name)


def project_key(client, name):
    return "project:" + canon(client) + "/" + canon(name)


def ticket_key(client, project, name):
    return "ticket:" + canon(client) + "/" + canon(project) + "/" + canon(name)


def uid(key):
    return str(uuid.uuid5(NS, key))


# (group, input, note)
CASES = [
    # --- whitespace -------------------------------------------------------
    ("whitespace", "Acme", "Baseline. Every other case is measured against this id."),
    ("whitespace", "  Acme  ", "Leading and trailing spaces trimmed."),
    ("whitespace", "Acme   Corp", "Interior run of spaces collapses to one."),
    ("whitespace", "\tAcme\nCorp\r\n", "Tab, LF, CR are White_Space; become U+0020, then collapse and trim."),
    ("whitespace", "Acme Corp", "NBSP. NFKC already maps it to U+0020, but step 3 must catch it regardless."),
    ("whitespace", "Acme Corp", "EM SPACE."),
    ("whitespace", "Acme　Corp", "IDEOGRAPHIC SPACE - common when pasting from CJK input methods."),
    ("whitespace", "Acme Corp", "OGHAM SPACE MARK. NFKC does NOT map this; only step 3 catches it. A strong test of step 3."),
    ("whitespace", "Acme Corp", "NARROW NO-BREAK SPACE."),
    ("whitespace", "", "Empty input canons to empty. Per section 6.1 step 5 this is 'no reference', NOT an entity named ''."),
    ("whitespace", "   ", "Whitespace-only canons to empty. Must not create an entity."),
    ("whitespace", "  \t", "Exotic whitespace only. Still empty."),

    # --- invisible / format characters ------------------------------------
    ("invisible", "Ac​me", "ZERO WIDTH SPACE stripped. Without step 1 this is a silent duplicate of 'Acme'."),
    ("invisible", "﻿Acme", "BOM / ZWNBSP stripped. Extremely common leading a pasted or file-read string."),
    ("invisible", "Acme­Corp", "SOFT HYPHEN stripped, leaving no space - yields 'acmecorp', NOT 'acme corp'."),
    ("invisible", "‫Acme‬", "Bidi embedding controls stripped."),
    ("invisible", "⁦Acme⁩", "Bidi isolate controls stripped."),
    ("invisible", "​", "Zero-width only. Canons to empty, so it is not an entity."),
    ("invisible", "\U0001f468‍\U0001f4bb", "ZWJ emoji sequence (man technologist). U+200D is NOT stripped - stripping it would split the glyph."),
    ("invisible", "\U0001f468‍\U0001f469‍\U0001f467", "Family ZWJ sequence preserved intact."),
    ("invisible", "می‌رود", "Persian with ZWNJ. U+200C is NOT stripped - it is semantically significant."),

    # --- case -------------------------------------------------------------
    ("case", "ACME", "Uppercase folds to the baseline id."),
    ("case", "AcMe", "Mixed case folds to the baseline id."),
    ("case", "ISTANBUL", "THE TURKISH TRAP. Must yield 'istanbul'. A Turkish-locale lowercase yields 'ıstanbul' and silently forks the workspace. Use Locale.ROOT / :default / .lowercased()."),
    ("case", "İstanbul", "U+0130 CAPITAL I WITH DOT ABOVE lowercases to 'i' + U+0307 COMBINING DOT ABOVE (two code points). Distinct from 'Istanbul'."),
    ("case", "Istanbul", "Plain ASCII I. Distinct from the U+0130 case above - compare the two ids."),
    ("case", "Iı", "ASCII I and dotless ı. The ı is already lowercase and stays."),
    ("case", "ΟΔΥΣΣΕΥΣ", "GREEK FINAL SIGMA TRAP. Verified empirically for this fixture: Java (Temurin 21) and Python 3 apply the Unicode Final_Sigma context rule when lowercasing and produce ς; Swift 6.3.1/Darwin .lowercased() and Elixir 1.20 String.downcase/1 (:default) do not, and produce σ directly. Kotlin/JVM .lowercase(Locale.ROOT) is expected to match Java - it shares the JVM's case-mapping tables - but was not independently run for this note. Step 7, not step 6, maps ς to σ so all four converge regardless of which one lowercasing produced. Step 7 is load-bearing even for runtimes that never emit ς from lowercasing: an input can already contain a literal ς with no lowercasing involved - see canon-029."),
    ("case", "οδυσσευς", "Same word already lowercased with a final sigma. Must produce the SAME id as the uppercase form above."),
    ("case", "Straße", "German sharp s. Lowercase leaves ß intact - this does NOT equal 'strasse'. Documented limitation of lowercase-vs-casefold."),
    ("case", "STRASSE", "Compare to 'Straße': different ids. If your ids match, you implemented casefold, not lowercase."),
    ("case", "ẞ", "U+1E9E CAPITAL SHARP S lowercases to ß in all three runtimes."),

    # --- normalization ----------------------------------------------------
    ("normalization", "Muñoz", "NFD input: 'n' + U+0303 COMBINING TILDE. NFKC composes it."),
    ("normalization", "Muñoz", "NFC input: precomposed U+00F1. MUST produce the same id as the NFD case above."),
    ("normalization", "Munoz", "Diacritics are NOT folded. This is a different client from 'Muñoz' - deliberately."),
    ("normalization", "ﬁle Review", "U+FB01 LATIN SMALL LIGATURE FI. NFKC decomposes it to 'fi'."),
    ("normalization", "ＡＣＭＥ", "Fullwidth Latin. NFKC maps to ASCII, then lowercase - equals the baseline 'Acme' id."),
    ("normalization", "Acme²", "SUPERSCRIPT TWO. NFKC maps to '2'."),
    ("normalization", "① Priority", "CIRCLED DIGIT ONE. NFKC maps to '1'."),
    ("normalization", "Ⅳ Rollout", "U+2163 ROMAN NUMERAL FOUR. NFKC maps to 'IV', then lowercase to 'iv'."),
    ("normalization", "ｱｸﾒ", "Halfwidth katakana. NFKC maps to fullwidth アクメ."),

    # --- punctuation and separators ---------------------------------------
    ("punctuation", "Acme, Inc.", "Punctuation is NOT stripped."),
    ("punctuation", "Acme Inc", "Distinct from 'Acme, Inc.'. These are two clients. Merging them is a user decision (US-085), not a canon() decision."),
    ("punctuation", "Acme-Corp", "Hyphen is not a separator; no space is introduced."),
    ("punctuation", "Acme Corp", "Distinct from 'Acme-Corp'."),
    ("punctuation", "Bob's Diner", "ASCII apostrophe U+0027. Baseline for the quote-normalization group below."),
    ("punctuation", "Bob’s Diner", "U+2019 RIGHT SINGLE QUOTATION MARK - what iOS autocorrect emits. Step 3 maps it to U+0027, so this MUST produce the same id as the ASCII form. This is the single most likely real-world cross-device duplicate generator: same name typed on an iPhone and on a Mac."),
    ("punctuation", "Bob‘s Diner", "U+2018 LEFT SINGLE QUOTATION MARK. Same id."),
    ("punctuation", "Bob‛s Diner", "U+201B SINGLE HIGH-REVERSED-9. Same id."),
    ("punctuation", "Bob‚s Diner", "U+201A SINGLE LOW-9 - the German opening single quote. Same id."),
    ("punctuation", "Bobʼs Diner", "U+02BC MODIFIER LETTER APOSTROPHE. Same id. See known_limitations: U+02BC is a letter in some orthographies, and this mapping deliberately conflates it with punctuation."),
    ("punctuation", "ŉuit Shift", "U+0149 LATIN SMALL LETTER N PRECEDED BY APOSTROPHE. THE ORDERING PROOF: NFKC decomposes this to U+02BC + n, so step 3 must run AFTER step 2 to catch it. It is the only code point in Unicode that NFKC maps into the quote target set. Expect \"'nuit shift\"."),
    ("punctuation", "“Phoenix” Rebrand", "U+201C/U+201D smart double quotes map to U+0022."),
    ("punctuation", "\"Phoenix\" Rebrand", "ASCII double quotes. MUST produce the same id as the smart-quote form above."),
    ("punctuation", "„Phoenix“ Rebrand", "German smart double quotes U+201E/U+201C. Same id again."),
    ("punctuation", "Acme / Redesign", "Slashes survive canon. They are only structural inside the composite key strings."),

    # --- digits -----------------------------------------------------------
    ("digits", "Project 42", "ASCII digits pass through."),
    ("digits", "٤٢", "Arabic-Indic digits. NFKC does NOT map them to ASCII; they stay."),
    ("digits", "４２", "Fullwidth digits. NFKC DOES map these to ASCII '42'."),

    # --- scripts ----------------------------------------------------------
    ("scripts", "\U0001f680 Launch", "Emoji preserved; only the space and case are touched."),
    ("scripts", "株式会社アクメ", "CJK passes through unchanged - no case, no decomposition."),
    ("scripts", "شركة أكمي", "Arabic RTL. Logical order is preserved; canon never reorders."),
    ("scripts", "חברת  אקמי", "Hebrew RTL with a double space that collapses."),

    # --- length -----------------------------------------------------------
    ("length", "A" * 512, "512 chars. canon() never truncates - length limits are a schema concern (maxLength 200), enforced separately and AFTER canon."),
    ("length", "  " + "Very Long Project Name " * 20 + "  ", "Long input with repeated interior whitespace runs."),

    # --- coverage gaps ------------------------------------------------------
    # Added after an audit found that a passing 65/65 behavioural suite does
    # NOT prove every declared code point is exercised: three implementations
    # could each drop a different entry from strip/quote/whitespace, still
    # pass every case above, and still silently diverge on the one input that
    # happens to carry the dropped point. These three cases close every code
    # point in strip_code_points, quote_code_points, and whitespace_code_points
    # that no case above touches. Appended at the end, not interleaved, so
    # every existing case id (canon-001..canon-065) is unchanged.
    ("punctuation", "‟Phoenix‟ Rebrand", "U+201F DOUBLE HIGH-REVERSED-9 QUOTATION MARK - the one quote_code_points entry no other case touches. Same id as the ASCII double-quote form."),
    ("invisible", "‎‏‪‭‮⁧⁨Acme", "The strip_code_points entries no other case touches: LRM, RLM, LRE, LRO, RLO, RLI, FSI. All stripped, leaving 'acme'."),
    ("whitespace", "Acme             Corp", "The whitespace_code_points entries no other case touches: VT, FF, NEL, EN QUAD, EM QUAD, EN SPACE, THREE/FOUR/SIX-PER-EM SPACE, FIGURE SPACE, PUNCTUATION SPACE, THIN SPACE, HAIR SPACE, LINE SEPARATOR, PARAGRAPH SEPARATOR, MEDIUM MATHEMATICAL SPACE. All collapse to one U+0020."),
]

COMPOSITE = [
    ("project", ("Acme", "Redesign"), "Baseline composite project key."),
    ("project", ("ACME", "  redesign  "), "CONVERGENCE: different casing and padding must yield the SAME project id as the baseline above."),
    ("project", ("Acme", "Rede sign"), "Distinct from 'Redesign' - interior space is significant."),
    ("project", ("", "Internal"), "Client-less project. canon('') is empty, so the key is 'project:/internal'. Null client_id is its own uniqueness scope."),
    ("project", ("Globex", "Redesign"), "Same project name under a different client is a DIFFERENT project."),
    ("ticket", ("Acme", "Redesign", "TIM-14"), "Baseline composite ticket key."),
    ("ticket", ("Acme", "Redesign", "tim-14"), "CONVERGENCE: must equal the baseline ticket id."),
    ("ticket", ("Acme", "Redesign", "TIM 14"), "Space instead of hyphen is a different ticket."),
]


def build():
    cases = []
    for i, (group, inp, note) in enumerate(CASES, start=1):
        out = canon(inp)
        key = client_key(inp)
        cases.append({
            "id": f"canon-{i:03d}",
            "group": group,
            "input": inp,
            "expected_output": out,
            "expected_output_codepoints": cps(out),
            "expected_client_key": key,
            "expected_client_id": uid(key) if out else None,
            "note": note,
        })

    comps = []
    for i, (kind, parts, note) in enumerate(COMPOSITE, start=1):
        if kind == "project":
            client, name = parts
            key = project_key(client, name)
            entry = {
                "id": f"composite-{i:03d}",
                "kind": "project",
                "input": {"client_name": client, "name": name},
            }
        else:
            client, project, name = parts
            key = ticket_key(client, project, name)
            entry = {
                "id": f"composite-{i:03d}",
                "kind": "ticket",
                "input": {"client_name": client, "project_name": project, "name": name},
            }
        entry["expected_key"] = key
        entry["expected_id"] = uuid.uuid5(NS, key).__str__()
        entry["note"] = note
        comps.append(entry)

    return cases, comps


cases, comps = build()

doc = {
    "$schema_note": "Plain JSON. No external schema. Consumed directly by test suites.",
    "title": "Timely canon() and taxonomy-id conformance fixtures",
    "version": "1.0.0",
    "generated_for_contract_version": "1.0.0-draft.1",
    "about": [
        "canon() and the deterministic UUIDv5 taxonomy-id derivation are implemented three times:",
        "once in Elixir (server), once in Swift (macOS + iOS), once in Kotlin (Android).",
        "A divergence between any two of them does not raise an error. It silently creates",
        "duplicate clients, projects, and tickets in a live workspace, and the duplicates are",
        "only discoverable by a human noticing them in a report weeks later.",
        "",
        "Every implementation MUST pass every case in this file before it is allowed to sync.",
        "See docs/SYNC-PROTOCOL.md sections 3.2, 3.3, and 14."
    ],
    "workspace_id": WORKSPACE_ID,
    "workspace_id_note": [
        "Fixed test constant. Used as the UUIDv5 namespace for every expected id below.",
        "uuid5(namespace, name) is RFC 4122 section 4.3: SHA-1 over the namespace's 16 raw",
        "bytes followed by the UTF-8 bytes of name, with version and variant bits set.",
        "This is NOT a real workspace. Never use it outside tests."
    ],
    "canon_algorithm": [
        "1. Remove every code point in strip_code_points (below). U+200C ZWNJ and U+200D ZWJ are deliberately retained.",
        "2. Normalize NFKC.",
        "3. Map every code point in quote_code_points (below) to its ASCII equivalent. MUST run after step 2 - see step_order_note.",
        "4. Replace every code point in whitespace_code_points (below) with U+0020.",
        "5. Collapse runs of U+0020 to one; trim leading and trailing U+0020.",
        "6. Lowercase, locale-independent. Elixir String.downcase/1, Swift .lowercased(), Kotlin .lowercase(Locale.ROOT). NEVER a locale-sensitive lowercase.",
        "7. Replace U+03C2 GREEK SMALL LETTER FINAL SIGMA with U+03C3 GREEK SMALL LETTER SIGMA.",
        "8. Normalize NFC."
    ],
    "step_order_note": [
        "Step 3 MUST run after step 2, not before. U+0149 LATIN SMALL LETTER N PRECEDED BY",
        "APOSTROPHE NFKC-decomposes to U+02BC + U+006E, so a pre-NFKC mapping would leave a",
        "U+02BC behind and diverge from the ASCII spelling. U+0149 is the only code point in",
        "Unicode that NFKC maps into the quote target set; it is pinned by a fixture case.",
        "Steps 3 and 4 operate on disjoint code point sets, so their relative order is free."
    ],
    "strip_code_points": [f"U+{c:04X}" for c in sorted(STRIP)],
    "quote_code_points": {
        f"U+{c:04X}": QUOTES[c] for c in sorted(QUOTES)
    },
    "quote_rationale": [
        "Smart-quote substitution is what a keyboard or autocorrect emits IN PLACE OF the plain",
        "ASCII key, so these are the same character as far as a human naming a client is concerned.",
        "iOS emits U+2019 where a desktop keyboard emits U+0027. Without this step, 'Bob's Diner'",
        "typed on an iPhone and on a Mac mint two different clients - the most likely real-world",
        "cross-device duplicate generator in this product.",
        "The set is fixed and closed. It covers the marks that US and German smart-quote features",
        "substitute for the ASCII ' and \" keys, and it is not a general punctuation-folding table."
    ],
    "whitespace_code_points": [f"U+{c:04X}" for c in sorted(WHITESPACE)],
    "key_formats": {
        "client": "\"client:\" + canon(name)",
        "project": "\"project:\" + canon(client_name) + \"/\" + canon(name)",
        "ticket": "\"ticket:\" + canon(client_name) + \"/\" + canon(project_name) + \"/\" + canon(name)",
        "user_settings": "\"user_settings:\" + user_id",
        "note": "An absent parent contributes an empty segment, e.g. \"project:/internal\". The id is minted from the key; it is never re-derived after a rename."
    },
    "how_to_run": [
        "For each entry in canon_cases: assert canon(input) == expected_output.",
        "Then assert uuid5(workspace_id, expected_client_key) == expected_client_id.",
        "A null expected_client_id means canon() produced an empty string: the implementation",
        "MUST NOT mint an id and MUST NOT create an entity. Treat it as 'no reference'.",
        "For each entry in composite_cases: assert the composed key and id match.",
        "Compare expected_output_codepoints, not just the string - a terminal or editor will",
        "happily hide a combining mark or a zero-width character and turn a real failure into a pass."
    ],
    "how_to_add_cases": [
        "Add to CASES or COMPOSITE in the generator, regenerate, and commit the generator and",
        "the JSON together. Never hand-edit expected_output or expected_*_id - they are computed.",
        "Add a case whenever a canon()-related bug is found in ANY of the three implementations,",
        "before fixing it. A bug that reached production is by definition not covered here yet."
    ],
    "known_limitations": [
        "Lowercase, not case folding: 'Straße' != 'strasse' and 'Aẞ' != 'ass'. None of Elixir, Swift, or Kotlin exposes Unicode case folding natively, so lowercase is the only rule all three can implement identically without shipping a custom table. Reviewed and deliberately retained - a hand-maintained sharp-s mapping in three languages is a worse divergence risk than the duplicate it prevents. The user-facing merge (US-085) is the right home for it. Do NOT 'fix' this; two fixture cases pin it.",
        "Diacritics are not folded: 'Muñoz' != 'Munoz'. Deliberate - they are usually different names.",
        "U+02BC MODIFIER LETTER APOSTROPHE is mapped to U+0027 along with the smart quotes. In a few orthographies U+02BC is a letter (a glottal stop) rather than punctuation, so this mapping can conflate two genuinely distinct names. Accepted: the cross-device duplicate it prevents is far more common in this product's actual user base than the orthography it flattens.",
        "Quote normalization is a fixed closed set, not general punctuation folding. 'Acme, Inc.' and 'Acme Inc' remain different clients, as do 'Acme-Corp' and 'Acme Corp'.",
        "Arabic-Indic digits are not mapped to ASCII. NFKC does not touch them."
    ],
    "canon_cases": cases,
    "composite_cases": comps,
}

out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "canon-fixtures.json")
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(doc, f, indent=2, ensure_ascii=True)
    f.write("\n")

print("wrote", out_path)
print("canon_cases:", len(cases))
print("composite_cases:", len(comps))
print()
# Convergence assertions - these MUST hold or the fixture is lying.
base = uid(client_key("Acme"))
for v in ["  Acme  ", "ACME", "AcMe", "ＡＣＭＥ", "Ac​me", "﻿Acme"]:
    assert uid(client_key(v)) == base, ("convergence broken", repr(v))
assert canon("Muñoz") == canon("Muñoz"), "NFD/NFC convergence broken"
assert canon("ΟΔΥΣΣΕΥΣ") == canon("οδυσσευς"), "final sigma convergence broken"
assert canon("ISTANBUL") == "istanbul", "turkish trap"
assert canon("Straße") != canon("STRASSE"), "sharp s must NOT equal ss"
assert canon("Munoz") != canon("Muñoz"), "diacritics must not fold"
assert canon("") == "" and canon("   ") == "" and canon("​") == "", "empty rule"
assert project_key("ACME", "  redesign  ") == project_key("Acme", "Redesign"), "composite convergence"
assert project_key("Acme", "Redesign") != project_key("Globex", "Redesign"), "client scoping"
assert "‍" in canon("\U0001f468‍\U0001f4bb"), "ZWJ must survive"
assert "‌" in canon("می‌رود"), "ZWNJ must survive"
assert canon("Acme Corp") == "acme corp", "ogham space"
assert canon("Acme­Corp") == "acmecorp", "soft hyphen leaves no space"
assert canon("İstanbul") == "i̇stanbul", "dotted capital I -> i + U+0307"

# quote normalization: every smart form must converge on the ASCII form
ascii_single = uid(client_key("Bob's Diner"))
for v in ["Bob\u2019s Diner", "Bob\u2018s Diner", "Bob\u201as Diner",
          "Bob\u201bs Diner", "Bob\u02bcs Diner"]:
    assert uid(client_key(v)) == ascii_single, ("quote convergence broken", repr(v))
ascii_double = uid(client_key('"Phoenix" Rebrand'))
for v in ["\u201cPhoenix\u201d Rebrand", "\u201ePhoenix\u201c Rebrand"]:
    assert uid(client_key(v)) == ascii_double, ("double-quote convergence broken", repr(v))
# ORDERING PROOF: U+0149 NFKC-decomposes to U+02BC + n, so step 3 must follow step 2.
assert canon("\u0149uit Shift") == "'nuit shift", "quote step must run AFTER NFKC"
# quote normalization must NOT bleed into general punctuation folding
assert canon("Acme, Inc.") != canon("Acme Inc"), "punctuation must not be folded"
assert canon("Acme-Corp") != canon("Acme Corp"), "hyphen must not be folded"
print("all convergence assertions passed")
print("baseline 'Acme' client_id:", base)
print("canon('İstanbul') codepoints:", cps(canon("İstanbul")))
