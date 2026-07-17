//! Stable, machine-readable error codes.
//!
//! One variant per code in the SDK-INTERFACE.md §3 registry. Codes are
//! permanent (add, never rename); the detail strings are human-readable and
//! **non-normative** — conformance asserts only on [`Error::code`].

use std::fmt;

/// Result alias used across the crate.
pub type Result<T> = std::result::Result<T, Error>;

/// Error with a stable machine-readable code (SDK-INTERFACE.md §3).
///
/// `Display` formats as `"<code>: <detail>"`, matching the message shape of
/// the Python reference implementation.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Error {
    /// `invalid_natural_number` — an integer(-string) input that is not an
    /// unsigned decimal natural (sign character, empty string, non-digits).
    InvalidNaturalNumber(String),
    /// `nonminimal_varint` — an LEB128 varint with a redundant zero
    /// continuation group (e.g. `80 00` for 0).
    NonminimalVarint(String),
    /// `reserved_tag` — the reserved term tag byte `0x04`.
    ReservedTag(String),
    /// `unknown_tag` — a term tag byte above `0x04`.
    UnknownTag(String),
    /// `truncated` — input ended inside a construct being read.
    Truncated(String),
    /// `trailing_bytes` — bytes remained after the root term.
    TrailingBytes(String),
    /// `invalid_version` — schema version not a positive integer.
    InvalidVersion(String),
    /// `invalid_orientation` — orientation outside `0..=3` (schema v1).
    InvalidOrientation(String),
    /// `invalid_socket_id` — socket id outside `0..=7` (schema v1).
    InvalidSocketId(String),
    /// `duplicate_socket` — two sockets with the same id (never repaired).
    DuplicateSocket(String),
    /// `unsorted_sockets` — sockets not strictly ascending on a strict path.
    UnsortedSockets(String),
    /// `invalid_structure` — any other structural defect (wrong term shape,
    /// malformed JSON, values outside this SDK's representable range, ...).
    InvalidStructure(String),
    /// `unsupported` — outside romanization profile core-v1 coverage.
    Unsupported(String),
}

impl Error {
    /// The stable machine-readable code (exact snake_case registry string).
    pub fn code(&self) -> &'static str {
        match self {
            Error::InvalidNaturalNumber(_) => "invalid_natural_number",
            Error::NonminimalVarint(_) => "nonminimal_varint",
            Error::ReservedTag(_) => "reserved_tag",
            Error::UnknownTag(_) => "unknown_tag",
            Error::Truncated(_) => "truncated",
            Error::TrailingBytes(_) => "trailing_bytes",
            Error::InvalidVersion(_) => "invalid_version",
            Error::InvalidOrientation(_) => "invalid_orientation",
            Error::InvalidSocketId(_) => "invalid_socket_id",
            Error::DuplicateSocket(_) => "duplicate_socket",
            Error::UnsortedSockets(_) => "unsorted_sockets",
            Error::InvalidStructure(_) => "invalid_structure",
            Error::Unsupported(_) => "unsupported",
        }
    }

    /// The human-readable detail (non-normative).
    pub fn detail(&self) -> &str {
        match self {
            Error::InvalidNaturalNumber(s)
            | Error::NonminimalVarint(s)
            | Error::ReservedTag(s)
            | Error::UnknownTag(s)
            | Error::Truncated(s)
            | Error::TrailingBytes(s)
            | Error::InvalidVersion(s)
            | Error::InvalidOrientation(s)
            | Error::InvalidSocketId(s)
            | Error::DuplicateSocket(s)
            | Error::UnsortedSockets(s)
            | Error::InvalidStructure(s)
            | Error::Unsupported(s) => s,
        }
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}: {}", self.code(), self.detail())
    }
}

impl std::error::Error for Error {}
