//! codec-v1: term algebra ser/de + integer ranking. Normative: `../../CODEC.md`.
//!
//! Term algebra (tag byte, then payload):
//!
//! | tag  | term        | payload                                  |
//! |------|-------------|------------------------------------------|
//! | 0x00 | `NAT n`     | minimal unsigned LEB128 varint of `n`    |
//! | 0x01 | `PAIR x y`  | `ser(x) ser(y)`                          |
//! | 0x02 | `LIST`      | varint `k`, then `k` serialized elements |
//! | 0x03 | `BYTES`     | varint `len`, then the raw bytes         |
//! | 0x04 | reserved    | never emitted in v1; decoders reject     |
//!
//! Integer ranking: with `B = ser(word)` of byte length `m`,
//! `S_m = (256^m - 1)/255` and `E(t) = S_m + V256(B)` where `V256` reads `B`
//! as a big-endian base-256 integer. Length intervals are disjoint, so
//! decoding recovers `m` first, then `B = E - S_m` as exactly `m` bytes
//! **preserving leading zeros**, then parses the term strictly.
//!
//! The term layer is arbitrary-precision ([`num_bigint::BigUint`] NATs). The
//! word layer stores open enum ids as `u64` (and `version` as `u32`); a
//! serialized NAT that exceeds the field's representable range is rejected
//! with `invalid_structure` rather than silently truncated (bounded fields —
//! orientation, socket id — get their semantic codes instead, and version 0
//! gets `invalid_version`).
//!
//! Note: term decoding is recursive over nesting depth; adversarially deep
//! inputs (bounded by input length) can exhaust the stack. Conformance and
//! real-world inputs are shallow.

use num_bigint::BigUint;
use num_traits::{ToPrimitive, Zero};

use crate::coord::{self, Glyph, Modifier, Socket, Word, MAX_ORIENTATION, MAX_SOCKET_ID};
use crate::error::{Error, Result};

pub const TAG_NAT: u8 = 0x00;
pub const TAG_PAIR: u8 = 0x01;
pub const TAG_LIST: u8 = 0x02;
pub const TAG_BYTES: u8 = 0x03;
pub const TAG_RESERVED: u8 = 0x04;

/// A codec-v1 term.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Term {
    Nat(BigUint),
    Pair(Box<Term>, Box<Term>),
    List(Vec<Term>),
    Bytes(Vec<u8>),
}

// ---------------------------------------------------------------------------
// Unsigned LEB128 varints (minimal encodings only).
// ---------------------------------------------------------------------------

/// Minimal unsigned LEB128: little-endian 7-bit groups, high bit = continue.
/// `0 -> 00`, `127 -> 7f`, `128 -> 80 01`, `300 -> ac 02`.
pub fn encode_varint(value: &BigUint) -> Vec<u8> {
    let mut out = Vec::new();
    let mut n = value.clone();
    let mask = BigUint::from(0x7fu8);
    loop {
        let group = (&n & &mask).to_u8().expect("masked to 7 bits");
        n >>= 7usize;
        if n.is_zero() {
            out.push(group);
            return out;
        }
        out.push(group | 0x80);
    }
}

/// Decode a varint at `*pos`, advancing `*pos`. Rejects non-minimal
/// encodings: a multi-byte varint whose final (most significant) group is
/// zero has a shorter equivalent, e.g. `80 00` for 0.
fn read_varint(data: &[u8], pos: &mut usize) -> Result<BigUint> {
    let start = *pos;
    let mut result = BigUint::zero();
    let mut shift: usize = 0;
    loop {
        if *pos >= data.len() {
            return Err(Error::Truncated(format!(
                "unexpected end of input inside varint at offset {start}"
            )));
        }
        let byte = data[*pos];
        *pos += 1;
        let group = byte & 0x7f;
        if group != 0 {
            // Groups occupy disjoint bit ranges, so OR assembles the value.
            result |= BigUint::from(group) << shift;
        }
        if byte & 0x80 == 0 {
            if group == 0 && *pos - start > 1 {
                return Err(Error::NonminimalVarint(format!(
                    "non-minimal varint at offset {start}: redundant zero continuation group"
                )));
            }
            return Ok(result);
        }
        shift += 7;
    }
}

// ---------------------------------------------------------------------------
// Term serialization / strict deserialization.
// ---------------------------------------------------------------------------

/// Canonical serialization of a term.
pub fn serialize_term(term: &Term) -> Vec<u8> {
    let mut out = Vec::new();
    write_term(term, &mut out);
    out
}

fn write_term(term: &Term, out: &mut Vec<u8>) {
    match term {
        Term::Nat(n) => {
            out.push(TAG_NAT);
            out.extend_from_slice(&encode_varint(n));
        }
        Term::Pair(x, y) => {
            out.push(TAG_PAIR);
            write_term(x, out);
            write_term(y, out);
        }
        Term::List(items) => {
            out.push(TAG_LIST);
            out.extend_from_slice(&encode_varint(&BigUint::from(items.len())));
            for item in items {
                write_term(item, out);
            }
        }
        Term::Bytes(bytes) => {
            out.push(TAG_BYTES);
            out.extend_from_slice(&encode_varint(&BigUint::from(bytes.len())));
            out.extend_from_slice(bytes);
        }
    }
}

/// Strict decode: canonical varints, no reserved/unknown tags, and no
/// trailing bytes after the root term.
pub fn deserialize_term(data: &[u8]) -> Result<Term> {
    let mut pos = 0usize;
    let term = read_term(data, &mut pos)?;
    if pos != data.len() {
        return Err(Error::TrailingBytes(format!(
            "{} trailing byte(s) after the root term at offset {pos}",
            data.len() - pos
        )));
    }
    Ok(term)
}

fn read_term(data: &[u8], pos: &mut usize) -> Result<Term> {
    if *pos >= data.len() {
        return Err(Error::Truncated(format!(
            "unexpected end of input: expected tag byte at offset {}",
            *pos
        )));
    }
    let tag = data[*pos];
    *pos += 1;
    match tag {
        TAG_NAT => Ok(Term::Nat(read_varint(data, pos)?)),
        TAG_PAIR => {
            let x = read_term(data, pos)?;
            let y = read_term(data, pos)?;
            Ok(Term::Pair(Box::new(x), Box::new(y)))
        }
        TAG_LIST => {
            let count_big = read_varint(data, pos)?;
            // Each element consumes at least one byte, so a count that does
            // not even fit usize is certainly truncated.
            let count = count_big.to_usize().ok_or_else(|| {
                Error::Truncated("list count exceeds the input size".to_string())
            })?;
            let mut items = Vec::new();
            for _ in 0..count {
                items.push(read_term(data, pos)?);
            }
            Ok(Term::List(items))
        }
        TAG_BYTES => {
            let len_big = read_varint(data, pos)?;
            let len = len_big.to_usize().ok_or_else(|| {
                Error::Truncated("bytes length exceeds the input size".to_string())
            })?;
            if len > data.len() - *pos {
                return Err(Error::Truncated(format!(
                    "bytes payload of length {len} truncated at offset {}",
                    *pos
                )));
            }
            let bytes = data[*pos..*pos + len].to_vec();
            *pos += len;
            Ok(Term::Bytes(bytes))
        }
        TAG_RESERVED => Err(Error::ReservedTag(format!(
            "reserved tag 0x04 at offset {}",
            *pos - 1
        ))),
        _ => Err(Error::UnknownTag(format!(
            "unknown tag 0x{tag:02x} at offset {}",
            *pos - 1
        ))),
    }
}

// ---------------------------------------------------------------------------
// Word <-> term mapping (schema v1, CODEC.md §2).
// ---------------------------------------------------------------------------

/// Map a canonical word onto its term:
/// `PAIR(NAT version, LIST glyphs)` etc. Does not itself validate — see
/// [`to_bytes`] for the validating entry point.
pub fn word_to_term(word: &Word) -> Term {
    Term::Pair(
        Box::new(Term::Nat(BigUint::from(word.version))),
        Box::new(Term::List(word.glyphs.iter().map(glyph_term).collect())),
    )
}

fn glyph_term(glyph: &Glyph) -> Term {
    Term::List(vec![
        Term::Nat(BigUint::from(glyph.character_class)),
        Term::Nat(BigUint::from(glyph.base)),
        Term::Nat(BigUint::from(glyph.orientation)),
        Term::List(glyph.sockets.iter().map(socket_term).collect()),
    ])
}

fn socket_term(socket: &Socket) -> Term {
    Term::Pair(
        Box::new(Term::Nat(BigUint::from(socket.id))),
        Box::new(modifier_term(&socket.modifier)),
    )
}

fn modifier_term(modifier: &Modifier) -> Term {
    Term::List(vec![
        Term::Nat(BigUint::from(modifier.shape)),
        Term::Nat(BigUint::from(modifier.orientation)),
        Term::List(
            modifier
                .diacritics
                .iter()
                .map(|d| Term::Nat(BigUint::from(*d)))
                .collect(),
        ),
        Term::List(modifier.sockets.iter().map(socket_term).collect()),
    ])
}

fn expect_nat<'a>(term: &'a Term, what: &str) -> Result<&'a BigUint> {
    match term {
        Term::Nat(n) => Ok(n),
        _ => Err(Error::InvalidStructure(format!("{what} must be a NAT term"))),
    }
}

fn expect_list<'a>(term: &'a Term, what: &str) -> Result<&'a [Term]> {
    match term {
        Term::List(items) => Ok(items),
        _ => Err(Error::InvalidStructure(format!(
            "{what} must be a LIST term"
        ))),
    }
}

/// Open-domain field: any u64 is valid; >= 2^64 is out of this SDK's
/// representable range and rejected rather than truncated.
fn nat_u64(term: &Term, what: &str) -> Result<u64> {
    expect_nat(term, what)?.to_u64().ok_or_else(|| {
        Error::InvalidStructure(format!(
            "{what} exceeds the u64 range representable by this SDK"
        ))
    })
}

/// Bounded field: anything above the schema bound (including values that do
/// not fit u64 at all) gets the semantic code.
fn nat_orientation(term: &Term, what: &str) -> Result<u8> {
    let n = expect_nat(term, what)?;
    match n.to_u64() {
        Some(v) if v <= MAX_ORIENTATION as u64 => Ok(v as u8),
        _ => Err(Error::InvalidOrientation(format!(
            "{what} must be 0..{MAX_ORIENTATION}"
        ))),
    }
}

fn nat_socket_id(term: &Term, what: &str) -> Result<u8> {
    let n = expect_nat(term, what)?;
    match n.to_u64() {
        Some(v) if v <= MAX_SOCKET_ID as u64 => Ok(v as u8),
        _ => Err(Error::InvalidSocketId(format!(
            "{what} must be 0..{MAX_SOCKET_ID} in schema v1"
        ))),
    }
}

/// Strict term -> word. Enforces the canonical-form rules of CODEC.md §2:
/// exact tuple shapes, `version >= 1`, orientation `0..=3`, socket id
/// `0..=7`, sockets strictly ascending (duplicates -> `duplicate_socket`,
/// out of order -> `unsorted_sockets`).
pub fn term_to_word(term: &Term) -> Result<Word> {
    let (version_term, glyphs_term) = match term {
        Term::Pair(x, y) => (x.as_ref(), y.as_ref()),
        _ => {
            return Err(Error::InvalidStructure(
                "word term must be PAIR(NAT version, LIST glyphs)".to_string(),
            ))
        }
    };
    let version_big = expect_nat(version_term, "word version")?;
    if version_big.is_zero() {
        return Err(Error::InvalidVersion(
            "schema version must be a positive integer".to_string(),
        ));
    }
    let version = version_big.to_u32().ok_or_else(|| {
        Error::InvalidStructure(
            "word version exceeds the u32 range representable by this SDK".to_string(),
        )
    })?;
    let glyph_terms = expect_list(glyphs_term, "word glyph list")?;
    let mut glyphs = Vec::with_capacity(glyph_terms.len());
    for glyph_term in glyph_terms {
        glyphs.push(term_glyph(glyph_term)?);
    }
    Ok(Word { version, glyphs })
}

fn term_glyph(term: &Term) -> Result<Glyph> {
    let items = expect_list(term, "glyph")?;
    if items.len() != 4 {
        return Err(Error::InvalidStructure(
            "glyph must be LIST[class, base, orientation, sockets]".to_string(),
        ));
    }
    Ok(Glyph {
        character_class: nat_u64(&items[0], "glyph character class")?,
        base: nat_u64(&items[1], "glyph base")?,
        orientation: nat_orientation(&items[2], "glyph orientation")?,
        sockets: term_sockets(&items[3])?,
    })
}

fn term_sockets(term: &Term) -> Result<Vec<Socket>> {
    let items = expect_list(term, "socket list")?;
    let mut sockets = Vec::with_capacity(items.len());
    let mut prev: Option<u8> = None;
    for entry in items {
        let (id_term, modifier_term) = match entry {
            Term::Pair(x, y) => (x.as_ref(), y.as_ref()),
            _ => {
                return Err(Error::InvalidStructure(
                    "socket must be PAIR(NAT id, modifier)".to_string(),
                ))
            }
        };
        let id = nat_socket_id(id_term, "socket id")?;
        match prev {
            Some(p) if id == p => {
                return Err(Error::DuplicateSocket(format!("duplicate socket {id}")));
            }
            Some(p) if id < p => {
                return Err(Error::UnsortedSockets(format!(
                    "sockets must be sorted strictly ascending (socket {id} after {p})"
                )));
            }
            _ => {}
        }
        prev = Some(id);
        sockets.push(Socket {
            id,
            modifier: term_modifier(modifier_term)?,
        });
    }
    Ok(sockets)
}

fn term_modifier(term: &Term) -> Result<Modifier> {
    let items = expect_list(term, "modifier")?;
    if items.len() != 4 {
        return Err(Error::InvalidStructure(
            "modifier must be LIST[shape, orientation, diacritics, sockets]".to_string(),
        ));
    }
    let diacritic_terms = expect_list(&items[2], "diacritic list")?;
    let mut diacritics = Vec::with_capacity(diacritic_terms.len());
    for d in diacritic_terms {
        diacritics.push(nat_u64(d, "diacritic id")?);
    }
    Ok(Modifier {
        shape: nat_u64(&items[0], "modifier shape")?,
        orientation: nat_orientation(&items[1], "modifier orientation")?,
        diacritics,
        sockets: term_sockets(&items[3])?,
    })
}

// ---------------------------------------------------------------------------
// Byte-string ranking among all finite byte strings.
// ---------------------------------------------------------------------------

/// `S_m = (256^m - 1) / 255` — the number of byte strings shorter than `m`,
/// computed by the exact recurrence `S_0 = 0`, `S_{m+1} = 256 * S_m + 1`.
pub fn strings_shorter_than(m: usize) -> BigUint {
    let mut s = BigUint::zero();
    let base = BigUint::from(256u32);
    for _ in 0..m {
        s = s * &base + 1u32;
    }
    s
}

/// `E = S_m + V256(B)` for `B = data` of length `m`.
pub fn rank(data: &[u8]) -> BigUint {
    strings_shorter_than(data.len()) + BigUint::from_bytes_be(data)
}

/// Inverse of [`rank`]: recover the exact byte string, leading zeros
/// included. Total: every natural number maps to some byte string.
pub fn unrank(e: &BigUint) -> Vec<u8> {
    // Find the largest m with S_m <= e.
    let mut m = 0usize;
    let mut s = BigUint::zero();
    let base = BigUint::from(256u32);
    loop {
        let next = &s * &base + 1u32; // S_{m+1}
        if &next <= e {
            m += 1;
            s = next;
        } else {
            break;
        }
    }
    if m == 0 {
        return Vec::new();
    }
    let value = e - &s; // 0 <= value < 256^m
    let raw = value.to_bytes_be(); // note: value 0 -> [0], len 1 <= m
    let mut out = vec![0u8; m];
    let start = m - raw.len();
    out[start..].copy_from_slice(&raw);
    out
}

// ---------------------------------------------------------------------------
// Public word-level API.
// ---------------------------------------------------------------------------

/// Canonical codec-v1 serialization of a word. Validates first: a
/// non-canonical native value (unsorted sockets, orientation out of range,
/// ...) is an error, never silently repaired — canonicalize explicitly with
/// [`crate::coord::canonicalize`] if that is what you want.
pub fn to_bytes(word: &Word) -> Result<Vec<u8>> {
    coord::validate(word)?;
    Ok(serialize_term(&word_to_term(word)))
}

/// Strict decode: only canonical serializations of valid words succeed.
pub fn from_bytes(data: &[u8]) -> Result<Word> {
    term_to_word(&deserialize_term(data)?)
}

/// `E(t)` per CODEC.md §3.
pub fn to_integer(word: &Word) -> Result<BigUint> {
    Ok(rank(&to_bytes(word)?))
}

/// Strict decode of a ranked integer back to a word.
pub fn from_integer(n: &BigUint) -> Result<Word> {
    from_bytes(&unrank(n))
}

/// Unsigned decimal string — the only sanctioned cross-boundary integer form.
pub fn to_integer_string(word: &Word) -> Result<String> {
    Ok(to_integer(word)?.to_string())
}

/// Parse an unsigned decimal string. Rejects sign characters, empty strings,
/// and anything but ASCII digits `0-9` with `invalid_natural_number`.
pub fn from_integer_string(s: &str) -> Result<Word> {
    if s.is_empty() || !s.bytes().all(|b| b.is_ascii_digit()) {
        return Err(Error::InvalidNaturalNumber(format!(
            "expected unsigned decimal string, got {s:?}"
        )));
    }
    let n = BigUint::parse_bytes(s.as_bytes(), 10).ok_or_else(|| {
        Error::InvalidNaturalNumber(format!("expected unsigned decimal string, got {s:?}"))
    })?;
    from_integer(&n)
}
