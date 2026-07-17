package ithkuil

// codec-v1: term algebra ser/de + integer ranking. Normative: ../CODEC.md.
//
// Term algebra (tag byte, then payload):
//
//	0x00  NAT n     minimal unsigned LEB128 varint of n
//	0x01  PAIR x y  ser(x) ser(y)
//	0x02  LIST      varint k, then k serialized elements
//	0x03  BYTES     varint len, then the raw bytes
//	0x04  reserved  never emitted in v1; decoders MUST reject
//
// Integer ranking: with B = ser(word) of byte length m,
//
//	S_m  = (256^m − 1) / 255      (number of byte strings shorter than m)
//	E(t) = S_m + V256(B)          (V256 = big-endian base-256 value)
//
// Length intervals are disjoint, so decoding recovers m first (largest m
// with S_m <= E), then B = E − S_m as exactly m bytes PRESERVING LEADING
// ZEROS, then parses the term strictly.

import "math/big"

const (
	tagNat      = 0x00
	tagPair     = 0x01
	tagList     = 0x02
	tagBytes    = 0x03
	tagReserved = 0x04
)

// term is the internal codec-v1 term-algebra value (CODEC.md §1). Exactly
// one of the payload fields is meaningful, selected by tag.
type term struct {
	tag   byte
	nat   *big.Int // tag == tagNat
	fst   *term    // tag == tagPair
	snd   *term    // tag == tagPair
	items []*term  // tag == tagList
	data  []byte   // tag == tagBytes
}

var (
	bigOne     = big.NewInt(1)
	big255     = big.NewInt(255)
	big256     = big.NewInt(256)
	varintMask = big.NewInt(0x7f)
)

// ---------------------------------------------------------------------------
// Unsigned LEB128 varints (minimal encodings only).
// ---------------------------------------------------------------------------

// appendVarint appends the minimal unsigned LEB128 encoding of n:
// little-endian 7-bit groups, high bit = continue.
// 0 -> 00, 127 -> 7f, 128 -> 80 01, 300 -> ac 02.
func appendVarint(dst []byte, n *big.Int) []byte {
	if n.Sign() < 0 {
		// Canonical Words never carry negative values; failing loudly beats
		// the infinite loop an arithmetic right shift of -1 would produce.
		panic("ithkuil: negative varint value")
	}
	v := new(big.Int).Set(n)
	low := new(big.Int)
	for {
		group := byte(low.And(v, varintMask).Uint64())
		v.Rsh(v, 7)
		if v.Sign() != 0 {
			dst = append(dst, group|0x80)
		} else {
			return append(dst, group)
		}
	}
}

// readVarint decodes a varint at data[pos:], returning the value and the
// offset just past it. Non-minimal encodings are rejected: a multi-byte
// varint whose final (most significant) group is zero has a shorter
// equivalent, e.g. 80 00 for 0 (CODEC.md §1).
func readVarint(data []byte, pos int) (*big.Int, int, error) {
	result := new(big.Int)
	chunk := new(big.Int)
	shift := uint(0)
	start := pos
	for {
		if pos >= len(data) {
			return nil, 0, errf(ErrTruncated, "unexpected end of input inside varint at offset %d", start)
		}
		b := data[pos]
		pos++
		chunk.SetUint64(uint64(b & 0x7f))
		chunk.Lsh(chunk, shift)
		result.Or(result, chunk)
		if b&0x80 == 0 {
			if b == 0 && pos-start > 1 {
				return nil, 0, errf(ErrNonminimalVarint,
					"non-minimal varint at offset %d: redundant zero continuation group", start)
			}
			return result, pos, nil
		}
		shift += 7
	}
}

// ---------------------------------------------------------------------------
// Term serialization / strict deserialization.
// ---------------------------------------------------------------------------

func appendTerm(dst []byte, t *term) []byte {
	switch t.tag {
	case tagNat:
		dst = append(dst, tagNat)
		return appendVarint(dst, t.nat)
	case tagPair:
		dst = append(dst, tagPair)
		dst = appendTerm(dst, t.fst)
		return appendTerm(dst, t.snd)
	case tagList:
		dst = append(dst, tagList)
		dst = appendVarint(dst, big.NewInt(int64(len(t.items))))
		for _, e := range t.items {
			dst = appendTerm(dst, e)
		}
		return dst
	case tagBytes:
		dst = append(dst, tagBytes)
		dst = appendVarint(dst, big.NewInt(int64(len(t.data))))
		return append(dst, t.data...)
	default:
		// terms are only built inside this package; an unknown tag is a bug.
		panic("ithkuil: malformed internal term")
	}
}

// deserializeTerm strictly decodes a root term: canonical varints, no
// reserved/unknown tags, and no trailing bytes after the root term.
func deserializeTerm(data []byte) (*term, error) {
	t, pos, err := readTerm(data, 0)
	if err != nil {
		return nil, err
	}
	if pos != len(data) {
		return nil, errf(ErrTrailingBytes, "%d trailing byte(s) after the root term at offset %d",
			len(data)-pos, pos)
	}
	return t, nil
}

func readTerm(data []byte, pos int) (*term, int, error) {
	if pos >= len(data) {
		return nil, 0, errf(ErrTruncated, "unexpected end of input: expected tag byte at offset %d", pos)
	}
	tag := data[pos]
	pos++
	switch tag {
	case tagNat:
		n, next, err := readVarint(data, pos)
		if err != nil {
			return nil, 0, err
		}
		return &term{tag: tagNat, nat: n}, next, nil
	case tagPair:
		fst, afterFst, err := readTerm(data, pos)
		if err != nil {
			return nil, 0, err
		}
		snd, afterSnd, err := readTerm(data, afterFst)
		if err != nil {
			return nil, 0, err
		}
		return &term{tag: tagPair, fst: fst, snd: snd}, afterSnd, nil
	case tagList:
		count, next, err := readVarint(data, pos)
		if err != nil {
			return nil, 0, err
		}
		// Every element occupies at least one byte, so a count beyond the
		// remaining input is necessarily truncated (this also bounds the
		// allocation below by the input size).
		if !count.IsInt64() || count.Int64() > int64(len(data)-next) {
			return nil, 0, errf(ErrTruncated, "list of %s element(s) exceeds remaining input at offset %d",
				count.String(), next)
		}
		k := int(count.Int64())
		items := make([]*term, 0, k)
		for i := 0; i < k; i++ {
			var e *term
			e, next, err = readTerm(data, next)
			if err != nil {
				return nil, 0, err
			}
			items = append(items, e)
		}
		return &term{tag: tagList, items: items}, next, nil
	case tagBytes:
		length, next, err := readVarint(data, pos)
		if err != nil {
			return nil, 0, err
		}
		if !length.IsInt64() || length.Int64() > int64(len(data)-next) {
			return nil, 0, errf(ErrTruncated, "bytes payload of length %s truncated at offset %d",
				length.String(), next)
		}
		n := int(length.Int64())
		payload := make([]byte, n)
		copy(payload, data[next:next+n])
		return &term{tag: tagBytes, data: payload}, next + n, nil
	case tagReserved:
		return nil, 0, errf(ErrReservedTag, "reserved tag 0x04 at offset %d", pos-1)
	default:
		return nil, 0, errf(ErrUnknownTag, "unknown tag 0x%02x at offset %d", tag, pos-1)
	}
}

// ---------------------------------------------------------------------------
// Word <-> term mapping (schema v1, CODEC.md §2).
// ---------------------------------------------------------------------------

func natTermInt64(v int64) *term { return &term{tag: tagNat, nat: big.NewInt(v)} }

func natTermUint64(u uint64) *term {
	return &term{tag: tagNat, nat: new(big.Int).SetUint64(u)}
}

func wordToTerm(w Word) *term {
	glyphs := make([]*term, len(w.Glyphs))
	for i, g := range w.Glyphs {
		glyphs[i] = glyphToTerm(g)
	}
	return &term{
		tag: tagPair,
		fst: natTermInt64(int64(w.Version)),
		snd: &term{tag: tagList, items: glyphs},
	}
}

func glyphToTerm(g Glyph) *term {
	return &term{tag: tagList, items: []*term{
		natTermUint64(g.CharacterClass),
		natTermUint64(g.Base),
		natTermInt64(int64(g.Orientation)),
		socketsToTerm(g.Sockets),
	}}
}

func socketsToTerm(ss []Socket) *term {
	items := make([]*term, len(ss))
	for i, s := range ss {
		items[i] = &term{
			tag: tagPair,
			fst: natTermInt64(int64(s.ID)),
			snd: modifierToTerm(s.Modifier),
		}
	}
	return &term{tag: tagList, items: items}
}

func modifierToTerm(m Modifier) *term {
	dia := make([]*term, len(m.Diacritics))
	for i, d := range m.Diacritics {
		dia[i] = natTermUint64(d)
	}
	return &term{tag: tagList, items: []*term{
		natTermUint64(m.Shape),
		natTermInt64(int64(m.Orientation)),
		{tag: tagList, items: dia},
		socketsToTerm(m.Sockets),
	}}
}

func termToWord(t *term) (Word, error) {
	if t.tag != tagPair {
		return Word{}, errf(ErrInvalidStructure, "word term must be PAIR(NAT version, LIST glyphs)")
	}
	if t.fst.tag != tagNat {
		return Word{}, errf(ErrInvalidStructure, "word version must be a NAT term")
	}
	if t.snd.tag != tagList {
		return Word{}, errf(ErrInvalidStructure, "word glyph list must be a LIST term")
	}
	if !t.fst.nat.IsInt64() {
		return Word{}, errf(ErrInvalidStructure,
			"word version %s exceeds this implementation's range", t.fst.nat.String())
	}
	v64 := t.fst.nat.Int64()
	version := int(v64)
	if int64(version) != v64 { // int overflow on 32-bit platforms
		return Word{}, errf(ErrInvalidStructure,
			"word version %d exceeds this implementation's int range", v64)
	}
	var glyphs []Glyph
	if len(t.snd.items) > 0 {
		glyphs = make([]Glyph, len(t.snd.items))
		for i, gt := range t.snd.items {
			g, err := termToGlyph(gt)
			if err != nil {
				return Word{}, err
			}
			glyphs[i] = g
		}
	}
	return Word{Version: version, Glyphs: glyphs}, nil
}

func natUint64(t *term, what string) (uint64, error) {
	if t.tag != tagNat {
		return 0, errf(ErrInvalidStructure, "%s must be a NAT term", what)
	}
	if !t.nat.IsUint64() {
		return 0, errf(ErrInvalidStructure,
			"%s value %s exceeds this implementation's range (uint64)", what, t.nat.String())
	}
	return t.nat.Uint64(), nil
}

func natOrientation(t *term, what string) (int, error) {
	if t.tag != tagNat {
		return 0, errf(ErrInvalidStructure, "%s must be a NAT term", what)
	}
	if !t.nat.IsUint64() || t.nat.Uint64() > MaxOrientation {
		return 0, errf(ErrInvalidOrientation, "%s must be 0..%d, got %s",
			what, MaxOrientation, t.nat.String())
	}
	return int(t.nat.Uint64()), nil
}

func natSocketID(t *term) (int, error) {
	if t.tag != tagNat {
		return 0, errf(ErrInvalidStructure, "socket id must be a NAT term")
	}
	if !t.nat.IsUint64() || t.nat.Uint64() > MaxSocketID {
		return 0, errf(ErrInvalidSocketID, "socket id must be 0..%d in schema v1, got %s",
			MaxSocketID, t.nat.String())
	}
	return int(t.nat.Uint64()), nil
}

func termToGlyph(t *term) (Glyph, error) {
	if t.tag != tagList || len(t.items) != 4 {
		return Glyph{}, errf(ErrInvalidStructure, "glyph must be LIST[class, base, orientation, sockets]")
	}
	cc, err := natUint64(t.items[0], "glyph character class")
	if err != nil {
		return Glyph{}, err
	}
	base, err := natUint64(t.items[1], "glyph base")
	if err != nil {
		return Glyph{}, err
	}
	orientation, err := natOrientation(t.items[2], "glyph orientation")
	if err != nil {
		return Glyph{}, err
	}
	sockets, err := termToSockets(t.items[3])
	if err != nil {
		return Glyph{}, err
	}
	return Glyph{CharacterClass: cc, Base: base, Orientation: orientation, Sockets: sockets}, nil
}

func termToSockets(t *term) ([]Socket, error) {
	if t.tag != tagList {
		return nil, errf(ErrInvalidStructure, "socket list must be a LIST term")
	}
	if len(t.items) == 0 {
		return nil, nil
	}
	out := make([]Socket, 0, len(t.items))
	for _, e := range t.items {
		if e.tag != tagPair {
			return nil, errf(ErrInvalidStructure, "socket must be PAIR(NAT id, modifier)")
		}
		id, err := natSocketID(e.fst)
		if err != nil {
			return nil, err
		}
		mod, err := termToModifier(e.snd)
		if err != nil {
			return nil, err
		}
		out = append(out, Socket{ID: id, Modifier: mod})
	}
	return out, nil
}

func termToModifier(t *term) (Modifier, error) {
	if t.tag != tagList || len(t.items) != 4 {
		return Modifier{}, errf(ErrInvalidStructure,
			"modifier must be LIST[shape, orientation, diacritics, sockets]")
	}
	shape, err := natUint64(t.items[0], "modifier shape")
	if err != nil {
		return Modifier{}, err
	}
	orientation, err := natOrientation(t.items[1], "modifier orientation")
	if err != nil {
		return Modifier{}, err
	}
	if t.items[2].tag != tagList {
		return Modifier{}, errf(ErrInvalidStructure, "diacritic list must be a LIST term")
	}
	var dia []uint64
	if len(t.items[2].items) > 0 {
		dia = make([]uint64, len(t.items[2].items))
		for i, d := range t.items[2].items {
			v, err := natUint64(d, "diacritic id")
			if err != nil {
				return Modifier{}, err
			}
			dia[i] = v
		}
	}
	sockets, err := termToSockets(t.items[3])
	if err != nil {
		return Modifier{}, err
	}
	return Modifier{Shape: shape, Orientation: orientation, Diacritics: dia, Sockets: sockets}, nil
}

// ---------------------------------------------------------------------------
// Byte-string ranking among all finite byte strings (CODEC.md §3).
// ---------------------------------------------------------------------------

// stringsShorterThan returns S_m = (256^m − 1) / 255, the number of byte
// strings with length < m. The division is exact.
func stringsShorterThan(m int) *big.Int {
	s := new(big.Int).Exp(big256, big.NewInt(int64(m)), nil)
	s.Sub(s, bigOne)
	return s.Div(s, big255)
}

// rank returns E = S_m + V256(B) for B = data of length m.
func rank(data []byte) *big.Int {
	e := stringsShorterThan(len(data))
	return e.Add(e, new(big.Int).SetBytes(data))
}

// unrank inverts rank: it recovers the exact byte string, leading zeros
// included. Every non-negative integer maps to some byte string. e must be
// non-negative.
func unrank(e *big.Int) []byte {
	// Largest m with S_m <= e, using S_{m+1} = 256*S_m + 1.
	m := 0
	s := big.NewInt(0)
	next := big.NewInt(1)
	for next.Cmp(e) <= 0 {
		m++
		s = next
		next = new(big.Int).Add(new(big.Int).Mul(next, big256), bigOne)
	}
	diff := new(big.Int).Sub(e, s)
	// CLASSIC BUG GUARD: big.Int.Bytes() drops leading zeros, but B must be
	// exactly m bytes — e.g. the empty word's B is 01 00 01 02 00 and would
	// come back as 4 bytes without the pad. FillBytes writes the big-endian
	// value LEFT-PADDED with zeros into an m-byte buffer (diff < 256^m by
	// construction, so it always fits).
	buf := make([]byte, m)
	diff.FillBytes(buf)
	return buf
}

// ---------------------------------------------------------------------------
// Public word-level API.
// ---------------------------------------------------------------------------

// ToBytes returns the canonical codec-v1 serialization ser(w). It is total
// on valid canonical Words (see Validate/Canonicalize); the output for an
// invalid Word is unspecified and will fail strict decoding.
func ToBytes(w Word) []byte {
	return appendTerm(nil, wordToTerm(w))
}

// FromBytes strictly decodes a canonical serialization: minimal varints, no
// reserved/unknown tags, no trailing bytes, canonical word structure with
// sorted sockets. Only ser(w) of a valid Word succeeds.
func FromBytes(data []byte) (Word, error) {
	t, err := deserializeTerm(data)
	if err != nil {
		return Word{}, err
	}
	w, err := termToWord(t)
	if err != nil {
		return Word{}, err
	}
	if err := Validate(w); err != nil {
		return Word{}, err
	}
	return w, nil
}

// ToInteger returns E(w) per CODEC.md §3. Total on valid canonical Words.
func ToInteger(w Word) *big.Int {
	return rank(ToBytes(w))
}

// FromInteger strictly decodes an integer back to a Word. Every natural
// number denotes some byte string, but only canonical serializations of
// valid words decode successfully.
func FromInteger(n *big.Int) (Word, error) {
	if n == nil || n.Sign() < 0 {
		return Word{}, errf(ErrInvalidNaturalNumber, "expected a non-negative integer, got %v", n)
	}
	return FromBytes(unrank(n))
}

// ToIntegerString returns the unsigned decimal form of ToInteger(w) — the
// only sanctioned cross-boundary integer representation (CODEC.md §3).
func ToIntegerString(w Word) string {
	return ToInteger(w).String()
}

// FromIntegerString parses an unsigned decimal string. Sign characters,
// empty strings, and any non-digit are rejected with
// ErrInvalidNaturalNumber.
func FromIntegerString(s string) (Word, error) {
	// Manual digit-only validation FIRST: big.Int.SetString would happily
	// accept a leading '+' or '-' in base 10 (and underscore separators in
	// base 0), none of which are legal in the IntegerString boundary form.
	if len(s) == 0 {
		return Word{}, errf(ErrInvalidNaturalNumber, "expected unsigned decimal string, got empty string")
	}
	for i := 0; i < len(s); i++ {
		if s[i] < '0' || s[i] > '9' {
			return Word{}, errf(ErrInvalidNaturalNumber, "expected unsigned decimal string, got %q", s)
		}
	}
	n, ok := new(big.Int).SetString(s, 10)
	if !ok {
		// Unreachable after the digit check; kept as a safety net.
		return Word{}, errf(ErrInvalidNaturalNumber, "expected unsigned decimal string, got %q", s)
	}
	return FromInteger(n)
}
