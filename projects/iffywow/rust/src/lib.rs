//! # ithkuil — iffywow New Ithkuil codec, Rust core SDK
//!
//! Core **conversions only** (no scene graphs, no SVG, no rendering) between
//! the value domains of the iffywow SDK interface:
//!
//! | Domain | Rust type |
//! |---|---|
//! | `Coord` | [`Word`] (canonical: sockets strictly ascending, empties omitted) |
//! | `Latin` | `String` (romanization profile core-v1, canonical spelling) |
//! | `Integer` | [`num_bigint::BigUint`] |
//! | `IntegerString` | `String` (unsigned decimal — the only cross-boundary integer form) |
//! | `Bytes` | `Vec<u8>` (canonical codec-v1 serialization) |
//! | `Wire` | [`serde_json::Value`] / JSON text (tagged arrays) |
//!
//! Normative documents (this crate implements them exactly; the golden
//! vectors under `../conformance/` are the arbiter):
//!
//! * `../SDK-INTERFACE.md` — operations, laws, error-code registry
//! * `../CODEC.md` — codec-v1 bytes/terms/integer ranking (schema v1)
//! * `../ROMANIZATION.md` — romanization profile core-v1
//!
//! Strictness boundary: byte and integer inputs are **strict** (one meaning,
//! one representation); wire/JSON and language-native inputs are **lenient
//! but canonicalizing** (sockets sorted, `[id, null]` empties dropped).
//! Duplicated sockets are always an error, never repaired.
//!
//! All fallible operations return [`Result<T, Error>`](Error); every error
//! carries a stable machine-readable code via [`Error::code`].
//!
//! ```no_run
//! let word = ithkuil::from_latin("alala").unwrap();
//! let n = ithkuil::to_integer_string(&word).unwrap();
//! assert_eq!(ithkuil::from_integer_string(&n).unwrap(), word);
//! assert_eq!(ithkuil::to_latin(&word).unwrap(), "alala");
//! ```

pub mod codec;
pub mod coord;
pub mod error;
pub mod romanization;
pub mod wire;

pub use codec::{
    from_bytes, from_integer, from_integer_string, to_bytes, to_integer, to_integer_string,
};
pub use coord::{canonicalize, validate, Glyph, Modifier, Socket, Word};
pub use error::{Error, Result};
pub use romanization::{from_latin, to_latin};
pub use wire::{from_wire, from_wire_json, to_wire, to_wire_json};

// Re-exported so downstream code can name the integer type without adding
// its own num-bigint dependency line.
pub use num_bigint;
