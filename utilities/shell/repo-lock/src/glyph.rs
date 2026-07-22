//! Cosmetic session-handle encoding.
//!
//! Reuses `misc-git-utils`' `doc-pointers` base-1072 unicode scheme (four glyphs from
//! the U+13000..U+1342F Egyptian Hieroglyph block) so a session's handle reads the same
//! way across Noizu tooling. Unlike `doc-pointers`, where the glyph *is* the pointer id,
//! here it is **cosmetic and lossy** — only ~40 bits of the 128-bit session UUID survive,
//! so display collisions are possible. The full UUID in the lock record is the sole
//! authoritative identity; the glyph and its 8-hex fallback are for human/log readability.

use uuid::Uuid;

// Encoding constants — duplicated verbatim from
// utilities/shell/misc-git-utils/src/bin/doc-pointers.rs (unicode4_encode_uuid).
const TOKEN_START: u32 = 0x13000;
const TOKEN_END: u32 = 0x1342F;
const TOKEN_SIZE: u128 = (TOKEN_END - TOKEN_START + 1) as u128;
const TOKEN_LENGTH: usize = 4;

/// Four-glyph cosmetic handle for a session UUID.
///
/// Duplicated from `doc-pointers`' `unicode4_encode_uuid`; kept small and local
/// rather than shared so `repo-lock` has no build dependency on `misc-git-utils`.
pub fn unicode4_encode_uuid(value: Uuid) -> String {
    let mut number = u128::from_be_bytes(*value.as_bytes());
    let mut chars = Vec::new();
    for _ in 0..TOKEN_LENGTH {
        let index = (number % TOKEN_SIZE) as u32;
        number /= TOKEN_SIZE;
        chars.push(char::from_u32(TOKEN_START + index).expect("valid token code point"));
    }
    chars.into_iter().rev().collect()
}

/// Eight-hex fallback (first four bytes of the UUID) for glyph-poor terminals / `--ascii`.
/// New to `repo-lock` — no `doc-pointers` precedent.
pub fn hex8(value: Uuid) -> String {
    let b = value.as_bytes();
    format!("{:02x}{:02x}{:02x}{:02x}", b[0], b[1], b[2], b[3])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn encoding_is_stable_and_four_glyphs() {
        let id = Uuid::parse_str("9f2c1e4a-0000-4000-8000-000000000000").unwrap();
        let a = unicode4_encode_uuid(id);
        let b = unicode4_encode_uuid(id);
        assert_eq!(a, b, "encoding must be deterministic");
        assert_eq!(a.chars().count(), TOKEN_LENGTH);
        assert!(a.chars().all(|c| {
            let n = c as u32;
            (TOKEN_START..=TOKEN_END).contains(&n)
        }));
    }

    #[test]
    fn hex8_is_first_four_bytes() {
        let id = Uuid::parse_str("a1b2c3d4-0000-4000-8000-000000000000").unwrap();
        assert_eq!(hex8(id), "a1b2c3d4");
    }
}
