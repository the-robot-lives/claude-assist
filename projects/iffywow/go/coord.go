package ithkuil

// Canonical coordinate tuple (CODEC.md §2, schema v1) as native Go values.
//
// Canonical-form invariants (checked by Validate, repaired where legal by
// Canonicalize):
//
//   - Version >= 1; every Orientation in 0..MaxOrientation; every socket ID
//     in 0..MaxSocketID.
//   - Socket lists sorted strictly ascending by ID (duplicates are invalid
//     and are never repaired).
//   - Empty sockets are omitted: a Socket always carries a Modifier. The
//     wire form [id, null] exists only at JSON boundaries (see wire.go) and
//     is dropped during canonicalization — one meaning, one representation.

import (
	"fmt"
	"sort"
)

// Schema v1 bounds (CODEC.md §2).
const (
	MaxOrientation = 3
	MaxSocketID    = 7
)

// Word is a canonical ithkuil word: a schema version plus a glyph sequence.
type Word struct {
	Version int
	Glyphs  []Glyph
}

// Glyph is one glyph of a word.
type Glyph struct {
	CharacterClass uint64
	Base           uint64
	Orientation    int
	Sockets        []Socket
}

// Socket attaches a Modifier at a socket position. Empty sockets are omitted
// from the canonical form, so a Socket always holds a Modifier.
type Socket struct {
	ID       int
	Modifier Modifier
}

// Modifier decorates a socket with a shape, orientation, diacritics, and
// (recursively) child sockets.
type Modifier struct {
	Shape       uint64
	Orientation int
	Diacritics  []uint64
	Sockets     []Socket
}

// Validate checks that w is a canonical schema-v1 Word: version >= 1,
// orientations in range, socket IDs in range, and every socket list sorted
// strictly ascending by ID. It is strict — unsorted sockets are an error
// here; use Canonicalize for the lenient (sorting) form.
func Validate(w Word) error {
	if w.Version < 1 {
		return errf(ErrInvalidVersion, "schema version must be a positive integer, got %d", w.Version)
	}
	for i, g := range w.Glyphs {
		if err := validateGlyph(g, fmt.Sprintf("glyph %d", i)); err != nil {
			return err
		}
	}
	return nil
}

func validateGlyph(g Glyph, where string) error {
	if g.Orientation < 0 || g.Orientation > MaxOrientation {
		return errf(ErrInvalidOrientation, "%s: orientation must be 0..%d, got %d",
			where, MaxOrientation, g.Orientation)
	}
	return validateSockets(g.Sockets, where)
}

func validateSockets(ss []Socket, where string) error {
	prev := -1
	for _, s := range ss {
		if s.ID < 0 || s.ID > MaxSocketID {
			return errf(ErrInvalidSocketID, "%s: socket id must be 0..%d in schema v1, got %d",
				where, MaxSocketID, s.ID)
		}
		if s.ID == prev {
			return errf(ErrDuplicateSocket, "%s: duplicate socket %d", where, s.ID)
		}
		if s.ID < prev {
			return errf(ErrUnsortedSockets,
				"%s: sockets must be sorted strictly ascending (socket %d after %d)",
				where, s.ID, prev)
		}
		prev = s.ID
		if err := validateModifier(s.Modifier, fmt.Sprintf("%s socket %d", where, s.ID)); err != nil {
			return err
		}
	}
	return nil
}

func validateModifier(m Modifier, where string) error {
	if m.Orientation < 0 || m.Orientation > MaxOrientation {
		return errf(ErrInvalidOrientation, "%s: modifier orientation must be 0..%d, got %d",
			where, MaxOrientation, m.Orientation)
	}
	return validateSockets(m.Sockets, where)
}

// Canonicalize returns a canonical deep copy of w: every socket list is
// sorted ascending by ID (at every nesting level) and the result is
// validated. Duplicate socket IDs are an error (ErrDuplicateSocket), never
// repaired. The returned Word shares no slices with the input, so callers
// may freely mutate either afterwards.
func Canonicalize(w Word) (Word, error) {
	out := Word{Version: w.Version, Glyphs: canonGlyphs(w.Glyphs)}
	if err := Validate(out); err != nil {
		return Word{}, err
	}
	return out, nil
}

func canonGlyphs(gs []Glyph) []Glyph {
	if len(gs) == 0 {
		return nil
	}
	out := make([]Glyph, len(gs))
	for i, g := range gs {
		out[i] = Glyph{
			CharacterClass: g.CharacterClass,
			Base:           g.Base,
			Orientation:    g.Orientation,
			Sockets:        canonSockets(g.Sockets),
		}
	}
	return out
}

func canonSockets(ss []Socket) []Socket {
	if len(ss) == 0 {
		return nil
	}
	out := make([]Socket, len(ss))
	for i, s := range ss {
		out[i] = Socket{ID: s.ID, Modifier: canonModifier(s.Modifier)}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].ID < out[j].ID })
	return out
}

func canonModifier(m Modifier) Modifier {
	var dia []uint64
	if len(m.Diacritics) > 0 {
		dia = make([]uint64, len(m.Diacritics))
		copy(dia, m.Diacritics)
	}
	return Modifier{
		Shape:       m.Shape,
		Orientation: m.Orientation,
		Diacritics:  dia,
		Sockets:     canonSockets(m.Sockets),
	}
}
