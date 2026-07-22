package ithkuil

// Romanization profile core-v1. Normative: ../ROMANIZATION.md; the
// conformance vectors in ../conformance/latin_to_coordinate.jsonl are the
// arbiter.
//
// core-v1 accepts exactly one word shape — an unconcatenated formative
// `Vv Cr Vr Ca Vc` (slots II, III, IV, VI, IX) — with closed tables for
// each slot. Everything else (Slot I Cc, affixes, VnCn, stress, glottal
// stop, adjuncts, multiple words, ...) is rejected with ErrUnsupported; the
// profile never guesses.
//
// Every non-ASCII literal below is a single PRECOMPOSED codepoint (NFC),
// exactly as inventoried in ROMANIZATION.md §2 — never a base letter plus a
// combining mark (which would not even compile as a rune literal).

import "strings"

const maxRootCluster = 4

// ---------------------------------------------------------------------------
// Preprocessing (ROMANIZATION.md §1): trim -> NFC -> lowercase.
// ---------------------------------------------------------------------------

// composeTable maps the decomposed (base rune, combining mark) sequences of
// the profile alphabet to their precomposed NFC codepoints.
//
// The Go standard library has no NFC normalizer (that lives in
// golang.org/x/text, and this SDK is stdlib-only), so full NFC is
// approximated by targeted composition over exactly the ROMANIZATION.md §2
// inventory — every profile character plus the stress-marked vowels of
// §2.2, in both cases (composition runs before lowercasing per §1). Any
// sequence outside this table is left untouched and is then rejected as
// ErrUnsupported by classification, which is the required outcome for all
// out-of-alphabet input anyway, so the approximation is behaviorally exact
// for the profile.
var composeTable = map[[2]rune]rune{
	// U+0308 combining diaeresis
	{'a', 0x0308}: 'ä', // ä
	{'e', 0x0308}: 'ë', // ë
	{'o', 0x0308}: 'ö', // ö
	{'u', 0x0308}: 'ü', // ü
	{'A', 0x0308}: 'Ä', // Ä
	{'E', 0x0308}: 'Ë', // Ë
	{'O', 0x0308}: 'Ö', // Ö
	{'U', 0x0308}: 'Ü', // Ü
	// U+0301 combining acute (stress marking; composed so it classifies as
	// a stress vowel rather than a stray combining mark)
	{'a', 0x0301}: 'á', // á
	{'e', 0x0301}: 'é', // é
	{'i', 0x0301}: 'í', // í
	{'o', 0x0301}: 'ó', // ó
	{'u', 0x0301}: 'ú', // ú
	{'A', 0x0301}: 'Á', // Á
	{'E', 0x0301}: 'É', // É
	{'I', 0x0301}: 'Í', // Í
	{'O', 0x0301}: 'Ó', // Ó
	{'U', 0x0301}: 'Ú', // Ú
	// U+0302 combining circumflex (stress marking)
	{'a', 0x0302}: 'â', // â
	{'e', 0x0302}: 'ê', // ê
	{'i', 0x0302}: 'î', // î
	{'o', 0x0302}: 'ô', // ô
	{'u', 0x0302}: 'û', // û
	{'A', 0x0302}: 'Â', // Â
	{'E', 0x0302}: 'Ê', // Ê
	{'I', 0x0302}: 'Î', // Î
	{'O', 0x0302}: 'Ô', // Ô
	{'U', 0x0302}: 'Û', // Û
	// U+030C combining caron
	{'s', 0x030C}: 'š', // š
	{'z', 0x030C}: 'ž', // ž
	{'c', 0x030C}: 'č', // č
	{'r', 0x030C}: 'ř', // ř
	{'n', 0x030C}: 'ň', // ň
	{'S', 0x030C}: 'Š', // Š
	{'Z', 0x030C}: 'Ž', // Ž
	{'C', 0x030C}: 'Č', // Č
	{'R', 0x030C}: 'Ř', // Ř
	{'N', 0x030C}: 'Ň', // Ň
	// U+0327 combining cedilla
	{'t', 0x0327}: 'ţ', // ţ
	{'d', 0x0327}: 'ḑ', // ḑ
	{'c', 0x0327}: 'ç', // ç
	{'l', 0x0327}: 'ļ', // ļ
	{'T', 0x0327}: 'Ţ', // Ţ
	{'D', 0x0327}: 'Ḑ', // Ḑ
	{'C', 0x0327}: 'Ç', // Ç
	{'L', 0x0327}: 'Ļ', // Ļ
	// U+0323 combining dot below
	{'z', 0x0323}: 'ẓ', // ẓ
	{'Z', 0x0323}: 'Ẓ', // Ẓ
}

// composeProfile performs the targeted NFC composition described at
// composeTable. Greedy left-to-right: each rune absorbs following combining
// marks as long as a composition exists.
func composeProfile(s string) string {
	runes := []rune(s)
	out := make([]rune, 0, len(runes))
	for i := 0; i < len(runes); {
		r := runes[i]
		i++
		for i < len(runes) {
			c, ok := composeTable[[2]rune{r, runes[i]}]
			if !ok {
				break
			}
			r = c
			i++
		}
		out = append(out, r)
	}
	return string(out)
}

// ---------------------------------------------------------------------------
// Character inventories (ROMANIZATION.md §2; exact codepoints, NFC).
// ---------------------------------------------------------------------------

// vowelSet — the 9 vowel codepoints of §2.1.
var vowelSet = map[rune]bool{
	'a': true,
	'e': true,
	'i': true,
	'o': true,
	'u': true,
	'ä': true, // ä U+00E4
	'ë': true, // ë U+00EB
	'ö': true, // ö U+00F6
	'ü': true, // ü U+00FC
}

// stressVowelSet — §2.2, always rejected (Slot X stress).
var stressVowelSet = map[rune]bool{
	'á': true, // á
	'é': true, // é
	'í': true, // í
	'ó': true, // ó
	'ú': true, // ú
	'â': true, // â
	'ê': true, // ê
	'î': true, // î
	'ô': true, // ô
	'û': true, // û
}

// rootConsonants — the 27-consonant root inventory in the NORMATIVE order
// of §2.3: the bijective base-27 digit of a consonant is its index here
// plus one.
var rootConsonants = []rune{
	'p', 'b', 't', 'd', 'k', 'g', 'f', 'v', 'ţ', // 1-9:   p b t d k g f v ţ
	'ḑ', 's', 'z', 'c', 'ẓ', 'š', 'ž', 'č', 'j', // 10-18: ḑ s z c ẓ š ž č j
	'ç', 'x', 'ļ', 'l', 'r', 'ř', 'm', 'n', 'ň', // 19-27: ç x ļ l r ř m n ň
}

// rootDigit maps a root consonant to its 1-based digit value.
var rootDigit = func() map[rune]int {
	m := make(map[rune]int, len(rootConsonants))
	for i, r := range rootConsonants {
		m[r] = i + 1
	}
	return m
}()

// segmenterOnly — characters that classify as consonants for run
// segmentation but are valid only where a table row admits them (w/y in Ca)
// or nowhere (h, ').
var segmenterOnly = map[rune]bool{'w': true, 'y': true, 'h': true, '\'': true}

// ---------------------------------------------------------------------------
// Lookup tables (ROMANIZATION.md §4; closed, exact rows).
// ---------------------------------------------------------------------------

type vvEntry struct{ stem, version int } // version: 0 = PRC, 1 = CPT

var vvTable = map[rune]vvEntry{
	'a': {1, 0},
	'ä': {1, 1}, // ä
	'e': {2, 0},
	'i': {2, 1},
	'u': {3, 0},
	'ü': {3, 1}, // ü
	'o': {0, 0},
	'ö': {0, 1}, // ö
}

var vvInverse = func() map[vvEntry]rune {
	m := make(map[vvEntry]rune, len(vvTable))
	for k, v := range vvTable {
		m[v] = k
	}
	return m
}()

type vrEntry struct{ function, spec int } // function: 0 = STA, 1 = DYN

var vrTable = map[rune]vrEntry{
	'a': {0, 0},
	'ä': {0, 1}, // ä
	'e': {0, 2},
	'i': {0, 3},
	'u': {1, 0},
	'ü': {1, 1}, // ü
	'o': {1, 2},
	'ö': {1, 3}, // ö
}

var vrInverse = func() map[vrEntry]rune {
	m := make(map[vrEntry]rune, len(vrTable))
	for k, v := range vrTable {
		m[v] = k
	}
	return m
}()

// caTable: perspective (configuration UNI, extension DEL, affiliation CSL,
// essence NRM).
var caTable = map[rune]int{'l': 0, 'r': 1, 'w': 2, 'y': 3}

var caInverse = func() map[int]rune {
	m := make(map[int]rune, len(caTable))
	for k, v := range caTable {
		m[v] = k
	}
	return m
}()

// vcForms: case index 0..8 (THM INS ABS AFF STM EFF ERG DAT IND). Index 4
// is the two-codepoint digraph "ëi", matched as the whole vowel run.
var vcForms = []string{
	"a",
	"ä", // ä
	"e",
	"i",
	"ëi", // ëi
	"ö",  // ö
	"o",
	"ü", // ü
	"u",
}

// ---------------------------------------------------------------------------
// Segmentation (ROMANIZATION.md §3).
// ---------------------------------------------------------------------------

type latinRun struct {
	vowel bool
	text  []rune
}

func classifyRune(r rune) (vowel bool, err error) {
	switch {
	case stressVowelSet[r]:
		return false, errf(ErrUnsupported,
			"stress-marked vowel %q (Slot X) is outside profile core-v1", r)
	case vowelSet[r]:
		return true, nil
	case rootDigit[r] != 0 || segmenterOnly[r]:
		return false, nil
	default:
		return false, errf(ErrUnsupported, "character %q is outside the profile inventories", r)
	}
}

func segmentLatin(word string) ([]latinRun, error) {
	var runs []latinRun
	for _, r := range word {
		vowel, err := classifyRune(r)
		if err != nil {
			return nil, err
		}
		if n := len(runs); n > 0 && runs[n-1].vowel == vowel {
			runs[n-1].text = append(runs[n-1].text, r)
		} else {
			runs = append(runs, latinRun{vowel: vowel, text: []rune{r}})
		}
	}
	return runs, nil
}

// ---------------------------------------------------------------------------
// FromLatin / ToLatin.
// ---------------------------------------------------------------------------

// FromLatin parses romanized New Ithkuil text (profile core-v1) into a
// canonical Word. Input is preprocessed per ROMANIZATION.md §1: trim,
// Unicode NFC (approximated over the profile alphabet, see composeTable),
// then lowercase. Everything outside the profile rejects with
// ErrUnsupported.
func FromLatin(text string) (Word, error) {
	word := strings.ToLower(composeProfile(strings.TrimSpace(text)))
	if word == "" {
		return Word{}, errf(ErrUnsupported, "empty word")
	}
	runs, err := segmentLatin(word)
	if err != nil {
		return Word{}, err
	}
	// Exactly five runs, alternating, vowel first: Vv Cr Vr Ca Vc.
	if len(runs) != 5 || !runs[0].vowel || runs[1].vowel || !runs[2].vowel ||
		runs[3].vowel || !runs[4].vowel {
		return Word{}, errf(ErrUnsupported,
			"word shape must be Vv Cr Vr Ca Vc (five alternating runs, vowel first), got %d run(s)",
			len(runs))
	}
	vvRun, crRun, vrRun, caRun, vcRun := runs[0].text, runs[1].text, runs[2].text, runs[3].text, runs[4].text

	// Vv — stem + version (§4.1); one character.
	if len(vvRun) != 1 {
		return Word{}, errf(ErrUnsupported, "Vv %q is not a single stem/version vowel", string(vvRun))
	}
	vv, ok := vvTable[vvRun[0]]
	if !ok {
		return Word{}, errf(ErrUnsupported, "Vv %q has no stem/version row", string(vvRun))
	}

	// Cr — root cluster as a bijective base-27 numeral (§5); 1..4 root
	// consonants.
	if len(crRun) > maxRootCluster {
		return Word{}, errf(ErrUnsupported,
			"root cluster %q is longer than %d consonants", string(crRun), maxRootCluster)
	}
	base := uint64(0)
	for _, c := range crRun {
		d, ok := rootDigit[c]
		if !ok {
			return Word{}, errf(ErrUnsupported,
				"consonant %q is not in the root inventory", c)
		}
		base = base*27 + uint64(d)
	}

	// Vr — function + specification (§4.2); one character.
	if len(vrRun) != 1 {
		return Word{}, errf(ErrUnsupported, "Vr %q is not a single function/specification vowel", string(vrRun))
	}
	vr, ok := vrTable[vrRun[0]]
	if !ok {
		return Word{}, errf(ErrUnsupported, "Vr %q has no function/specification row", string(vrRun))
	}

	// Ca — perspective (§4.3); one character.
	if len(caRun) != 1 {
		return Word{}, errf(ErrUnsupported, "Ca %q is not a single perspective consonant", string(caRun))
	}
	perspective, ok := caTable[caRun[0]]
	if !ok {
		return Word{}, errf(ErrUnsupported, "Ca %q is not one of l/r/w/y", string(caRun))
	}

	// Vc — case (§4.4); the whole vowel run must match one form.
	vcStr := string(vcRun)
	caseIndex := -1
	for i, form := range vcForms {
		if form == vcStr {
			caseIndex = i
			break
		}
	}
	if caseIndex < 0 {
		return Word{}, errf(ErrUnsupported, "Vc %q is not a case vowel form of the profile", vcStr)
	}

	// §6 morpheme -> coordinate mapping (provisional, normative for v1).
	return Word{Version: 1, Glyphs: []Glyph{{
		CharacterClass: 0, // formative
		Base:           base,
		Orientation:    vv.stem,
		Sockets: []Socket{
			{ID: 0, Modifier: Modifier{Shape: uint64(vr.spec), Orientation: vr.function + 2*vv.version}},
			{ID: 1, Modifier: Modifier{Shape: uint64(perspective), Orientation: 0}},
			{ID: 2, Modifier: Modifier{Shape: uint64(caseIndex), Orientation: 0}},
		},
	}}}, nil
}

// ToLatin emits the canonical spelling (ROMANIZATION.md §7) of a coordinate
// of exactly the §6 shape. The input is canonicalized first (native input
// is lenient per SDK-INTERFACE.md §2); anything outside the profile shape
// rejects with ErrUnsupported. The result is trimmed, NFC, lowercase.
func ToLatin(w Word) (string, error) {
	c, err := Canonicalize(w)
	if err != nil {
		return "", err
	}
	if c.Version != 1 || len(c.Glyphs) != 1 {
		return "", errf(ErrUnsupported,
			"profile core-v1 covers exactly one glyph at schema version 1, got version %d with %d glyph(s)",
			c.Version, len(c.Glyphs))
	}
	g := c.Glyphs[0]
	if g.CharacterClass != 0 {
		return "", errf(ErrUnsupported,
			"character class %d has no romanization in profile core-v1", g.CharacterClass)
	}
	if len(g.Sockets) != 3 || g.Sockets[0].ID != 0 || g.Sockets[1].ID != 1 || g.Sockets[2].ID != 2 {
		return "", errf(ErrUnsupported, "profile core-v1 requires exactly sockets 0, 1, 2")
	}
	m0 := g.Sockets[0].Modifier
	m1 := g.Sockets[1].Modifier
	m2 := g.Sockets[2].Modifier
	for i, m := range []Modifier{m0, m1, m2} {
		if len(m.Diacritics) != 0 || len(m.Sockets) != 0 {
			return "", errf(ErrUnsupported,
				"socket %d: diacritics and child sockets have no romanization in profile core-v1", i)
		}
	}
	if m0.Shape > 3 { // specification
		return "", errf(ErrUnsupported, "socket 0 shape %d is outside the Vr table", m0.Shape)
	}
	if m1.Shape > 3 || m1.Orientation != 0 { // perspective
		return "", errf(ErrUnsupported, "socket 1 must be a perspective modifier (shape 0..3, orientation 0)")
	}
	if m2.Shape > 8 || m2.Orientation != 0 { // case
		return "", errf(ErrUnsupported, "socket 2 must be a case modifier (shape 0..8, orientation 0)")
	}
	if g.Base < 1 {
		return "", errf(ErrUnsupported,
			"root code 0 has no consonant cluster (bijective numeration starts at 1)")
	}
	cluster, err := decodeRootCluster(g.Base)
	if err != nil {
		return "", err
	}
	fnVer := m0.Orientation // 0..3, range-checked by Canonicalize
	vv := vvInverse[vvEntry{stem: g.Orientation, version: fnVer / 2}]
	vr := vrInverse[vrEntry{function: fnVer % 2, spec: int(m0.Shape)}]
	ca := caInverse[int(m1.Shape)]
	vc := vcForms[int(m2.Shape)]
	return string(vv) + cluster + string(vr) + string(ca) + vc, nil
}

// decodeRootCluster inverts the bijective base-27 numeration of
// ROMANIZATION.md §5: digit = ((n−1) mod 27) + 1, prepend consonant #digit,
// n = (n−1) div 27. Rejects codes decoding to more than four consonants
// (valid root codes are 1..551880).
func decodeRootCluster(base uint64) (string, error) {
	var cluster []rune
	for n := base; n > 0; {
		if len(cluster) == maxRootCluster {
			return "", errf(ErrUnsupported,
				"root code %d decodes to more than %d consonants", base, maxRootCluster)
		}
		d := (n-1)%27 + 1
		cluster = append([]rune{rootConsonants[d-1]}, cluster...)
		n = (n - 1) / 27
	}
	return string(cluster), nil
}
