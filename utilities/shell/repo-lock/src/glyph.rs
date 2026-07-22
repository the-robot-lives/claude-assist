//! Cosmetic session-handle encoding.
//!
//! Reuses `misc-git-utils`' `doc-pointers` base-1072 unicode scheme (four glyphs from
//! the U+13000..U+1342F Egyptian Hieroglyph block) so a session's handle reads the same
//! way across Noizu tooling. Unlike `doc-pointers`, where the glyph *is* the pointer id,
//! here it is **cosmetic and lossy** — only the base-1072 residue (~40 bits) of the
//! 128-bit session UUID survives, so display collisions are possible. The full UUID in
//! the lock record is the sole authoritative identity; the glyph handle is the canonical
//! display form, and the codepoint-sequence fallback renders the *same* residue for
//! glyph-poor terminals.

use uuid::Uuid;

// Encoding constants — duplicated verbatim from
// utilities/shell/misc-git-utils/src/bin/doc-pointers.rs (unicode4_encode_uuid).
const TOKEN_START: u32 = 0x13000;
const TOKEN_END: u32 = 0x1342F;
const TOKEN_SIZE: u128 = (TOKEN_END - TOKEN_START + 1) as u128;
const TOKEN_LENGTH: usize = 4;

/// The value the glyph handle actually displays: the UUID (big-endian u128) reduced
/// mod 1072^4. Not "the low 40 bits" — 1072^4 is not a power of two, so the residue
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
        chars.push(char::from_u32(TOKEN_START + index).expect("valid token code point"));
    }
    chars.into_iter().rev().collect()
}

/// Codepoint-sequence fallback for glyph-poor terminals / `--ascii`: the *same*
/// residue the glyph handle shows, rendered as `U+131B4 U+133B2 U+132DD U+13045`.
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
            (TOKEN_START..=TOKEN_END).contains(&n)
        }));
    }

    // MUST match doc-pointers.rs's golden test (generated_token_matches_unity_fixture) —
    // these constants are a cross-crate pact guarding drift between the duplicated encoders.
    #[test]
    fn golden_matches_doc_pointers_fixture() {
        let id = Uuid::parse_str("5c692577-ad0c-51f1-992c-759b5e5fffb5").unwrap();
        assert_eq!(
            unicode4_encode_uuid(id),
            "\u{131B4}\u{133B2}\u{132DD}\u{13045}"
        );
        assert_eq!(glyph_residue(id), 538_207_322_037);
        assert_eq!(codepoint_handle(id), "U+131B4 U+133B2 U+132DD U+13045");
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
