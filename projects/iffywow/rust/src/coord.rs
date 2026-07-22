//! Canonical coordinate tuple (schema v1). Normative: `../../CODEC.md` §2.
//!
//! Canonical-form invariants (checked by [`validate`], repaired where lenient
//! by [`canonicalize`]):
//!
//! * `version >= 1`; `orientation` in `0..=3`; socket `id` in `0..=7`.
//! * Sockets sorted strictly ascending by id (duplicates are always an
//!   error, never repaired).
//! * Empty sockets are omitted: there is no "empty" [`Socket`] value — a
//!   socket always carries a [`Modifier`]. The wire form `[id, null]` is
//!   accepted on *input* at the JSON boundary ([`crate::wire::from_wire`])
//!   and dropped during canonicalization there.
//!
//! # Representation limits
//!
//! Open enum ids (`character_class`, `base`, `shape`, diacritic ids) are
//! `u64` in this SDK. The byte codec itself (codec-v1) is arbitrary
//! precision; schema ids will not exceed `u64` in practice, so serialized
//! input carrying a value `>= 2^64` in one of these fields is rejected by
//! the decoder with `invalid_structure` rather than silently truncated
//! (see `crate::codec`). Likewise `version` is `u32` here; a structurally
//! valid word whose version exceeds `u32::MAX` is rejected with
//! `invalid_structure` on decode.

use crate::error::{Error, Result};

/// Highest orientation value in schema v1.
pub const MAX_ORIENTATION: u8 = 3;
/// Highest socket id in schema v1.
pub const MAX_SOCKET_ID: u8 = 7;

/// A canonical word: schema version plus glyph sequence.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Word {
    pub version: u32,
    pub glyphs: Vec<Glyph>,
}

/// One glyph of a word.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Glyph {
    pub character_class: u64,
    pub base: u64,
    /// `0..=3` in schema v1.
    pub orientation: u8,
    /// Strictly ascending by [`Socket::id`]; empty sockets omitted.
    pub sockets: Vec<Socket>,
}

/// An occupied socket. Empty sockets are omitted from the canonical form,
/// so a socket always carries a modifier.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Socket {
    /// `0..=7` in schema v1.
    pub id: u8,
    pub modifier: Modifier,
}

/// A socket modifier.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Modifier {
    pub shape: u64,
    /// `0..=3` in schema v1.
    pub orientation: u8,
    pub diacritics: Vec<u64>,
    /// Nested sockets, same invariants as glyph sockets.
    pub sockets: Vec<Socket>,
}

/// Structural check of a language-native [`Word`] value.
///
/// Errors: `invalid_version`, `invalid_orientation`, `invalid_socket_id`,
/// `duplicate_socket`, `unsorted_sockets`.
pub fn validate(word: &Word) -> Result<()> {
    if word.version < 1 {
        return Err(Error::InvalidVersion(format!(
            "schema version must be a positive integer, got {}",
            word.version
        )));
    }
    for (i, glyph) in word.glyphs.iter().enumerate() {
        validate_glyph(glyph, i)?;
    }
    Ok(())
}

fn validate_glyph(glyph: &Glyph, index: usize) -> Result<()> {
    if glyph.orientation > MAX_ORIENTATION {
        return Err(Error::InvalidOrientation(format!(
            "glyph {index}: orientation must be 0..{MAX_ORIENTATION}, got {}",
            glyph.orientation
        )));
    }
    validate_sockets(&glyph.sockets)
}

fn validate_sockets(sockets: &[Socket]) -> Result<()> {
    let mut prev: Option<u8> = None;
    for socket in sockets {
        if socket.id > MAX_SOCKET_ID {
            return Err(Error::InvalidSocketId(format!(
                "socket id must be 0..{MAX_SOCKET_ID} in schema v1, got {}",
                socket.id
            )));
        }
        match prev {
            Some(p) if socket.id == p => {
                return Err(Error::DuplicateSocket(format!(
                    "duplicate socket {}",
                    socket.id
                )));
            }
            Some(p) if socket.id < p => {
                return Err(Error::UnsortedSockets(format!(
                    "sockets must be sorted strictly ascending (socket {} after {p})",
                    socket.id
                )));
            }
            _ => {}
        }
        prev = Some(socket.id);
        validate_modifier(&socket.modifier)?;
    }
    Ok(())
}

fn validate_modifier(modifier: &Modifier) -> Result<()> {
    if modifier.orientation > MAX_ORIENTATION {
        return Err(Error::InvalidOrientation(format!(
            "modifier orientation must be 0..{MAX_ORIENTATION}, got {}",
            modifier.orientation
        )));
    }
    validate_sockets(&modifier.sockets)
}

/// Lenient repair of a language-native [`Word`]: sorts every socket list
/// (recursively) by id, then validates. Duplicate socket ids are always an
/// error (`duplicate_socket`) — never repaired.
///
/// The canonical form has no empty sockets and the native [`Socket`] type
/// cannot represent one, so — unlike the JSON wire boundary — there is
/// nothing to drop here.
pub fn canonicalize(word: &Word) -> Result<Word> {
    let mut canonical = word.clone();
    for glyph in &mut canonical.glyphs {
        sort_sockets(&mut glyph.sockets)?;
    }
    validate(&canonical)?;
    Ok(canonical)
}

fn sort_sockets(sockets: &mut Vec<Socket>) -> Result<()> {
    sockets.sort_by_key(|s| s.id);
    for pair in sockets.windows(2) {
        if pair[0].id == pair[1].id {
            return Err(Error::DuplicateSocket(format!(
                "duplicate socket {}",
                pair[0].id
            )));
        }
    }
    for socket in sockets.iter_mut() {
        sort_sockets(&mut socket.modifier.sockets)?;
    }
    Ok(())
}
