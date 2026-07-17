package ithkuil

// Golden-vector conformance tests: every row of ../conformance/*.jsonl,
// both directions where defined (SDK-INTERFACE.md §5). These vectors, not
// shared code, keep this SDK in sync with the Elixir production codec and
// the Python reference.

import (
	"bufio"
	"encoding/hex"
	"encoding/json"
	"errors"
	"math/big"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// loadJSONL reads a conformance vector file (one JSON object per line).
// Tests run with the module directory go/ as the working directory, so the
// vectors live at ../conformance/.
func loadJSONL(t *testing.T, name string) []map[string]interface{} {
	t.Helper()
	path := filepath.Join("..", "conformance", name)
	f, err := os.Open(path)
	if err != nil {
		t.Fatalf("cannot open conformance vectors %s: %v", path, err)
	}
	defer f.Close()
	var rows []map[string]interface{}
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 0, 64*1024), 4*1024*1024)
	lineNo := 0
	for sc.Scan() {
		lineNo++
		line := strings.TrimSpace(sc.Text())
		if line == "" {
			continue
		}
		var row map[string]interface{}
		if err := json.Unmarshal([]byte(line), &row); err != nil {
			t.Fatalf("%s:%d: invalid JSON: %v", name, lineNo, err)
		}
		rows = append(rows, row)
	}
	if err := sc.Err(); err != nil {
		t.Fatalf("reading %s: %v", name, err)
	}
	if len(rows) == 0 {
		t.Fatalf("no vectors found in %s", name)
	}
	return rows
}

func mustHex(t *testing.T, s string) []byte {
	t.Helper()
	b, err := hex.DecodeString(s)
	if err != nil {
		t.Fatalf("bad hex in vector %q: %v", s, err)
	}
	return b
}

func mustBig(t *testing.T, s string) *big.Int {
	t.Helper()
	n, ok := new(big.Int).SetString(s, 10)
	if !ok {
		t.Fatalf("bad integer in vector %q", s)
	}
	return n
}

func mustString(t *testing.T, row map[string]interface{}, key string) string {
	t.Helper()
	s, ok := row[key].(string)
	if !ok {
		t.Fatalf("vector field %q is not a string: %v", key, row[key])
	}
	return s
}

// canonicalJSON re-marshals an already-decoded JSON value; used to compare
// wire forms textually (json.Marshal renders integral float64s without a
// decimal point, so this matches the marshaling of ToWire's native ints).
func canonicalJSON(t *testing.T, v interface{}) string {
	t.Helper()
	b, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("cannot re-marshal vector value: %v", err)
	}
	return string(b)
}

// assertCode checks that err is a *Error carrying exactly the expected
// registry code, and that errors.Is sentinel matching agrees.
func assertCode(t *testing.T, err error, code, ctx string) {
	t.Helper()
	if err == nil {
		t.Errorf("%s: expected error %q, got nil", ctx, code)
		return
	}
	var ie *Error
	if !errors.As(err, &ie) {
		t.Errorf("%s: expected *ithkuil.Error, got %T (%v)", ctx, err, err)
		return
	}
	if ie.Code != code {
		t.Errorf("%s: expected code %q, got %q (%v)", ctx, code, ie.Code, err)
	}
	if !errors.Is(err, &Error{Code: code}) {
		t.Errorf("%s: errors.Is failed to match code %q", ctx, code)
	}
}

// ---------------------------------------------------------------------------
// Structural equality helpers (shared with roundtrip_test.go).
// ---------------------------------------------------------------------------

func wordEqual(a, b Word) bool {
	if a.Version != b.Version || len(a.Glyphs) != len(b.Glyphs) {
		return false
	}
	for i := range a.Glyphs {
		if !glyphEqual(a.Glyphs[i], b.Glyphs[i]) {
			return false
		}
	}
	return true
}

func glyphEqual(a, b Glyph) bool {
	return a.CharacterClass == b.CharacterClass &&
		a.Base == b.Base &&
		a.Orientation == b.Orientation &&
		socketsEqual(a.Sockets, b.Sockets)
}

func socketsEqual(a, b []Socket) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i].ID != b[i].ID || !modifierEqual(a[i].Modifier, b[i].Modifier) {
			return false
		}
	}
	return true
}

func modifierEqual(a, b Modifier) bool {
	if a.Shape != b.Shape || a.Orientation != b.Orientation ||
		len(a.Diacritics) != len(b.Diacritics) {
		return false
	}
	for i := range a.Diacritics {
		if a.Diacritics[i] != b.Diacritics[i] {
			return false
		}
	}
	return socketsEqual(a.Sockets, b.Sockets)
}

// ---------------------------------------------------------------------------
// codec_units.jsonl — term-level ser/rank vectors.
// ---------------------------------------------------------------------------

// termFromVector builds an internal term from the conformance JSON shape
// (["nat", n], ["pair", x, y], ["list", [...]], ["bytes", "<hex>"]).
func termFromVector(t *testing.T, v interface{}) *term {
	t.Helper()
	arr, ok := v.([]interface{})
	if !ok || len(arr) < 2 {
		t.Fatalf("malformed term vector: %v", v)
	}
	kind, _ := arr[0].(string)
	switch kind {
	case "nat":
		f, ok := arr[1].(float64)
		if !ok || f < 0 {
			t.Fatalf("malformed nat vector: %v", v)
		}
		return &term{tag: tagNat, nat: new(big.Int).SetUint64(uint64(f))}
	case "pair":
		if len(arr) != 3 {
			t.Fatalf("malformed pair vector: %v", v)
		}
		return &term{tag: tagPair, fst: termFromVector(t, arr[1]), snd: termFromVector(t, arr[2])}
	case "list":
		elems, ok := arr[1].([]interface{})
		if !ok {
			t.Fatalf("malformed list vector: %v", v)
		}
		items := make([]*term, len(elems))
		for i, e := range elems {
			items[i] = termFromVector(t, e)
		}
		return &term{tag: tagList, items: items}
	case "bytes":
		s, ok := arr[1].(string)
		if !ok {
			t.Fatalf("malformed bytes vector: %v", v)
		}
		return &term{tag: tagBytes, data: mustHex(t, s)}
	}
	t.Fatalf("unknown term kind in vector: %v", v)
	return nil
}

func termEqual(a, b *term) bool {
	if a.tag != b.tag {
		return false
	}
	switch a.tag {
	case tagNat:
		return a.nat.Cmp(b.nat) == 0
	case tagPair:
		return termEqual(a.fst, b.fst) && termEqual(a.snd, b.snd)
	case tagList:
		if len(a.items) != len(b.items) {
			return false
		}
		for i := range a.items {
			if !termEqual(a.items[i], b.items[i]) {
				return false
			}
		}
		return true
	case tagBytes:
		return string(a.data) == string(b.data)
	}
	return false
}

func TestCodecUnits(t *testing.T) {
	for _, row := range loadJSONL(t, "codec_units.jsonl") {
		hexStr := mustString(t, row, "bytes")
		data := mustHex(t, hexStr)
		wantInt := mustBig(t, mustString(t, row, "integer"))
		tm := termFromVector(t, row["term"])
		ctx := "bytes " + hexStr

		// serialize / deserialize
		if got := appendTerm(nil, tm); string(got) != string(data) {
			t.Errorf("%s: serialize mismatch: got %x", ctx, got)
		}
		back, err := deserializeTerm(data)
		if err != nil {
			t.Errorf("%s: deserialize failed: %v", ctx, err)
		} else if !termEqual(back, tm) {
			t.Errorf("%s: deserialize produced a different term", ctx)
		}

		// rank / unrank
		if got := rank(data); got.Cmp(wantInt) != 0 {
			t.Errorf("%s: rank mismatch: got %s want %s", ctx, got, wantInt)
		}
		if got := unrank(wantInt); string(got) != string(data) {
			t.Errorf("%s: unrank mismatch: got %x", ctx, got)
		}
	}
}

// ---------------------------------------------------------------------------
// coordinate_to_integer.jsonl — word-level coordinate <-> bytes <-> integer.
// ---------------------------------------------------------------------------

func TestCoordinateToInteger(t *testing.T) {
	for _, row := range loadJSONL(t, "coordinate_to_integer.jsonl") {
		data := mustHex(t, mustString(t, row, "bytes"))
		intStr := mustString(t, row, "integer")
		wantInt := mustBig(t, intStr)
		coordArr, ok := row["coordinate"].([]interface{})
		if !ok {
			t.Fatalf("vector coordinate is not an array: %v", row["coordinate"])
		}
		ctx := "integer " + intStr

		word, err := FromWire(coordArr)
		if err != nil {
			t.Fatalf("%s: FromWire failed: %v", ctx, err)
		}

		// encode direction
		if got := ToBytes(word); string(got) != string(data) {
			t.Errorf("%s: ToBytes mismatch: got %x", ctx, got)
		}
		if got := ToInteger(word); got.Cmp(wantInt) != 0 {
			t.Errorf("%s: ToInteger mismatch: got %s", ctx, got)
		}
		if got := ToIntegerString(word); got != intStr {
			t.Errorf("%s: ToIntegerString mismatch: got %s", ctx, got)
		}

		// decode direction (leading zeros preserved, strict parse)
		if back, err := FromBytes(data); err != nil {
			t.Errorf("%s: FromBytes failed: %v", ctx, err)
		} else if !wordEqual(back, word) {
			t.Errorf("%s: FromBytes produced a different word", ctx)
		}
		if back, err := FromInteger(wantInt); err != nil {
			t.Errorf("%s: FromInteger failed: %v", ctx, err)
		} else if !wordEqual(back, word) {
			t.Errorf("%s: FromInteger produced a different word", ctx)
		}
		if back, err := FromIntegerString(intStr); err != nil {
			t.Errorf("%s: FromIntegerString failed: %v", ctx, err)
		} else if !wordEqual(back, word) {
			t.Errorf("%s: FromIntegerString produced a different word", ctx)
		}

		// the vector's coordinate is already canonical: wire JSON matches
		wantJSON := canonicalJSON(t, row["coordinate"])
		gotJSON, err := ToWireJSON(word)
		if err != nil {
			t.Errorf("%s: ToWireJSON failed: %v", ctx, err)
		} else if string(gotJSON) != wantJSON {
			t.Errorf("%s: wire JSON mismatch:\n got  %s\n want %s", ctx, gotJSON, wantJSON)
		}
		if back, err := FromWireJSON([]byte(wantJSON)); err != nil {
			t.Errorf("%s: FromWireJSON failed: %v", ctx, err)
		} else if !wordEqual(back, word) {
			t.Errorf("%s: FromWireJSON produced a different word", ctx)
		}
	}
}

// ---------------------------------------------------------------------------
// invalid_inputs.jsonl — inputs that MUST be rejected, by exact code.
// ---------------------------------------------------------------------------

func TestInvalidInputs(t *testing.T) {
	for _, row := range loadJSONL(t, "invalid_inputs.jsonl") {
		kind := mustString(t, row, "kind")
		wantCode := mustString(t, row, "error")
		ctx := kind + "/" + wantCode

		switch kind {
		case "integer_string":
			_, err := FromIntegerString(mustString(t, row, "value"))
			assertCode(t, err, wantCode, ctx)
		case "bytes":
			data := mustHex(t, mustString(t, row, "value"))
			_, err := FromBytes(data)
			assertCode(t, err, wantCode, ctx)
		case "coordinate":
			arr, ok := row["value"].([]interface{})
			if !ok {
				t.Fatalf("%s: coordinate vector value is not an array", ctx)
			}
			_, err := FromWire(arr)
			assertCode(t, err, wantCode, ctx+" (structural)")
			_, err = FromWireJSON([]byte(canonicalJSON(t, row["value"])))
			assertCode(t, err, wantCode, ctx+" (JSON text)")
		default:
			t.Fatalf("unknown vector kind %q", kind)
		}
	}
}

// ---------------------------------------------------------------------------
// latin_to_coordinate.jsonl — romanization profile core-v1.
// ---------------------------------------------------------------------------

func TestLatinToCoordinate(t *testing.T) {
	for _, row := range loadJSONL(t, "latin_to_coordinate.jsonl") {
		latin := mustString(t, row, "latin")
		ctx := "latin " + latin

		if wantCode, isErr := row["error"].(string); isErr {
			_, err := FromLatin(latin)
			assertCode(t, err, wantCode, ctx)
			continue
		}

		canonical := mustString(t, row, "canonical")
		coordArr, ok := row["coordinate"].([]interface{})
		if !ok {
			t.Fatalf("%s: coordinate vector value is not an array", ctx)
		}
		wantJSON := canonicalJSON(t, row["coordinate"])

		// from_latin(latin) == coordinate (compared as canonical wire JSON)
		word, err := FromLatin(latin)
		if err != nil {
			t.Errorf("%s: FromLatin failed: %v", ctx, err)
			continue
		}
		gotJSON, err := ToWireJSON(word)
		if err != nil {
			t.Errorf("%s: ToWireJSON failed: %v", ctx, err)
		} else if string(gotJSON) != wantJSON {
			t.Errorf("%s: coordinate mismatch:\n got  %s\n want %s", ctx, gotJSON, wantJSON)
		}

		// to_latin(coordinate) == canonical
		vecWord, err := FromWire(coordArr)
		if err != nil {
			t.Fatalf("%s: FromWire of vector coordinate failed: %v", ctx, err)
		}
		if spelled, err := ToLatin(vecWord); err != nil {
			t.Errorf("%s: ToLatin failed: %v", ctx, err)
		} else if spelled != canonical {
			t.Errorf("%s: ToLatin mismatch: got %q want %q", ctx, spelled, canonical)
		}

		// to_latin(from_latin(latin)) == canonical
		if spelled, err := ToLatin(word); err != nil {
			t.Errorf("%s: ToLatin(FromLatin) failed: %v", ctx, err)
		} else if spelled != canonical {
			t.Errorf("%s: ToLatin(FromLatin) mismatch: got %q want %q", ctx, spelled, canonical)
		}
	}
}
