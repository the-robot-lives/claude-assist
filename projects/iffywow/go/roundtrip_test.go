package ithkuil

// Property tests: the SDK-INTERFACE.md §5 round-trip laws over ~300
// generated valid Words (seeded LCG — deterministic, no external deps),
// plus targeted lenient-boundary checks.

import (
	"errors"
	"strings"
	"testing"
)

// ---------------------------------------------------------------------------
// Deterministic generator (64-bit LCG, Knuth MMIX constants).
// ---------------------------------------------------------------------------

type lcg uint64

func (l *lcg) next() uint64 {
	*l = *l*6364136223846793005 + 1442695040888963407
	return uint64(*l)
}

// intn returns a value in [0, n). Uses the high bits; the tiny modulo bias
// is irrelevant for test-case generation.
func (l *lcg) intn(n int) int {
	return int((l.next() >> 11) % uint64(n))
}

func genWord(r *lcg) Word {
	nGlyphs := r.intn(4) // 0..3 glyphs
	var glyphs []Glyph
	for i := 0; i < nGlyphs; i++ {
		glyphs = append(glyphs, genGlyph(r))
	}
	return Word{Version: 1 + r.intn(3), Glyphs: glyphs}
}

func genGlyph(r *lcg) Glyph {
	return Glyph{
		CharacterClass: uint64(r.intn(6)),
		Base:           uint64(r.intn(600000)),
		Orientation:    r.intn(MaxOrientation + 1),
		Sockets:        genSockets(r, 2),
	}
}

// genSockets emits strictly ascending socket IDs by construction.
func genSockets(r *lcg, depth int) []Socket {
	var out []Socket
	for id := 0; id <= MaxSocketID; id++ {
		if r.intn(4) == 0 { // ~25% occupancy per socket
			out = append(out, Socket{ID: id, Modifier: genModifier(r, depth)})
		}
	}
	return out
}

func genModifier(r *lcg, depth int) Modifier {
	m := Modifier{
		Shape:       uint64(r.intn(50)),
		Orientation: r.intn(MaxOrientation + 1),
	}
	if n := r.intn(3); n > 0 {
		m.Diacritics = make([]uint64, n)
		for i := range m.Diacritics {
			m.Diacritics[i] = uint64(r.intn(30))
		}
	}
	if depth > 0 && r.intn(3) == 0 {
		m.Sockets = genSockets(r, depth-1)
	}
	return m
}

// ---------------------------------------------------------------------------
// §5 laws over generated valid Words.
// ---------------------------------------------------------------------------

func TestRoundTripLaws(t *testing.T) {
	r := lcg(0x1FF7_2026_0717)
	for i := 0; i < 300; i++ {
		w := genWord(&r)
		if err := Validate(w); err != nil {
			t.Fatalf("case %d: generator produced an invalid word: %v", i, err)
		}

		// from_bytes(to_bytes(c)) == c
		data := ToBytes(w)
		if back, err := FromBytes(data); err != nil {
			t.Fatalf("case %d: FromBytes(ToBytes) failed: %v", i, err)
		} else if !wordEqual(back, w) {
			t.Fatalf("case %d: bytes round trip changed the word", i)
		}

		// from_integer(to_integer(c)) == c
		n := ToInteger(w)
		if back, err := FromInteger(n); err != nil {
			t.Fatalf("case %d: FromInteger(ToInteger) failed: %v", i, err)
		} else if !wordEqual(back, w) {
			t.Fatalf("case %d: integer round trip changed the word", i)
		}

		// from_integer_string(to_integer_string(c)) == c
		s := ToIntegerString(w)
		if back, err := FromIntegerString(s); err != nil {
			t.Fatalf("case %d: FromIntegerString(ToIntegerString) failed: %v", i, err)
		} else if !wordEqual(back, w) {
			t.Fatalf("case %d: integer-string round trip changed the word", i)
		}

		// from_wire(to_wire(c)) == c
		if back, err := FromWire(ToWire(w)); err != nil {
			t.Fatalf("case %d: FromWire(ToWire) failed: %v", i, err)
		} else if !wordEqual(back, w) {
			t.Fatalf("case %d: wire round trip changed the word", i)
		}

		// from_wire_json(to_wire_json(c)) == c
		j, err := ToWireJSON(w)
		if err != nil {
			t.Fatalf("case %d: ToWireJSON failed: %v", i, err)
		}
		if back, err := FromWireJSON(j); err != nil {
			t.Fatalf("case %d: FromWireJSON(ToWireJSON) failed: %v", i, err)
		} else if !wordEqual(back, w) {
			t.Fatalf("case %d: wire JSON round trip changed the word", i)
		}
	}
}

// ---------------------------------------------------------------------------
// Latin laws over generated in-profile coordinates (ROMANIZATION.md §6/§7).
// ---------------------------------------------------------------------------

func genProfileWord(r *lcg) Word {
	return Word{Version: 1, Glyphs: []Glyph{{
		CharacterClass: 0,
		Base:           uint64(1 + r.intn(551880)), // valid root codes: 1..551880
		Orientation:    r.intn(4),                  // stem
		Sockets: []Socket{
			{ID: 0, Modifier: Modifier{Shape: uint64(r.intn(4)), Orientation: r.intn(4)}},
			{ID: 1, Modifier: Modifier{Shape: uint64(r.intn(4)), Orientation: 0}},
			{ID: 2, Modifier: Modifier{Shape: uint64(r.intn(9)), Orientation: 0}},
		},
	}}}
}

func TestLatinRoundTripLaws(t *testing.T) {
	r := lcg(0xC0DEC_1)
	for i := 0; i < 300; i++ {
		c := genProfileWord(&r)

		// from_latin(to_latin(c)) == c  (for c in profile)
		latin, err := ToLatin(c)
		if err != nil {
			t.Fatalf("case %d: ToLatin failed on in-profile word: %v", i, err)
		}
		back, err := FromLatin(latin)
		if err != nil {
			t.Fatalf("case %d: FromLatin(%q) failed: %v", i, latin, err)
		}
		if !wordEqual(back, c) {
			t.Fatalf("case %d: latin round trip changed the word (%q)", i, latin)
		}

		// to_latin(from_latin(w)) == canonicalize(w): preprocessing folds
		// whitespace and case back to the canonical spelling.
		messy := "  " + strings.ToUpper(latin) + " "
		w2, err := FromLatin(messy)
		if err != nil {
			t.Fatalf("case %d: FromLatin(%q) failed: %v", i, messy, err)
		}
		if !wordEqual(w2, c) {
			t.Fatalf("case %d: preprocessing changed the parse (%q)", i, messy)
		}
		spelled, err := ToLatin(w2)
		if err != nil {
			t.Fatalf("case %d: ToLatin failed after reparse: %v", i, err)
		}
		if spelled != latin {
			t.Fatalf("case %d: canonical spelling not stable: got %q want %q", i, spelled, latin)
		}
	}
}

// ---------------------------------------------------------------------------
// Lenient boundaries: Canonicalize / FromWire repairs and refusals.
// ---------------------------------------------------------------------------

func TestCanonicalizeSortsAndValidateRejects(t *testing.T) {
	unsorted := Word{Version: 1, Glyphs: []Glyph{{
		Sockets: []Socket{
			{ID: 2, Modifier: Modifier{Shape: 1}},
			{ID: 0, Modifier: Modifier{Shape: 2}},
		},
	}}}

	if err := Validate(unsorted); !errors.Is(err, ErrUnsortedSockets) {
		t.Errorf("Validate: expected ErrUnsortedSockets, got %v", err)
	}

	c, err := Canonicalize(unsorted)
	if err != nil {
		t.Fatalf("Canonicalize failed: %v", err)
	}
	got := c.Glyphs[0].Sockets
	if len(got) != 2 || got[0].ID != 0 || got[1].ID != 2 {
		t.Errorf("Canonicalize did not sort sockets: %+v", got)
	}
	// Deep copy: the caller's slice must be untouched.
	if unsorted.Glyphs[0].Sockets[0].ID != 2 {
		t.Errorf("Canonicalize mutated its input")
	}

	dup := Word{Version: 1, Glyphs: []Glyph{{
		Sockets: []Socket{
			{ID: 1, Modifier: Modifier{}},
			{ID: 1, Modifier: Modifier{Shape: 1}},
		},
	}}}
	if _, err := Canonicalize(dup); !errors.Is(err, ErrDuplicateSocket) {
		t.Errorf("Canonicalize: expected ErrDuplicateSocket, got %v", err)
	}
}

func TestFromWireLenient(t *testing.T) {
	// Unsorted sockets are sorted; [id, null] empties are dropped.
	raw := `["ithkuil-word", 1, [["glyph", 0, 5, 0, [` +
		`[3, null], ` +
		`[1, ["modifier", 4, 0, [], []]], ` +
		`[0, ["modifier", 1, 2, [7], []]]]]]]`
	w, err := FromWireJSON([]byte(raw))
	if err != nil {
		t.Fatalf("FromWireJSON failed: %v", err)
	}
	want := Word{Version: 1, Glyphs: []Glyph{{
		CharacterClass: 0,
		Base:           5,
		Orientation:    0,
		Sockets: []Socket{
			{ID: 0, Modifier: Modifier{Shape: 1, Orientation: 2, Diacritics: []uint64{7}}},
			{ID: 1, Modifier: Modifier{Shape: 4, Orientation: 0}},
		},
	}}}
	if !wordEqual(w, want) {
		t.Errorf("lenient FromWireJSON mismatch: %+v", w)
	}

	// Duplicates are always an error, even with a null side.
	dup := `["ithkuil-word", 1, [["glyph", 0, 0, 0, [[1, null], [1, ["modifier", 0, 0, [], []]]]]]]`
	if _, err := FromWireJSON([]byte(dup)); !errors.Is(err, ErrDuplicateSocket) {
		t.Errorf("expected ErrDuplicateSocket, got %v", err)
	}

	// Non-integral and oversized JSON numbers are structural errors (the
	// float64 wire bound of 2^53−1).
	frac := `["ithkuil-word", 1, [["glyph", 0, 1.5, 0, []]]]`
	if _, err := FromWireJSON([]byte(frac)); !errors.Is(err, ErrInvalidStructure) {
		t.Errorf("expected ErrInvalidStructure for fractional base, got %v", err)
	}
	huge := `["ithkuil-word", 1, [["glyph", 0, 9007199254740993, 0, []]]]`
	if _, err := FromWireJSON([]byte(huge)); !errors.Is(err, ErrInvalidStructure) {
		t.Errorf("expected ErrInvalidStructure for base beyond 2^53-1, got %v", err)
	}

	// Malformed JSON text.
	if _, err := FromWireJSON([]byte(`{"nope`)); !errors.Is(err, ErrInvalidStructure) {
		t.Errorf("expected ErrInvalidStructure for bad JSON, got %v", err)
	}
}

func TestSentinelMatching(t *testing.T) {
	_, err := FromIntegerString("-5")
	if !errors.Is(err, ErrInvalidNaturalNumber) {
		t.Errorf("expected errors.Is(err, ErrInvalidNaturalNumber), got %v", err)
	}
	if errors.Is(err, ErrTruncated) {
		t.Errorf("sentinel matching must compare codes, not merely types")
	}
	var ie *Error
	if !errors.As(err, &ie) || ie.Code != "invalid_natural_number" {
		t.Errorf("expected *Error with code invalid_natural_number, got %v", err)
	}
}
