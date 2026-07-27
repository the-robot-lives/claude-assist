//! Cosmetic session-handle encoding.
//!
//! Reuses `misc-git-utils`' `doc-pointers` printable sign alphabet (four glyphs from
//! curated hieroglyphic Unicode blocks) so a session's handle reads the same way across
//! Noizu tooling. Unlike `doc-pointers`, where the glyph *is* the pointer id, here it is
//! **cosmetic and lossy** — only the sign-alphabet residue (~50 bits) of the 128-bit
//! session UUID survives, so display collisions are possible. The full UUID in the lock
//! record is the sole authoritative identity; the glyph handle is the canonical display
//! form, and the codepoint-sequence fallback renders the *same* residue for glyph-poor
//! terminals.

use uuid::Uuid;

// Encoding constants — duplicated verbatim from
// utilities/shell/misc-git-utils/src/bin/doc-pointers.rs (unicode4_encode_uuid).
const TOKEN_RANGES: [(u32, u32); 4] = [
    (0x10980, 0x1099F), // Meroitic Hieroglyphs
    (0x13000, 0x1342F), // Egyptian Hieroglyphs
    (0x13460, 0x143FF), // Egyptian Hieroglyphs Extended-A; skips U+13430..U+1345F controls
    (0x14400, 0x1467F), // Anatolian Hieroglyphs
];
const TOKEN_SIZE: u128 = token_alphabet_size();
const TOKEN_LENGTH: usize = 4;

const fn token_alphabet_size() -> u128 {
    let mut total = 0u128;
    let mut index = 0usize;
    while index < TOKEN_RANGES.len() {
        let (start, end) = TOKEN_RANGES[index];
        total += (end - start + 1) as u128;
        index += 1;
    }
    total
}

/// The value the glyph handle actually displays: the UUID (big-endian u128) reduced
/// mod 5744^4. Not "the low bits" — 5744^4 is not a power of two, so the residue
/// depends on all 128 bits.
// ⟦𓁣𓐬𓇃𓎂⟧ glyph_residue :: The value the glyph handle actually displays: the UUID (big-endian u128) reduced
pub fn glyph_residue(value: Uuid) -> u128 {
    u128::from_be_bytes(*value.as_bytes()) % TOKEN_SIZE.pow(TOKEN_LENGTH as u32)
}

/// Four-glyph cosmetic handle for a session UUID.
///
/// Duplicated from `doc-pointers`' `unicode4_encode_uuid`; kept small and local
/// rather than shared so `repo-lock` has no build dependency on `misc-git-utils`.
// ⟦𓏹𓋯𓈗𓂗⟧ unicode4_encode_uuid :: Four-glyph cosmetic handle for a session UUID.
pub fn unicode4_encode_uuid(value: Uuid) -> String {
    let mut number = glyph_residue(value);
    let mut chars = Vec::new();
    for _ in 0..TOKEN_LENGTH {
        let index = (number % TOKEN_SIZE) as u32;
        number /= TOKEN_SIZE;
        chars.push(token_char_from_index(index));
    }
    chars.into_iter().rev().collect()
}

fn token_char_from_index(mut index: u32) -> char {
    for &(start, end) in TOKEN_RANGES.iter() {
        let range_size = end - start + 1;
        if index < range_size {
            return char::from_u32(start + index).expect("valid token code point");
        }
        index -= range_size;
    }
    panic!("token alphabet index out of range");
}

/// Codepoint-sequence fallback for glyph-poor terminals / `--ascii`: the *same*
/// residue the glyph handle shows, rendered as `U+13CD4 U+1442E U+1461F U+14135`.
/// Lossless with respect to the glyph handle — round-trips to the glyphs exactly.
// ⟦𓄲𓄄𓍁𓆑⟧ codepoint_handle :: Codepoint-sequence fallback for glyph-poor terminals / `--ascii`: the *same*
pub fn codepoint_handle(value: Uuid) -> String {
    unicode4_encode_uuid(value)
        .chars()
        .map(|c| format!("U+{:X}", c as u32))
        .collect::<Vec<_>>()
        .join(" ")
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
            TOKEN_RANGES
                .iter()
                .any(|(start, end)| (*start..=*end).contains(&n))
        }));
    }

    // MUST match doc-pointers.rs's golden test (generated_token_matches_unity_fixture) —
    // these constants are a cross-crate pact guarding drift between the duplicated encoders.
    #[test]
    fn golden_matches_doc_pointers_fixture() {
        let id = Uuid::parse_str("5c692577-ad0c-51f1-992c-759b5e5fffb5").unwrap();
        assert_eq!(
            unicode4_encode_uuid(id),
            "\u{13CD4}\u{1442E}\u{1461F}\u{14135}"
        );
        assert_eq!(glyph_residue(id), 619_504_546_873_269);
        assert_eq!(codepoint_handle(id), "U+13CD4 U+1442E U+1461F U+14135");
    }

    #[test]
    fn codepoint_handle_renders_same_value_as_glyphs() {
        let id = Uuid::parse_str("a1b2c3d4-0000-4000-8000-000000000000").unwrap();
        let glyphs = unicode4_encode_uuid(id);
        let rendered: String = codepoint_handle(id)
            .split(' ')
            .map(|cp| {
                let n = u32::from_str_radix(cp.trim_start_matches("U+"), 16).unwrap();
                char::from_u32(n).unwrap()
            })
            .collect();
        assert_eq!(
            rendered, glyphs,
            "codepoint form must round-trip to the glyph handle"
        );
    }
}
