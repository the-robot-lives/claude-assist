//! Romanization profile core-v1. Normative: `../../ROMANIZATION.md`.
//!
//! Exactly one word shape is accepted — an unconcatenated formative
//! `Vv Cr Vr Ca Vc` (slots II, III, IV, VI, IX) with closed tables per slot.
//! Everything else is rejected with the stable code `unsupported`; the
//! profile never guesses.
//!
//! # Unicode note
//!
//! ROMANIZATION.md §1 preprocessing is trim → NFC → lowercase. The profile
//! alphabet consists solely of single precomposed codepoints, so this
//! implementation approximates full NFC with a **targeted composition map**
//! over the profile alphabet only: the decomposed combining-mark sequences
//! of every inventory codepoint (both cases, plus the stress-marked vowels
//! so they classify as stress rather than as unknown marks) are folded to
//! their precomposed forms before lowercasing. Sequences outside that table
//! are left as-is and subsequently rejected with `unsupported` — exactly the
//! outcome full NFC would produce for out-of-alphabet input (only the
//! non-normative error detail may differ).

use crate::coord::{self, Glyph, Modifier, Socket, Word};
use crate::error::{Error, Result};

/// Maximum root code: 27 + 27^2 + 27^3 + 27^4 (clusters of length <= 4).
pub const MAX_ROOT_CODE: u64 = 551_880;

/// Root inventory, **normative order** (ROMANIZATION.md §2.3): the base-27
/// digit of a consonant is its 1-based position in this array.
const ROOT_CONSONANTS: [char; 27] = [
    'p',          //  1  U+0070
    'b',          //  2  U+0062
    't',          //  3  U+0074
    'd',          //  4  U+0064
    'k',          //  5  U+006B
    'g',          //  6  U+0067
    'f',          //  7  U+0066
    'v',          //  8  U+0076
    '\u{0163}',   //  9  ţ t-cedilla
    '\u{1E11}',   // 10  ḑ d-cedilla
    's',          // 11  U+0073
    'z',          // 12  U+007A
    'c',          // 13  U+0063
    '\u{1E93}',   // 14  ẓ z-dot-below
    '\u{0161}',   // 15  š s-caron
    '\u{017E}',   // 16  ž z-caron
    '\u{010D}',   // 17  č c-caron
    'j',          // 18  U+006A
    '\u{00E7}',   // 19  ç c-cedilla
    'x',          // 20  U+0078
    '\u{013C}',   // 21  ļ l-cedilla
    'l',          // 22  U+006C
    'r',          // 23  U+0072
    '\u{0159}',   // 24  ř r-caron
    'm',          // 25  U+006D
    'n',          // 26  U+006E
    '\u{0148}',   // 27  ň n-caron
];

/// Vowel inventory (ROMANIZATION.md §2.1).
const VOWELS: [char; 9] = [
    'a',
    '\u{00E4}', // ä
    'e',
    '\u{00EB}', // ë
    'i',
    'o',
    '\u{00F6}', // ö
    'u',
    '\u{00FC}', // ü
];

/// Stress-marked vowels (Slot X) — always rejected (ROMANIZATION.md §2.2).
const STRESS_VOWELS: [char; 10] = [
    '\u{00E1}', // á
    '\u{00E9}', // é
    '\u{00ED}', // í
    '\u{00F3}', // ó
    '\u{00FA}', // ú
    '\u{00E2}', // â
    '\u{00EA}', // ê
    '\u{00EE}', // î
    '\u{00F4}', // ô
    '\u{00FB}', // û
];

/// Additional segmenter consonants (ROMANIZATION.md §2.3): classify as
/// consonants for run segmentation; validity is decided by the slot tables.
const SEGMENTER_CONSONANTS: [char; 4] = ['w', 'y', 'h', '\''];

/// Targeted composition map: `(base, combining mark) -> precomposed`.
/// Covers the NFD decompositions of every profile-alphabet codepoint and of
/// the stress-marked vowels, in both cases. Marks used: U+0301 acute,
/// U+0302 circumflex, U+0308 diaeresis, U+030C caron, U+0323 dot below,
/// U+0327 cedilla.
const COMPOSE: &[(char, char, char)] = &[
    // Lowercase profile vowels.
    ('a', '\u{0308}', '\u{00E4}'), // ä
    ('e', '\u{0308}', '\u{00EB}'), // ë
    ('o', '\u{0308}', '\u{00F6}'), // ö
    ('u', '\u{0308}', '\u{00FC}'), // ü
    // Lowercase profile consonants.
    ('t', '\u{0327}', '\u{0163}'), // ţ
    ('d', '\u{0327}', '\u{1E11}'), // ḑ
    ('c', '\u{0327}', '\u{00E7}'), // ç
    ('l', '\u{0327}', '\u{013C}'), // ļ
    ('s', '\u{030C}', '\u{0161}'), // š
    ('z', '\u{030C}', '\u{017E}'), // ž
    ('c', '\u{030C}', '\u{010D}'), // č
    ('r', '\u{030C}', '\u{0159}'), // ř
    ('n', '\u{030C}', '\u{0148}'), // ň
    ('z', '\u{0323}', '\u{1E93}'), // ẓ
    // Lowercase stress-marked vowels (composed so they classify as stress).
    ('a', '\u{0301}', '\u{00E1}'), // á
    ('e', '\u{0301}', '\u{00E9}'), // é
    ('i', '\u{0301}', '\u{00ED}'), // í
    ('o', '\u{0301}', '\u{00F3}'), // ó
    ('u', '\u{0301}', '\u{00FA}'), // ú
    ('a', '\u{0302}', '\u{00E2}'), // â
    ('e', '\u{0302}', '\u{00EA}'), // ê
    ('i', '\u{0302}', '\u{00EE}'), // î
    ('o', '\u{0302}', '\u{00F4}'), // ô
    ('u', '\u{0302}', '\u{00FB}'), // û
    // Uppercase counterparts (lowercased afterwards per §1 step 3).
    ('A', '\u{0308}', '\u{00C4}'), // Ä
    ('E', '\u{0308}', '\u{00CB}'), // Ë
    ('O', '\u{0308}', '\u{00D6}'), // Ö
    ('U', '\u{0308}', '\u{00DC}'), // Ü
    ('T', '\u{0327}', '\u{0162}'), // Ţ
    ('D', '\u{0327}', '\u{1E10}'), // Ḑ
    ('C', '\u{0327}', '\u{00C7}'), // Ç
    ('L', '\u{0327}', '\u{013B}'), // Ļ
    ('S', '\u{030C}', '\u{0160}'), // Š
    ('Z', '\u{030C}', '\u{017D}'), // Ž
    ('C', '\u{030C}', '\u{010C}'), // Č
    ('R', '\u{030C}', '\u{0158}'), // Ř
    ('N', '\u{030C}', '\u{0147}'), // Ň
    ('Z', '\u{0323}', '\u{1E92}'), // Ẓ
    ('A', '\u{0301}', '\u{00C1}'), // Á
    ('E', '\u{0301}', '\u{00C9}'), // É
    ('I', '\u{0301}', '\u{00CD}'), // Í
    ('O', '\u{0301}', '\u{00D3}'), // Ó
    ('U', '\u{0301}', '\u{00DA}'), // Ú
    ('A', '\u{0302}', '\u{00C2}'), // Â
    ('E', '\u{0302}', '\u{00CA}'), // Ê
    ('I', '\u{0302}', '\u{00CE}'), // Î
    ('O', '\u{0302}', '\u{00D4}'), // Ô
    ('U', '\u{0302}', '\u{00DB}'), // Û
];

fn compose_pair(base: char, mark: char) -> Option<char> {
    COMPOSE
        .iter()
        .find(|(b, m, _)| *b == base && *m == mark)
        .map(|(_, _, composed)| *composed)
}

/// ROMANIZATION.md §1: trim → (targeted) compose → lowercase.
fn preprocess(input: &str) -> String {
    let trimmed = input.trim();
    let mut composed: Vec<char> = Vec::new();
    for ch in trimmed.chars() {
        let last = composed.last().copied();
        if let Some(prev) = last {
            if let Some(merged) = compose_pair(prev, ch) {
                composed.pop();
                composed.push(merged);
                continue;
            }
        }
        composed.push(ch);
    }
    composed.into_iter().collect::<String>().to_lowercase()
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Class {
    Vowel,
    Consonant,
}

fn classify(c: char) -> Result<Class> {
    if VOWELS.contains(&c) {
        return Ok(Class::Vowel);
    }
    if ROOT_CONSONANTS.contains(&c) || SEGMENTER_CONSONANTS.contains(&c) {
        return Ok(Class::Consonant);
    }
    if STRESS_VOWELS.contains(&c) {
        return Err(Error::Unsupported(format!(
            "stress-marked vowel {c:?} (Slot X stress) is outside profile core-v1"
        )));
    }
    Err(Error::Unsupported(format!(
        "character {c:?} (U+{:04X}) is outside the profile core-v1 inventories",
        c as u32
    )))
}

// ---------------------------------------------------------------------------
// Slot tables (ROMANIZATION.md §4). Keys are whole runs.
// ---------------------------------------------------------------------------

/// Vv → (stem, version): version 0 = PRC, 1 = CPT.
fn vv_lookup(run: &str) -> Option<(u8, u8)> {
    match run {
        "a" => Some((1, 0)),
        "\u{00E4}" => Some((1, 1)), // ä
        "e" => Some((2, 0)),
        "i" => Some((2, 1)),
        "u" => Some((3, 0)),
        "\u{00FC}" => Some((3, 1)), // ü
        "o" => Some((0, 0)),
        "\u{00F6}" => Some((0, 1)), // ö
        _ => None,
    }
}

/// Vr → (function, specification): function 0 = STA, 1 = DYN.
fn vr_lookup(run: &str) -> Option<(u8, u64)> {
    match run {
        "a" => Some((0, 0)),
        "\u{00E4}" => Some((0, 1)), // ä
        "e" => Some((0, 2)),
        "i" => Some((0, 3)),
        "u" => Some((1, 0)),
        "\u{00FC}" => Some((1, 1)), // ü
        "o" => Some((1, 2)),
        "\u{00F6}" => Some((1, 3)), // ö
        _ => None,
    }
}

/// Ca → perspective.
fn ca_lookup(run: &str) -> Option<u64> {
    match run {
        "l" => Some(0),
        "r" => Some(1),
        "w" => Some(2),
        "y" => Some(3),
        _ => None,
    }
}

/// Vc → case index (whole vowel run; `ëi` is the only digraph).
fn vc_lookup(run: &str) -> Option<u64> {
    match run {
        "a" => Some(0),
        "\u{00E4}" => Some(1),  // ä
        "e" => Some(2),
        "i" => Some(3),
        "\u{00EB}i" => Some(4), // ëi
        "\u{00F6}" => Some(5),  // ö
        "o" => Some(6),
        "\u{00FC}" => Some(7),  // ü
        "u" => Some(8),
        _ => None,
    }
}

// ---------------------------------------------------------------------------
// Root cluster <-> base-27 bijective numeration (ROMANIZATION.md §5).
// ---------------------------------------------------------------------------

fn root_digit(c: char) -> Option<u64> {
    ROOT_CONSONANTS
        .iter()
        .position(|rc| *rc == c)
        .map(|i| (i + 1) as u64)
}

/// Encode a non-empty Cr run (1..=4 root consonants) as its root code.
fn root_encode(run: &str) -> Result<u64> {
    let chars: Vec<char> = run.chars().collect();
    if chars.len() > 4 {
        return Err(Error::Unsupported(format!(
            "root cluster {run:?} is longer than 4 consonants"
        )));
    }
    let mut acc: u64 = 0;
    for c in &chars {
        let digit = root_digit(*c).ok_or_else(|| {
            Error::Unsupported(format!(
                "consonant {c:?} is not in the root inventory (Cr position)"
            ))
        })?;
        acc = acc * 27 + digit;
    }
    Ok(acc) // run is a maximal run, hence non-empty, hence acc >= 1
}

/// Decode a root code back to its unique cluster.
fn root_decode(code: u64) -> Result<String> {
    if code == 0 || code > MAX_ROOT_CODE {
        return Err(Error::Unsupported(format!(
            "glyph base {code} is not a root code of profile core-v1 (1..={MAX_ROOT_CODE})"
        )));
    }
    let mut n = code;
    let mut digits: Vec<u64> = Vec::new();
    while n > 0 {
        let digit = ((n - 1) % 27) + 1; // 1..=27
        digits.push(digit);
        n = (n - 1) / 27;
    }
    if digits.len() > 4 {
        // Unreachable given the MAX_ROOT_CODE bound; kept as a guard.
        return Err(Error::Unsupported(format!(
            "glyph base {code} decodes to more than 4 consonants"
        )));
    }
    Ok(digits
        .iter()
        .rev()
        .map(|d| ROOT_CONSONANTS[(*d - 1) as usize])
        .collect())
}

// ---------------------------------------------------------------------------
// Inverse slot tables (used by `to_latin`).
// ---------------------------------------------------------------------------

fn vv_string(stem: u8, version: u8) -> Option<&'static str> {
    match (stem, version) {
        (1, 0) => Some("a"),
        (1, 1) => Some("\u{00E4}"), // ä
        (2, 0) => Some("e"),
        (2, 1) => Some("i"),
        (3, 0) => Some("u"),
        (3, 1) => Some("\u{00FC}"), // ü
        (0, 0) => Some("o"),
        (0, 1) => Some("\u{00F6}"), // ö
        _ => None,
    }
}

fn vr_string(function: u8, spec: u64) -> Option<&'static str> {
    match (function, spec) {
        (0, 0) => Some("a"),
        (0, 1) => Some("\u{00E4}"), // ä
        (0, 2) => Some("e"),
        (0, 3) => Some("i"),
        (1, 0) => Some("u"),
        (1, 1) => Some("\u{00FC}"), // ü
        (1, 2) => Some("o"),
        (1, 3) => Some("\u{00F6}"), // ö
        _ => None,
    }
}

fn ca_string(perspective: u64) -> Option<&'static str> {
    match perspective {
        0 => Some("l"),
        1 => Some("r"),
        2 => Some("w"),
        3 => Some("y"),
        _ => None,
    }
}

fn vc_string(case_index: u64) -> Option<&'static str> {
    match case_index {
        0 => Some("a"),
        1 => Some("\u{00E4}"),  // ä
        2 => Some("e"),
        3 => Some("i"),
        4 => Some("\u{00EB}i"), // ëi
        5 => Some("\u{00F6}"),  // ö
        6 => Some("o"),
        7 => Some("\u{00FC}"),  // ü
        8 => Some("u"),
        _ => None,
    }
}

// ---------------------------------------------------------------------------
// Public API.
// ---------------------------------------------------------------------------

/// Romanized New Ithkuil text → canonical [`Word`] (profile core-v1).
///
/// Everything outside the profile is rejected with code `unsupported`.
pub fn from_latin(text: &str) -> Result<Word> {
    let word = preprocess(text);
    if word.is_empty() {
        return Err(Error::Unsupported(
            "empty word (after trimming)".to_string(),
        ));
    }

    // Segment into maximal runs of same-class characters (§3).
    let mut runs: Vec<(Class, String)> = Vec::new();
    for c in word.chars() {
        let class = classify(c)?;
        let start_new = match runs.last() {
            Some((last_class, _)) => *last_class != class,
            None => true,
        };
        if start_new {
            runs.push((class, String::new()));
        }
        runs.last_mut().expect("just pushed").1.push(c);
    }

    // Exactly five runs, alternating, vowel first: Vv Cr Vr Ca Vc.
    // Maximal runs alternate by construction, so count + first class suffice.
    if runs.len() != 5 || runs[0].0 != Class::Vowel {
        return Err(Error::Unsupported(format!(
            "word shape must be Vv Cr Vr Ca Vc (five alternating runs, vowel first); \
             got {} run(s)",
            runs.len()
        )));
    }

    let vv = runs[0].1.as_str();
    let cr = runs[1].1.as_str();
    let vr = runs[2].1.as_str();
    let ca = runs[3].1.as_str();
    let vc = runs[4].1.as_str();

    let (stem, version) = vv_lookup(vv).ok_or_else(|| {
        Error::Unsupported(format!("Vv {vv:?} is not a Vv form of profile core-v1"))
    })?;
    let base = root_encode(cr)?;
    let (function, spec) = vr_lookup(vr).ok_or_else(|| {
        Error::Unsupported(format!("Vr {vr:?} is not a Vr form of profile core-v1"))
    })?;
    let perspective = ca_lookup(ca).ok_or_else(|| {
        Error::Unsupported(format!("Ca {ca:?} is not a Ca form of profile core-v1"))
    })?;
    let case_index = vc_lookup(vc).ok_or_else(|| {
        Error::Unsupported(format!("Vc {vc:?} is not a Vc form of profile core-v1"))
    })?;

    // Morpheme → coordinate mapping (§6): one glyph, three sockets.
    Ok(Word {
        version: 1,
        glyphs: vec![Glyph {
            character_class: 0,
            base,
            orientation: stem,
            sockets: vec![
                Socket {
                    id: 0,
                    modifier: Modifier {
                        shape: spec,
                        orientation: function + 2 * version,
                        diacritics: vec![],
                        sockets: vec![],
                    },
                },
                Socket {
                    id: 1,
                    modifier: Modifier {
                        shape: perspective,
                        orientation: 0,
                        diacritics: vec![],
                        sockets: vec![],
                    },
                },
                Socket {
                    id: 2,
                    modifier: Modifier {
                        shape: case_index,
                        orientation: 0,
                        diacritics: vec![],
                        sockets: vec![],
                    },
                },
            ],
        }],
    })
}

/// Canonical [`Word`] → canonical spelling (profile core-v1, §7).
///
/// The input is canonicalized first (sockets sorted; structural defects keep
/// their structural error codes); any coordinate outside the exact §6/§7
/// shape is rejected with `unsupported`.
pub fn to_latin(word: &Word) -> Result<String> {
    let canonical = coord::canonicalize(word)?;

    let unsupported =
        |detail: &str| -> Error { Error::Unsupported(format!("{detail} (profile core-v1)")) };

    if canonical.version != 1 {
        return Err(unsupported(&format!(
            "romanization is only defined for schema version 1, got {}",
            canonical.version
        )));
    }
    if canonical.glyphs.len() != 1 {
        return Err(unsupported(&format!(
            "expected exactly one glyph, got {}",
            canonical.glyphs.len()
        )));
    }
    let glyph = &canonical.glyphs[0];
    if glyph.character_class != 0 {
        return Err(unsupported(&format!(
            "expected character class 0 (formative), got {}",
            glyph.character_class
        )));
    }
    let cr = root_decode(glyph.base)?;
    let stem = glyph.orientation; // 0..=3 guaranteed by canonicalize

    if glyph.sockets.len() != 3
        || glyph.sockets[0].id != 0
        || glyph.sockets[1].id != 1
        || glyph.sockets[2].id != 2
    {
        return Err(unsupported(
            "expected exactly the three sockets 0, 1, 2 on the glyph",
        ));
    }
    for socket in &glyph.sockets {
        if !socket.modifier.diacritics.is_empty() || !socket.modifier.sockets.is_empty() {
            return Err(unsupported(&format!(
                "socket {} modifier must have empty diacritics and no child sockets",
                socket.id
            )));
        }
    }

    let m0 = &glyph.sockets[0].modifier;
    let m1 = &glyph.sockets[1].modifier;
    let m2 = &glyph.sockets[2].modifier;

    if m0.shape > 3 {
        return Err(unsupported(&format!(
            "socket 0 shape (specification) must be 0..3, got {}",
            m0.shape
        )));
    }
    if m1.shape > 3 || m1.orientation != 0 {
        return Err(unsupported(
            "socket 1 must be [\"modifier\", perspective 0..3, 0, [], []]",
        ));
    }
    if m2.shape > 8 || m2.orientation != 0 {
        return Err(unsupported(
            "socket 2 must be [\"modifier\", case index 0..8, 0, [], []]",
        ));
    }

    // m0.orientation is 0..=3 post-canonicalize: fn_ver = function + 2*version.
    let version = m0.orientation / 2;
    let function = m0.orientation % 2;

    let vv = vv_string(stem, version)
        .ok_or_else(|| unsupported("no Vv form for this stem/version"))?;
    let vr = vr_string(function, m0.shape)
        .ok_or_else(|| unsupported("no Vr form for this function/specification"))?;
    let ca = ca_string(m1.shape).ok_or_else(|| unsupported("no Ca form for this perspective"))?;
    let vc = vc_string(m2.shape).ok_or_else(|| unsupported("no Vc form for this case index"))?;

    Ok(format!("{vv}{cr}{vr}{ca}{vc}"))
}
