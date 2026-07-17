//! JSON wire form (tagged arrays). Normative: `../../CODEC.md` §2.
//!
//! ```text
//! ["ithkuil-word", version, [glyph, ...]]
//! ["glyph", character_class, base, orientation, [socket, ...]]
//! [socket_id, null | modifier]
//! ["modifier", shape, orientation, [diacritic_id, ...], [socket, ...]]
//! ```
//!
//! `to_wire` / `to_wire_json` are pure projections of a [`Word`] to its
//! tagged-array form. `from_wire` / `from_wire_json` are **lenient but
//! canonicalizing** per SDK-INTERFACE.md §2: unsorted sockets are sorted,
//! `[id, null]` empties are dropped, duplicated socket ids are always an
//! error (`duplicate_socket`).
//!
//! Numbers at this boundary: non-negative integers, including integral
//! floats (JSON cannot distinguish `2.0` from `2` — parity with the Python
//! reference). Values that cannot be represented exactly (above 2^53 on the
//! float path, above u64/u32 on the integer path) are rejected with
//! `invalid_structure`, never truncated.

use serde_json::Value;

use crate::coord::{Glyph, Modifier, Socket, Word, MAX_ORIENTATION, MAX_SOCKET_ID};
use crate::error::{Error, Result};

pub const WORD_TAG: &str = "ithkuil-word";
pub const GLYPH_TAG: &str = "glyph";
pub const MODIFIER_TAG: &str = "modifier";

// ---------------------------------------------------------------------------
// Word -> wire.
// ---------------------------------------------------------------------------

/// Canonical wire form (structural JSON value).
pub fn to_wire(word: &Word) -> Value {
    Value::Array(vec![
        Value::String(WORD_TAG.to_string()),
        Value::from(word.version),
        Value::Array(word.glyphs.iter().map(glyph_wire).collect()),
    ])
}

fn glyph_wire(glyph: &Glyph) -> Value {
    Value::Array(vec![
        Value::String(GLYPH_TAG.to_string()),
        Value::from(glyph.character_class),
        Value::from(glyph.base),
        Value::from(glyph.orientation),
        Value::Array(glyph.sockets.iter().map(socket_wire).collect()),
    ])
}

fn socket_wire(socket: &Socket) -> Value {
    Value::Array(vec![
        Value::from(socket.id),
        modifier_wire(&socket.modifier),
    ])
}

fn modifier_wire(modifier: &Modifier) -> Value {
    Value::Array(vec![
        Value::String(MODIFIER_TAG.to_string()),
        Value::from(modifier.shape),
        Value::from(modifier.orientation),
        Value::Array(modifier.diacritics.iter().map(|d| Value::from(*d)).collect()),
        Value::Array(modifier.sockets.iter().map(socket_wire).collect()),
    ])
}

/// Canonical wire form as compact JSON text (matches `JSON.stringify` /
/// Python `json.dumps(..., separators=(",", ":"))` of the same coordinate).
pub fn to_wire_json(word: &Word) -> String {
    serde_json::to_string(&to_wire(word))
        .expect("a tree of arrays, unsigned numbers and strings always serializes")
}

// ---------------------------------------------------------------------------
// Wire -> word (lenient, canonicalizing).
// ---------------------------------------------------------------------------

/// Parse a structural wire value into a canonical [`Word`].
pub fn from_wire(value: &Value) -> Result<Word> {
    let arr = match value.as_array() {
        Some(a) if a.len() == 3 && a[0].as_str() == Some(WORD_TAG) => a,
        _ => {
            return Err(fail(
                "$",
                &format!("expected [\"{WORD_TAG}\", version, glyphs]"),
            ))
        }
    };
    let version = match wire_nat(&arr[1], "$[1]") {
        Ok(v) if v >= 1 => v,
        _ => {
            return Err(Error::InvalidVersion(
                "invalid coordinate at $[1]: schema version must be a positive integer"
                    .to_string(),
            ))
        }
    };
    let version = u32::try_from(version).map_err(|_| {
        Error::InvalidStructure(
            "invalid coordinate at $[1]: word version exceeds the u32 range representable \
             by this SDK"
                .to_string(),
        )
    })?;
    let glyphs_arr = arr[2]
        .as_array()
        .ok_or_else(|| fail("$[2]", "glyph list must be an array"))?;
    let mut glyphs = Vec::with_capacity(glyphs_arr.len());
    for (i, glyph_value) in glyphs_arr.iter().enumerate() {
        glyphs.push(wire_glyph(glyph_value, &format!("$[2][{i}]"))?);
    }
    Ok(Word { version, glyphs })
}

/// Parse JSON text into a canonical [`Word`]. Text that is not valid JSON is
/// rejected with `invalid_structure`.
pub fn from_wire_json(text: &str) -> Result<Word> {
    let value: Value = serde_json::from_str(text).map_err(|e| {
        Error::InvalidStructure(format!("coordinate text is not valid JSON: {e}"))
    })?;
    from_wire(&value)
}

fn fail(path: &str, msg: &str) -> Error {
    Error::InvalidStructure(format!("invalid coordinate at {path}: {msg}"))
}

/// Non-negative integer at the JSON boundary, exact-value only.
fn wire_nat(value: &Value, path: &str) -> Result<u64> {
    if let Some(u) = value.as_u64() {
        return Ok(u);
    }
    if let Some(f) = value.as_f64() {
        // Integral floats are accepted (JSON `2.0` == `2`), but only inside
        // the exactly-representable range, so nothing is ever truncated.
        if f >= 0.0 && f.fract() == 0.0 && f <= 9_007_199_254_740_992.0 {
            return Ok(f as u64);
        }
    }
    Err(fail(path, "expected non-negative integer"))
}

fn wire_orientation(value: &Value, path: &str) -> Result<u8> {
    let n = wire_nat(value, path)?;
    if n > MAX_ORIENTATION as u64 {
        return Err(Error::InvalidOrientation(format!(
            "invalid coordinate at {path}: orientation must be 0..{MAX_ORIENTATION}"
        )));
    }
    Ok(n as u8)
}

fn wire_glyph(value: &Value, path: &str) -> Result<Glyph> {
    let arr = match value.as_array() {
        Some(a) if a.len() == 5 && a[0].as_str() == Some(GLYPH_TAG) => a,
        _ => {
            return Err(fail(
                path,
                &format!("expected [\"{GLYPH_TAG}\", class, base, orientation, sockets]"),
            ))
        }
    };
    Ok(Glyph {
        character_class: wire_nat(&arr[1], &format!("{path}[1]"))?,
        base: wire_nat(&arr[2], &format!("{path}[2]"))?,
        orientation: wire_orientation(&arr[3], &format!("{path}[3]"))?,
        sockets: wire_sockets(&arr[4], &format!("{path}[4]"))?,
    })
}

/// Lenient socket parsing: accepts any order and `[id, null]` empties; sorts
/// ascending and drops empties (canonical form). Duplicate ids error even
/// when one side is null.
fn wire_sockets(value: &Value, path: &str) -> Result<Vec<Socket>> {
    let arr = value
        .as_array()
        .ok_or_else(|| fail(path, "sockets must be an array"))?;
    let mut seen = [false; (MAX_SOCKET_ID as usize) + 1];
    let mut parsed: Vec<(u8, Option<Modifier>)> = Vec::with_capacity(arr.len());
    for (i, entry) in arr.iter().enumerate() {
        let entry_path = format!("{path}[{i}]");
        let pair = match entry.as_array() {
            Some(p) if p.len() == 2 => p,
            _ => return Err(fail(&entry_path, "expected [socket_id, null | modifier]")),
        };
        let id = wire_nat(&pair[0], &format!("{entry_path}[0]"))?;
        if id > MAX_SOCKET_ID as u64 {
            return Err(Error::InvalidSocketId(format!(
                "invalid coordinate at {entry_path}[0]: socket id must be \
                 0..{MAX_SOCKET_ID} in schema v1"
            )));
        }
        let id = id as u8;
        if seen[id as usize] {
            return Err(Error::DuplicateSocket(format!(
                "invalid coordinate at {entry_path}: duplicate socket {id}"
            )));
        }
        seen[id as usize] = true;
        let modifier = if pair[1].is_null() {
            None
        } else {
            Some(wire_modifier(&pair[1], &format!("{entry_path}[1]"))?)
        };
        parsed.push((id, modifier));
    }
    parsed.sort_by_key(|(id, _)| *id); // canonical ordering
    Ok(parsed
        .into_iter()
        .filter_map(|(id, modifier)| modifier.map(|modifier| Socket { id, modifier }))
        .collect()) // empties omitted
}

fn wire_modifier(value: &Value, path: &str) -> Result<Modifier> {
    let arr = match value.as_array() {
        Some(a) if a.len() == 5 && a[0].as_str() == Some(MODIFIER_TAG) => a,
        _ => {
            return Err(fail(
                path,
                &format!("expected [\"{MODIFIER_TAG}\", shape, orientation, diacritics, sockets]"),
            ))
        }
    };
    let diacritics_arr = arr[3]
        .as_array()
        .ok_or_else(|| fail(&format!("{path}[3]"), "diacritics must be an array"))?;
    let mut diacritics = Vec::with_capacity(diacritics_arr.len());
    for (i, d) in diacritics_arr.iter().enumerate() {
        diacritics.push(wire_nat(d, &format!("{path}[3][{i}]"))?);
    }
    Ok(Modifier {
        shape: wire_nat(&arr[1], &format!("{path}[1]"))?,
        orientation: wire_orientation(&arr[2], &format!("{path}[2]"))?,
        diacritics,
        sockets: wire_sockets(&arr[4], &format!("{path}[4]"))?,
    })
}
