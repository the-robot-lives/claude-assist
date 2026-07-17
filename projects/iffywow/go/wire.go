package ithkuil

// Wire form: JSON tagged arrays (CODEC.md §2), structural and text.
//
//	["ithkuil-word", version, [glyph, ...]]
//	["glyph", character_class, base, orientation, [socket, ...]]
//	[socket_id, null | modifier]
//	["modifier", shape, orientation, [diacritic_id, ...], [socket, ...]]
//
// Strictness boundary (SDK-INTERFACE.md §2): wire input is LENIENT but
// canonicalizing — unsorted sockets are sorted, [id, null] empties are
// dropped; duplicate socket IDs are always an error, never repaired.

import (
	"encoding/json"
	"fmt"
	"sort"
)

const (
	wordTag     = "ithkuil-word"
	glyphTag    = "glyph"
	modifierTag = "modifier"
)

// maxWireNumber is the largest integer accepted from JSON: 2^53 − 1.
// encoding/json decodes every JSON number into a float64, which represents
// integers exactly only up to 2^53 − 1; anything larger may already have
// silently lost precision inside the float before this package ever sees
// it, so such values are rejected as invalid_structure. Schema-v1 ids never
// approach this bound, so it is not a practical limitation.
const maxWireNumber = 1<<53 - 1

// ---------------------------------------------------------------------------
// Word -> wire.
// ---------------------------------------------------------------------------

// ToWire projects a canonical Word to its structural wire form (tagged
// []interface{} arrays). json.Marshal of the result is the canonical wire
// JSON. Total on valid canonical Words; call Canonicalize first for
// arbitrary native input (ToWireJSON does so automatically).
func ToWire(w Word) []interface{} {
	glyphs := make([]interface{}, len(w.Glyphs))
	for i, g := range w.Glyphs {
		glyphs[i] = glyphToWire(g)
	}
	return []interface{}{wordTag, w.Version, glyphs}
}

func glyphToWire(g Glyph) []interface{} {
	return []interface{}{glyphTag, g.CharacterClass, g.Base, g.Orientation, socketsToWire(g.Sockets)}
}

func socketsToWire(ss []Socket) []interface{} {
	out := make([]interface{}, len(ss))
	for i, s := range ss {
		out[i] = []interface{}{s.ID, modifierToWire(s.Modifier)}
	}
	return out
}

func modifierToWire(m Modifier) []interface{} {
	dia := make([]interface{}, len(m.Diacritics))
	for i, d := range m.Diacritics {
		dia[i] = d
	}
	return []interface{}{modifierTag, m.Shape, m.Orientation, dia, socketsToWire(m.Sockets)}
}

// ToWireJSON canonicalizes w (language-native input is lenient per
// SDK-INTERFACE.md §2) and returns the canonical wire JSON text.
func ToWireJSON(w Word) ([]byte, error) {
	c, err := Canonicalize(w)
	if err != nil {
		return nil, err
	}
	out, err := json.Marshal(ToWire(c))
	if err != nil {
		// Unreachable for the plain slices/ints/strings ToWire emits.
		return nil, errf(ErrInvalidStructure, "cannot marshal wire form: %v", err)
	}
	return out, nil
}

// ---------------------------------------------------------------------------
// Wire -> Word (lenient-canonicalizing).
// ---------------------------------------------------------------------------

// FromWire parses a structural wire coordinate into a canonical Word:
// sockets are sorted ascending, [id, null] empties are dropped, duplicate
// socket IDs are rejected.
func FromWire(value []interface{}) (Word, error) {
	return parseWireWord(value)
}

// FromWireJSON parses wire JSON text into a canonical Word (lenient, like
// FromWire). Malformed JSON is reported as invalid_structure.
func FromWireJSON(data []byte) (Word, error) {
	var v interface{}
	if err := json.Unmarshal(data, &v); err != nil {
		return Word{}, errf(ErrInvalidStructure, "invalid coordinate: not JSON (%v)", err)
	}
	arr, ok := v.([]interface{})
	if !ok {
		return Word{}, errf(ErrInvalidStructure,
			`invalid coordinate at $: expected ["%s", version, glyphs]`, wordTag)
	}
	return parseWireWord(arr)
}

// wireNat extracts a non-negative integer from a decoded wire value.
// encoding/json yields float64 for every JSON number; a float64 represents
// integers exactly only up to 2^53 − 1, so integrality and that bound are
// checked explicitly (see maxWireNumber). Structural (non-JSON) wire values
// built in Go may carry native integer types as well — ToWire emits int and
// uint64 — so those are accepted too.
func wireNat(v interface{}) (uint64, bool) {
	switch n := v.(type) {
	case float64:
		if n != n { // NaN
			return 0, false
		}
		if n < 0 || n > maxWireNumber {
			return 0, false
		}
		u := uint64(n)
		if float64(u) != n { // fractional
			return 0, false
		}
		return u, true
	case int:
		if n < 0 {
			return 0, false
		}
		return uint64(n), true
	case int64:
		if n < 0 {
			return 0, false
		}
		return uint64(n), true
	case uint64:
		return n, true
	}
	return 0, false
}

func wireFail(sentinel *Error, msg, path string) error {
	return errf(sentinel, "invalid coordinate at %s: %s", path, msg)
}

func parseWireWord(value []interface{}) (Word, error) {
	if len(value) != 3 {
		return Word{}, wireFail(ErrInvalidStructure,
			fmt.Sprintf(`expected ["%s", version, glyphs]`, wordTag), "$")
	}
	if tag, ok := value[0].(string); !ok || tag != wordTag {
		return Word{}, wireFail(ErrInvalidStructure,
			fmt.Sprintf(`expected ["%s", version, glyphs]`, wordTag), "$")
	}
	ver, ok := wireNat(value[1])
	if !ok || ver < 1 {
		return Word{}, wireFail(ErrInvalidVersion, "schema version must be a positive integer", "$[1]")
	}
	version := int(ver)
	if uint64(version) != ver { // int overflow on 32-bit platforms
		return Word{}, wireFail(ErrInvalidVersion, "schema version exceeds this implementation's int range", "$[1]")
	}
	glyphArr, ok := value[2].([]interface{})
	if !ok {
		return Word{}, wireFail(ErrInvalidStructure, "glyph list must be an array", "$[2]")
	}
	var glyphs []Glyph
	if len(glyphArr) > 0 {
		glyphs = make([]Glyph, len(glyphArr))
		for i, gv := range glyphArr {
			g, err := parseWireGlyph(gv, fmt.Sprintf("$[2][%d]", i))
			if err != nil {
				return Word{}, err
			}
			glyphs[i] = g
		}
	}
	return Word{Version: version, Glyphs: glyphs}, nil
}

func parseWireGlyph(v interface{}, path string) (Glyph, error) {
	arr, ok := v.([]interface{})
	if !ok || len(arr) != 5 {
		return Glyph{}, wireFail(ErrInvalidStructure,
			fmt.Sprintf(`expected ["%s", class, base, orientation, sockets]`, glyphTag), path)
	}
	if tag, ok := arr[0].(string); !ok || tag != glyphTag {
		return Glyph{}, wireFail(ErrInvalidStructure,
			fmt.Sprintf(`expected ["%s", class, base, orientation, sockets]`, glyphTag), path)
	}
	cc, ok := wireNat(arr[1])
	if !ok {
		return Glyph{}, wireFail(ErrInvalidStructure, "expected non-negative integer", path+"[1]")
	}
	base, ok := wireNat(arr[2])
	if !ok {
		return Glyph{}, wireFail(ErrInvalidStructure, "expected non-negative integer", path+"[2]")
	}
	orientation, err := parseWireOrientation(arr[3], path+"[3]")
	if err != nil {
		return Glyph{}, err
	}
	sockets, err := parseWireSockets(arr[4], path+"[4]")
	if err != nil {
		return Glyph{}, err
	}
	return Glyph{CharacterClass: cc, Base: base, Orientation: orientation, Sockets: sockets}, nil
}

func parseWireOrientation(v interface{}, path string) (int, error) {
	n, ok := wireNat(v)
	if !ok {
		return 0, wireFail(ErrInvalidStructure, "expected non-negative integer", path)
	}
	if n > MaxOrientation {
		return 0, wireFail(ErrInvalidOrientation,
			fmt.Sprintf("orientation must be 0..%d", MaxOrientation), path)
	}
	return int(n), nil
}

// parseWireSockets is the lenient socket parser: [id, null] entries are
// accepted and dropped, ordering is repaired by sorting, duplicates are
// rejected (even when one side is null).
func parseWireSockets(v interface{}, path string) ([]Socket, error) {
	arr, ok := v.([]interface{})
	if !ok {
		return nil, wireFail(ErrInvalidStructure, "sockets must be an array", path)
	}
	type socketEntry struct {
		id  int
		mod *Modifier // nil = explicit empty, dropped after the duplicate check
	}
	seen := make(map[int]bool, len(arr))
	parsed := make([]socketEntry, 0, len(arr))
	for i, sv := range arr {
		p := fmt.Sprintf("%s[%d]", path, i)
		pair, ok := sv.([]interface{})
		if !ok || len(pair) != 2 {
			return nil, wireFail(ErrInvalidStructure, "expected [socket_id, null | modifier]", p)
		}
		idU, ok := wireNat(pair[0])
		if !ok {
			return nil, wireFail(ErrInvalidStructure, "expected non-negative integer", p+"[0]")
		}
		if idU > MaxSocketID {
			return nil, wireFail(ErrInvalidSocketID,
				fmt.Sprintf("socket id must be 0..%d in schema v1", MaxSocketID), p+"[0]")
		}
		id := int(idU)
		if seen[id] {
			return nil, wireFail(ErrDuplicateSocket, fmt.Sprintf("duplicate socket %d", id), p)
		}
		seen[id] = true
		if pair[1] == nil {
			parsed = append(parsed, socketEntry{id: id})
			continue
		}
		mod, err := parseWireModifier(pair[1], p+"[1]")
		if err != nil {
			return nil, err
		}
		parsed = append(parsed, socketEntry{id: id, mod: &mod})
	}
	sort.Slice(parsed, func(i, j int) bool { return parsed[i].id < parsed[j].id }) // canonical order
	var out []Socket
	for _, e := range parsed {
		if e.mod != nil { // empties omitted from the canonical form
			out = append(out, Socket{ID: e.id, Modifier: *e.mod})
		}
	}
	return out, nil
}

func parseWireModifier(v interface{}, path string) (Modifier, error) {
	arr, ok := v.([]interface{})
	if !ok || len(arr) != 5 {
		return Modifier{}, wireFail(ErrInvalidStructure,
			fmt.Sprintf(`expected ["%s", shape, orientation, diacritics, sockets]`, modifierTag), path)
	}
	if tag, ok := arr[0].(string); !ok || tag != modifierTag {
		return Modifier{}, wireFail(ErrInvalidStructure,
			fmt.Sprintf(`expected ["%s", shape, orientation, diacritics, sockets]`, modifierTag), path)
	}
	shape, ok := wireNat(arr[1])
	if !ok {
		return Modifier{}, wireFail(ErrInvalidStructure, "expected non-negative integer", path+"[1]")
	}
	orientation, err := parseWireOrientation(arr[2], path+"[2]")
	if err != nil {
		return Modifier{}, err
	}
	diaArr, ok := arr[3].([]interface{})
	if !ok {
		return Modifier{}, wireFail(ErrInvalidStructure, "diacritics must be an array", path+"[3]")
	}
	var dia []uint64
	if len(diaArr) > 0 {
		dia = make([]uint64, len(diaArr))
		for i, dv := range diaArr {
			d, ok := wireNat(dv)
			if !ok {
				return Modifier{}, wireFail(ErrInvalidStructure, "expected non-negative integer",
					fmt.Sprintf("%s[3][%d]", path, i))
			}
			dia[i] = d
		}
	}
	sockets, err := parseWireSockets(arr[4], path+"[4]")
	if err != nil {
		return Modifier{}, err
	}
	return Modifier{Shape: shape, Orientation: orientation, Diacritics: dia, Sockets: sockets}, nil
}
