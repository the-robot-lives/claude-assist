# iffywow romanization profile core-v1 — normative

This document defines **romanization profile core-v1**: the exact mapping
between romanized New Ithkuil (Ithkuil IV) text and the canonical coordinate
tuple of CODEC.md §2, as required by SDK-INTERFACE.md (`from_latin` /
`to_latin`). It is implementation-independent: a Rust/Go/Node author who has
never seen the Elixir code MUST be able to reproduce identical behavior from
this document alone. `conformance/latin_to_coordinate.jsonl` is the arbiter.

**Scope.** core-v1 is deliberately a *partial* profile of New Ithkuil
morphology. It accepts exactly one word shape — an unconcatenated formative
`Vv Cr Vr Ca Vc` (slots II, III, IV, VI, IX) — with closed tables for each
slot. Everything else (Slot I Cc, affixes, VnCn, stress, glottal stop,
adjuncts, multiple words, ...) is **rejected** with error code `unsupported`;
the profile never guesses. Grapheme-level transliteration (as previously
shipped by the Python module) is **not** part of any profile and is
superseded by this document.

**Versioning.** The morpheme→coordinate mapping in §6 is *provisional* — it
predates the `spec/*.yaml` registries — but it is **normative for core-v1**:
every core-v1 implementation MUST produce exactly these coordinates. A future
registry-backed mapping will be a new profile version; core-v1 rows are
frozen.

---

## 1. Text model and preprocessing

Romanized input and output are Unicode strings (UTF-8 at byte boundaries).

`from_latin` MUST preprocess its input in this exact order:

1. **Trim** — remove leading and trailing Unicode whitespace.
2. **Normalize** — Unicode Normalization Form C (NFC). Decomposed input
   (e.g. `s` + U+030C COMBINING CARON) is thereby accepted wherever the
   composed character is.
3. **Lowercase** — the Unicode default (full, language-independent)
   lowercase mapping.

The result is the *word*. All subsequent rules operate on the word. Every
string emitted by `to_latin` is already trimmed, NFC, and lowercase — the
canonical spelling (§7).

After preprocessing, the word MUST consist solely of codepoints from the
inventories in §2; any other content (including an empty word) is rejected
with `unsupported`. Because all inventory entries are single, precomposed
codepoints, iterating by codepoint and by extended grapheme cluster give the
same result on every accepted word; on rejected words only the error
*detail* may differ (details are non-normative, see §8).

## 2. Character inventories (exact codepoints, NFC)

### 2.1 Vowels (class V) — 9 codepoints

| Char | Codepoint | | Char | Codepoint |
|---|---|---|---|---|
| `a` | U+0061 | | `ä` | U+00E4 |
| `e` | U+0065 | | `ë` | U+00EB |
| `i` | U+0069 | | `ö` | U+00F6 |
| `o` | U+006F | | `ü` | U+00FC |
| `u` | U+0075 | | | |

Note: `ë` (U+00EB) is a valid vowel *character* but appears in no Vv/Vr row;
it is accepted only as part of the Vc digraph `ëi` (§4.4).

### 2.2 Stress-marked vowels — always rejected

The following codepoints mark Slot X stress, which core-v1 does not support.
They classify as "stress marking" and MUST be rejected with `unsupported`:

`á` U+00E1, `é` U+00E9, `í` U+00ED, `ó` U+00F3, `ú` U+00FA,
`â` U+00E2, `ê` U+00EA, `î` U+00EE, `ô` U+00F4, `û` U+00FB.

(Any other letter outside §2.1–§2.3 — e.g. `q`, `à`, digits — is likewise
rejected with `unsupported` as an unknown character.)

### 2.3 Consonants (class C)

**Root inventory — 27 consonants. The order below is normative** (it defines
the base-27 digit values of §5; digit = position, 1-based):

| # | Char | Codepoint | # | Char | Codepoint | # | Char | Codepoint |
|---|---|---|---|---|---|---|---|---|
| 1 | `p` | U+0070 | 10 | `ḑ` | U+1E11 | 19 | `ç` | U+00E7 |
| 2 | `b` | U+0062 | 11 | `s` | U+0073 | 20 | `x` | U+0078 |
| 3 | `t` | U+0074 | 12 | `z` | U+007A | 21 | `ļ` | U+013C |
| 4 | `d` | U+0064 | 13 | `c` | U+0063 | 22 | `l` | U+006C |
| 5 | `k` | U+006B | 14 | `ẓ` | U+1E93 | 23 | `r` | U+0072 |
| 6 | `g` | U+0067 | 15 | `š` | U+0161 | 24 | `ř` | U+0159 |
| 7 | `f` | U+0066 | 16 | `ž` | U+017E | 25 | `m` | U+006D |
| 8 | `v` | U+0076 | 17 | `č` | U+010D | 26 | `n` | U+006E |
| 9 | `ţ` | U+0163 | 18 | `j` | U+006A | 27 | `ň` | U+0148 |

**Additional segmenter consonants** — these classify as consonants for run
segmentation (§3) but are valid only where a table row admits them:

| Char | Codepoint | Valid as |
|---|---|---|
| `w` | U+0077 | Ca only |
| `y` | U+0079 | Ca only |
| `h` | U+0068 | nowhere (segments, then rejected by shape or table lookup) |
| `'` | U+0027 | nowhere (segments, then rejected by shape or table lookup) |

## 3. Segmentation and word shape

Split the word into maximal runs of same-class characters (V = §2.1,
C = §2.3; anything else rejects per §2.2). The only accepted shape is
**exactly five runs, alternating, vowel first**:

```text
V₁ C₁ V₂ C₂ V₃   =   Vv  Cr  Vr  Ca  Vc
```

- `Vv` — must be a key of the Vv table (§4.1); one character.
- `Cr` — 1 to 4 characters, each from the root inventory (§2.3, first
  table). Longer clusters or clusters containing `w y h '` are rejected.
- `Vr` — must be a key of the Vr table (§4.2); one character.
- `Ca` — must be a key of the Ca table (§4.3); one character.
- `Vc` — must be a Vc form (§4.4); one or two characters (the run `ëi`).

Any other run count or run content ⇒ `unsupported`. In particular:
consonant-initial words (would need Slot I Cc), words with more than five
runs (affixes/adjuncts), the empty word, and whitespace-interior strings are
all rejected.

## 4. Lookup tables (closed; exact rows)

### 4.1 Vv — stem + version (Slot II)

Version: 0 = PRC (processual), 1 = CPT (completive).

| Vv | stem | version | | Vv | stem | version |
|---|---|---|---|---|---|---|
| `a` | 1 | 0 (PRC) | | `ä` | 1 | 1 (CPT) |
| `e` | 2 | 0 (PRC) | | `i` | 2 | 1 (CPT) |
| `u` | 3 | 0 (PRC) | | `ü` | 3 | 1 (CPT) |
| `o` | 0 | 0 (PRC) | | `ö` | 0 | 1 (CPT) |

### 4.2 Vr — function + specification (Slot IV; context fixed at EXS)

Function: 0 = STA (stative), 1 = DYN (dynamic).
Specification: 0 = BSC, 1 = CTE, 2 = CSV, 3 = OBJ.
core-v1 encodes only the existential context (EXS); other contexts have no
representation in this profile.

| Vr | function | spec | | Vr | function | spec |
|---|---|---|---|---|---|---|
| `a` | 0 (STA) | 0 (BSC) | | `u` | 1 (DYN) | 0 (BSC) |
| `ä` | 0 (STA) | 1 (CTE) | | `ü` | 1 (DYN) | 1 (CTE) |
| `e` | 0 (STA) | 2 (CSV) | | `o` | 1 (DYN) | 2 (CSV) |
| `i` | 0 (STA) | 3 (OBJ) | | `ö` | 1 (DYN) | 3 (OBJ) |

### 4.3 Ca — perspective (Slot VI; defaults elsewhere)

The four single-consonant default Ca forms (configuration UNI, extension DEL,
affiliation CSL, essence NRM):

| Ca | perspective |
|---|---|
| `l` | 0 — M (monadic) |
| `r` | 1 — G (agglomerative) |
| `w` | 2 — N (nomic) |
| `y` | 3 — A (abstract) |

### 4.4 Vc — case (Slot IX; cases 1–9)

| Vc | case index | case | | Vc | case index | case |
|---|---|---|---|---|---|---|
| `a` | 0 | THM | | `ö` | 5 | EFF |
| `ä` | 1 | INS | | `o` | 6 | ERG |
| `e` | 2 | ABS | | `ü` | 7 | DAT |
| `i` | 3 | AFF | | `u` | 8 | IND |
| `ëi` | 4 | STM | | | | |

`ëi` is the two-codepoint sequence U+00EB U+0069 and is matched as the whole
vowel run (a Vc run of exactly `ë` followed by `i`). Any other vowel run in
Vc position (`ai`, `ë` alone, `ëu`, ...) is rejected.

## 5. Root cluster ↔ base-27 integer (bijective numeration)

The Cr cluster is read as a **bijective base-27 numeral** over the root
inventory, digit values 1–27 per the normative order in §2.3 (there is no
zero digit). For a cluster `c₁ c₂ … c_k` (left = most significant), with
`d(c)` the 1-based position:

```text
base = ((…((d(c₁))·27 + d(c₂))·27 + …)·27 + d(c_k))
     = Σᵢ d(cᵢ) · 27^(k−i)
```

Equivalently, encoding is the left fold `acc ← acc·27 + d(c)` starting from
`acc = 0`. Decoding (used by `to_latin`):

```text
while n > 0:
    digit ← ((n − 1) mod 27) + 1        # 1..27
    prepend consonant #digit
    n ← (n − 1) div 27
```

This is a bijection between non-empty clusters and integers ≥ 1: every
cluster has exactly one code and every integer ≥ 1 decodes to exactly one
cluster. Clusters are limited to **k ≤ 4**, so valid root codes are
`1 ≤ base ≤ 551880` (= 27 + 27² + 27³ + 27⁴). `to_latin` MUST reject any
base outside that range (base 0, or any base whose decode exceeds four
consonants) with `unsupported`.

Worked examples:

```text
"p"   →  1                                   (first single consonant)
"ň"   →  27                                  (last single consonant)
"pp"  →  1·27 + 1            = 28            (first 2-cluster — no zero digit)
"kš"  →  5·27 + 15           = 150
"kšt" →  (5·27 + 15)·27 + 3  = 4053
"ňňňň" → 551880                              (maximum root code)

decode 28:  d = ((28−1) mod 27)+1 = 1 → "p";  n = (28−1) div 27 = 1
            d = ((1−1)  mod 27)+1 = 1 → "p";  n = 0        ⇒ "pp"
```

## 6. Morpheme → coordinate mapping (provisional, normative for v1)

Parsed slot values populate one glyph of a schema-v1 word (CODEC.md §2).
**This mapping is provisional** — it will be superseded by the generated
`spec/*.yaml` registries in a later profile version — **but it is normative
for core-v1**: only this exact tuple shape is produced or accepted.

```text
word                     = version 1, exactly one glyph
glyph.character_class    = 0                        (formative)
glyph.base               = root code (§5), ≥ 1
glyph.orientation        = stem                     (0..3, from Vv)
socket 0 modifier.shape        = specification      (0..3, from Vr)
socket 0 modifier.orientation  = function + 2·version   (0..3; STA/PRC 0,
                                                     DYN/PRC 1, STA/CPT 2,
                                                     DYN/CPT 3)
socket 1 modifier.shape        = perspective        (0..3, from Ca)
socket 1 modifier.orientation  = 0
socket 2 modifier.shape        = case index         (0..8, from Vc)
socket 2 modifier.orientation  = 0
```

All three sockets are always emitted, in ascending order 0, 1, 2 (they are
semantically occupied). Every modifier has empty `diacritics` and empty
child `sockets`. No other sockets, no diacritics, no nesting.

JSON wire form of the produced coordinate (CODEC.md §2):

```json
["ithkuil-word", 1, [
  ["glyph", 0, BASE, STEM, [
    [0, ["modifier", SPEC, FUNCTION + 2*VERSION, [], []]],
    [1, ["modifier", PERSPECTIVE, 0, [], []]],
    [2, ["modifier", CASE_INDEX, 0, [], []]]
  ]]
]]
```

## 7. `to_latin` — canonical spelling

`to_latin` accepts **exactly** coordinates of the §6 shape:

- version 1; exactly one glyph; `character_class` 0;
- `base` an integer in 1..551880 whose §5 decode has ≤ 4 consonants;
- glyph `orientation` (stem) in 0..3;
- exactly the three sockets 0, 1, 2, each `["modifier", shape, orientation,
  [], []]` with: socket 0 shape 0..3 and orientation 0..3; socket 1 shape
  0..3 and orientation 0; socket 2 shape 0..8 and orientation 0.

Anything else — zero or multiple glyphs, other classes, other socket
layouts, diacritics, child sockets, out-of-range shapes/orientations —
returns `unsupported`. (Per SDK-INTERFACE.md, coordinate *inputs* at
wire/JSON boundaries are first canonicalized — sockets sorted, `[id, null]`
empties dropped — before this shape check.)

Output is the concatenation, with no separators:

```text
to_latin = Vv ‖ Cr ‖ Vr ‖ Ca ‖ Vc
```

where each field is produced by inverting its §4/§5 table:
`Vv` from (stem, version) with `version = fn_ver div 2`;
`Vr` from (function, spec) with `function = fn_ver mod 2`;
`Ca` from perspective; `Cr` by decoding `base` (§5); `Vc` by case index.

The result is all-lowercase, NFC (guaranteed: the inventory contains only
precomposed codepoints), with no whitespace. This is the **canonical
spelling**; it is unique per in-profile coordinate. Round-trip laws:

```text
from_latin(to_latin(c)) == c            for every in-profile coordinate c
to_latin(from_latin(w)) == canonical(w) for every accepted w
```

where `canonical(w)` is `w` after §1 preprocessing (accepted words differ
from their canonical spelling only by trim/case/normalization).

## 8. Error behavior

Everything outside the profile is rejected with the stable error code
**`unsupported`** (SDK-INTERFACE.md §3), carrying an implementation-chosen
human-readable detail. **The code is normative; detail payloads are not.**
Rejection categories (all `unsupported`):

| Category | Example input |
|---|---|
| empty word (after trim) | `""` |
| stress-marked vowel (Slot X) | `"álala"` |
| character outside the inventories | `"qalala"` |
| word shape ≠ V C V C V (Cc, affixes, adjuncts, hyphens/concatenation) | `"hjalala"`, `"alalala"` |
| Vv not in §4.1 | `"ëlala"` |
| Cr consonant outside the root inventory | `"awala"` (`w` is Ca-only) |
| Cr cluster longer than 4 | `"apppppalu"` |
| Vr not in §4.2 | — |
| Ca not in §4.3 | `"alapa"` |
| Vc not in §4.4 | `"alalai"` |
| `to_latin`: coordinate outside §7 shape | root code 0, case index 9, extra sockets, ... |

Inputs outside the operation's value domain entirely (a non-string passed to
`from_latin`, a non-coordinate passed to `to_latin`) are a language-level
concern: statically-typed SDKs make them unrepresentable; dynamic SDKs
report their structural-error convention (Elixir: `{:invalid_input, _}`;
Python/Node: `invalid_structure`-class errors). This case is outside the
profile and never reachable from conformance vectors.

Implementations MUST NOT repair, guess, or partially parse: any failure in
§1–§7 rejects the whole input.

## 9. Worked examples (latin → coordinate wire form)

### 9.1 `"alala"` — the canonical smoke test

```text
preprocess : "alala"                       (already canonical)
segment    : V"a" C"l" V"a" C"l" V"a"      → Vv="a" Cr="l" Vr="a" Ca="l" Vc="a"
Vv  "a"    : stem 1, version 0 (PRC)
Cr  "l"    : d(l)=22 → base 22
Vr  "a"    : function 0 (STA), spec 0 (BSC) → socket0 shape 0, orient 0+2·0 = 0
Ca  "l"    : perspective 0 (M)              → socket1 shape 0, orient 0
Vc  "a"    : case 0 (THM)                   → socket2 shape 0, orient 0
```

```json
["ithkuil-word", 1, [["glyph", 0, 22, 1, [
  [0, ["modifier", 0, 0, [], []]],
  [1, ["modifier", 0, 0, [], []]],
  [2, ["modifier", 0, 0, [], []]]]]]]
```

### 9.2 `"ürzoyu"` — CPT + DYN (socket-0 orientation 3), Ca `y`

```text
segment    : Vv="ü" Cr="rz" Vr="o" Ca="y" Vc="u"
Vv  "ü"    : stem 3, version 1 (CPT)
Cr  "rz"   : d(r)=23, d(z)=12 → 23·27 + 12 = 633
Vr  "o"    : function 1 (DYN), spec 2 (CSV) → socket0 shape 2, orient 1+2·1 = 3
Ca  "y"    : perspective 3 (A)
Vc  "u"    : case 8 (IND)
```

```json
["ithkuil-word", 1, [["glyph", 0, 633, 3, [
  [0, ["modifier", 2, 3, [], []]],
  [1, ["modifier", 3, 0, [], []]],
  [2, ["modifier", 8, 0, [], []]]]]]]
```

### 9.3 `"akšalëi"` — 2-consonant root, digraph Vc

```text
segment    : Vv="a" Cr="kš" Vr="a" Ca="l" Vc="ëi"
Vv  "a"    : stem 1, version 0
Cr  "kš"   : d(k)=5, d(š)=15 → 5·27 + 15 = 150
Vr  "a"    : STA/BSC → socket0 shape 0, orient 0
Ca  "l"    : perspective 0 (M)
Vc  "ëi"   : case 4 (STM)          (the whole vowel run matches the digraph)
```

```json
["ithkuil-word", 1, [["glyph", 0, 150, 1, [
  [0, ["modifier", 0, 0, [], []]],
  [1, ["modifier", 0, 0, [], []]],
  [2, ["modifier", 4, 0, [], []]]]]]]
```

### 9.4 `"ekštalu"` — 3-consonant root

```text
segment    : Vv="e" Cr="kšt" Vr="a" Ca="l" Vc="u"
Vv  "e"    : stem 2, version 0 (PRC)
Cr  "kšt"  : ((0·27+5)·27+15)·27+3 = (5·27+15)·27+3 = 150·27+3 = 4053
Vr  "a"    : STA/BSC → socket0 shape 0, orient 0
Ca  "l"    : perspective 0 (M)
Vc  "u"    : case 8 (IND)
```

```json
["ithkuil-word", 1, [["glyph", 0, 4053, 2, [
  [0, ["modifier", 0, 0, [], []]],
  [1, ["modifier", 0, 0, [], []]],
  [2, ["modifier", 8, 0, [], []]]]]]]
```

### 9.5 `"  Alala "` — preprocessing only

Trim → `"Alala"`, NFC (no-op), lowercase → `"alala"`; thereafter identical
to §9.1. `to_latin` of the result returns the canonical spelling `"alala"`,
not the original input.

## 10. Conformance

`conformance/latin_to_coordinate.jsonl` carries the normative vectors:
`{"latin", "coordinate", "canonical"}` rows MUST satisfy
`from_latin(latin) == coordinate` and `to_latin(coordinate) == canonical`;
`{"latin", "error"}` rows MUST reject with the given code. Every SDK's test
suite MUST drive every vector in both directions where defined
(SDK-INTERFACE.md §5).
