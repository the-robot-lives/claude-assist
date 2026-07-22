/**
 * Romanization profile core-v1 — exact implementation of ../../ROMANIZATION.md.
 *
 * core-v1 accepts exactly one word shape: an unconcatenated formative
 * `Vv Cr Vr Ca Vc` (slots II, III, IV, VI, IX) with closed tables per slot.
 * Everything else — Slot I Cc, affixes, VnCn, stress, glottal stop,
 * adjuncts, multiple words — is rejected with error code `unsupported`;
 * the profile never guesses.
 *
 * Every non-ASCII inventory codepoint below is constructed from its numeric
 * codepoint (String.fromCodePoint) so the tables are guaranteed to hold
 * single precomposed NFC codepoints regardless of how this source file is
 * normalized on disk.
 */

import { IthkuilError } from "./errors.js";
import { validate, canonicalize } from "./coord.js";

function unsupported(detail) {
  return new IthkuilError("unsupported", detail);
}

// --------------------------------------------------------------------------
// §2 Character inventories (exact codepoints, NFC).
// --------------------------------------------------------------------------

// Built from numeric codepoints (not source literals) so the tables hold the
// exact single precomposed NFC codepoints of ROMANIZATION.md SS2 no matter how
// this file is normalized on disk.
const chr = (codepoint) => String.fromCodePoint(codepoint);

const A_UML = chr(0x00e4); // a-diaeresis
const E_UML = chr(0x00eb); // e-diaeresis
const O_UML = chr(0x00f6); // o-diaeresis
const U_UML = chr(0x00fc); // u-diaeresis

/** §2.1 Vowels (class V) — 9 codepoints. */
const VOWEL_SET = new Set(["a", "e", "i", "o", "u", A_UML, E_UML, O_UML, U_UML]);

/**
 * §2.3 Root inventory — 27 consonants in NORMATIVE order; digit value = index + 1.
 * (Defines the bijective base-27 digits of §5.)
 */
const ROOT_CONSONANTS = Object.freeze([
  "p", //           1
  "b", //           2
  "t", //           3
  "d", //           4
  "k", //           5
  "g", //           6
  "f", //           7
  "v", //           8
  chr(0x0163), //   9  t-cedilla
  chr(0x1e11), //  10  d-cedilla
  "s", //          11
  "z", //          12
  "c", //          13
  chr(0x1e93), //  14  z-dot-below
  chr(0x0161), //  15  s-caron
  chr(0x017e), //  16  z-caron
  chr(0x010d), //  17  c-caron
  "j", //          18
  chr(0x00e7), //  19  c-cedilla
  "x", //          20
  chr(0x013c), //  21  l-cedilla
  "l", //          22
  "r", //          23
  chr(0x0159), //  24  r-caron
  "m", //          25
  "n", //          26
  chr(0x0148), //  27  n-caron
]);

const ROOT_DIGIT = new Map(ROOT_CONSONANTS.map((c, i) => [c, i + 1]));

/**
 * Additional segmenter consonants (§2.3): classify as C for run segmentation
 * but are valid only where a table row admits them (`w`/`y`: Ca only;
 * `h`/`'`: nowhere).
 */
const SEGMENT_CONSONANTS = new Set([...ROOT_CONSONANTS, "w", "y", "h", "'"]);

// --------------------------------------------------------------------------
// §4 Lookup tables (closed; exact rows).
// --------------------------------------------------------------------------

/** §4.1 Vv — stem + version (Slot II). value = [stem, version]. */
const VV = new Map([
  ["a", [1, 0]],
  [A_UML, [1, 1]],
  ["e", [2, 0]],
  ["i", [2, 1]],
  ["u", [3, 0]],
  [U_UML, [3, 1]],
  ["o", [0, 0]],
  [O_UML, [0, 1]],
]);

/** Vv inverse: VV_INVERSE[stem][version]. */
const VV_INVERSE = [
  ["o", O_UML], // stem 0
  ["a", A_UML], // stem 1
  ["e", "i"], //   stem 2
  ["u", U_UML], // stem 3
];

/** §4.2 Vr — function + specification (Slot IV). value = [function, spec]. */
const VR = new Map([
  ["a", [0, 0]],
  [A_UML, [0, 1]],
  ["e", [0, 2]],
  ["i", [0, 3]],
  ["u", [1, 0]],
  [U_UML, [1, 1]],
  ["o", [1, 2]],
  [O_UML, [1, 3]],
]);

/** Vr inverse: VR_INVERSE[function][spec]. */
const VR_INVERSE = [
  ["a", A_UML, "e", "i"], // STA
  ["u", U_UML, "o", O_UML], // DYN
];

/** §4.3 Ca — perspective (Slot VI). */
const CA = new Map([
  ["l", 0], // M  monadic
  ["r", 1], // G  agglomerative
  ["w", 2], // N  nomic
  ["y", 3], // A  abstract
]);

const CA_INVERSE = ["l", "r", "w", "y"];

/** §4.4 Vc — case (Slot IX; cases 1-9). `ëi` is U+00EB U+0069, matched as the whole run. */
const VC = new Map([
  ["a", 0], //         THM
  [A_UML, 1], //       INS
  ["e", 2], //         ABS
  ["i", 3], //         AFF
  [E_UML + "i", 4], // STM (digraph ëi)
  [O_UML, 5], //       EFF
  ["o", 6], //         ERG
  [U_UML, 7], //       DAT
  ["u", 8], //         IND
]);

const VC_INVERSE = ["a", A_UML, "e", "i", E_UML + "i", O_UML, "o", U_UML, "u"];

// --------------------------------------------------------------------------
// §5 Root cluster <-> base-27 integer (bijective numeration, no zero digit).
// --------------------------------------------------------------------------

export const MAX_ROOT_CODE = 551880; // 27 + 27^2 + 27^3 + 27^4 (k <= 4)

function encodeRoot(cluster) {
  const chars = [...cluster];
  if (chars.length > 4) {
    throw unsupported(`root cluster "${cluster}" is longer than 4 consonants`);
  }
  let acc = 0;
  for (const ch of chars) {
    const digit = ROOT_DIGIT.get(ch);
    if (digit === undefined) {
      throw unsupported(`consonant "${ch}" (U+${cp(ch)}) is not in the 27-consonant root inventory`);
    }
    acc = acc * 27 + digit;
  }
  return acc; // 1 <= acc <= 551880
}

function decodeRoot(base) {
  if (base < 1 || base > MAX_ROOT_CODE) {
    throw unsupported(`root code ${base} is outside 1..${MAX_ROOT_CODE} (clusters of 1..4 consonants)`);
  }
  let n = base;
  const out = [];
  while (n > 0) {
    const digit = ((n - 1) % 27) + 1; // 1..27
    out.unshift(ROOT_CONSONANTS[digit - 1]);
    n = Math.floor((n - 1) / 27);
  }
  return out.join(""); // 1..4 consonants, guaranteed by the range check
}

function cp(ch) {
  return ch.codePointAt(0).toString(16).toUpperCase().padStart(4, "0");
}

// --------------------------------------------------------------------------
// from_latin (§1 preprocessing, §3 segmentation, §4-§6 tables and mapping).
// --------------------------------------------------------------------------

/**
 * Romanized New Ithkuil text -> canonical, deep-frozen Coord.
 * Rejects everything outside profile core-v1 with code `unsupported`.
 * @param {string} text
 */
export function fromLatin(text) {
  if (typeof text !== "string") {
    throw new IthkuilError("invalid_structure", `romanized input must be a string, got ${typeof text}`);
  }
  // §1: trim -> NFC -> lowercase, in this exact order.
  const word = text.trim().normalize("NFC").toLowerCase();
  if (word.length === 0) throw unsupported("empty word");

  // §3: maximal same-class runs; anything outside the inventories rejects.
  const runs = [];
  for (const ch of word) {
    let cls;
    if (VOWEL_SET.has(ch)) cls = "V";
    else if (SEGMENT_CONSONANTS.has(ch)) cls = "C";
    else throw unsupported(`character "${ch}" (U+${cp(ch)}) is outside the core-v1 inventories`);
    const last = runs[runs.length - 1];
    if (last !== undefined && last.cls === cls) last.text += ch;
    else runs.push({ cls, text: ch });
  }
  // Maximal runs alternate by construction: five runs starting with V is
  // exactly the shape V C V C V.
  if (runs.length !== 5 || runs[0].cls !== "V") {
    throw unsupported(
      `word shape must be Vv Cr Vr Ca Vc (five alternating runs, vowel first); got ${runs.length} run(s)` +
        ` starting with ${runs[0].cls === "V" ? "a vowel" : "a consonant"}`,
    );
  }
  const [vv, cr, vr, ca, vc] = runs.map((r) => r.text);

  // §4.1 Vv — one character, a key of the Vv table.
  const vvRow = VV.get(vv);
  if (vvRow === undefined) throw unsupported(`Vv "${vv}" is not a stem/version vowel of the profile`);
  const [stem, version] = vvRow;

  // §5 Cr — 1..4 root-inventory consonants, bijective base-27.
  const base = encodeRoot(cr);

  // §4.2 Vr — one character, a key of the Vr table.
  const vrRow = VR.get(vr);
  if (vrRow === undefined) throw unsupported(`Vr "${vr}" is not a function/specification vowel of the profile`);
  const [fn, spec] = vrRow;

  // §4.3 Ca — one of l/r/w/y.
  const perspective = CA.get(ca);
  if (perspective === undefined) throw unsupported(`Ca "${ca}" is not a default Ca form (l, r, w, y)`);

  // §4.4 Vc — the whole vowel run must be a Vc form (incl. the digraph "ëi").
  const caseIndex = VC.get(vc);
  if (caseIndex === undefined) throw unsupported(`Vc "${vc}" is not a case vowel form of the profile`);

  // §6: one glyph, three sockets 0/1/2, empty diacritics and child sockets.
  return validate({
    version: 1,
    glyphs: [
      {
        characterClass: 0,
        base,
        orientation: stem,
        sockets: [
          { id: 0, modifier: { shape: spec, orientation: fn + 2 * version, diacritics: [], sockets: [] } },
          { id: 1, modifier: { shape: perspective, orientation: 0, diacritics: [], sockets: [] } },
          { id: 2, modifier: { shape: caseIndex, orientation: 0, diacritics: [], sockets: [] } },
        ],
      },
    ],
  });
}

// --------------------------------------------------------------------------
// to_latin (§7 canonical spelling).
// --------------------------------------------------------------------------

/**
 * Canonical Coord -> canonical spelling (trimmed, NFC, lowercase).
 * Accepts EXACTLY coordinates of the §6/§7 shape; everything else is
 * `unsupported`. Native input is canonicalized first (sockets sorted,
 * empties dropped) per SDK-INTERFACE.md.
 * @returns {string}
 */
export function toLatin(coord) {
  const word = canonicalize(coord);
  if (word.version !== 1) {
    throw unsupported(`romanization profile core-v1 is defined for schema version 1, got ${word.version}`);
  }
  if (word.glyphs.length !== 1) {
    throw unsupported(`core-v1 words have exactly one glyph, got ${word.glyphs.length}`);
  }
  const g = word.glyphs[0];
  if (g.characterClass !== 0) {
    throw unsupported(`core-v1 glyphs have character class 0 (formative), got ${g.characterClass}`);
  }
  if (g.base < 1 || g.base > MAX_ROOT_CODE) {
    throw unsupported(`root code ${g.base} is outside 1..${MAX_ROOT_CODE}`);
  }
  const stem = g.orientation; // 0..3 guaranteed by canonicalize
  if (g.sockets.length !== 3 || g.sockets[0].id !== 0 || g.sockets[1].id !== 1 || g.sockets[2].id !== 2) {
    throw unsupported("core-v1 glyphs carry exactly the three sockets 0, 1, 2");
  }
  const [m0, m1, m2] = g.sockets.map((s) => s.modifier);
  for (const m of [m0, m1, m2]) {
    if (m.diacritics.length !== 0 || m.sockets.length !== 0) {
      throw unsupported("core-v1 modifiers have no diacritics and no child sockets");
    }
  }
  if (m0.shape > 3) throw unsupported(`specification (socket 0 shape) must be 0..3, got ${m0.shape}`);
  if (m1.shape > 3 || m1.orientation !== 0) {
    throw unsupported("perspective modifier (socket 1) must have shape 0..3 and orientation 0");
  }
  if (m2.shape > 8 || m2.orientation !== 0) {
    throw unsupported("case modifier (socket 2) must have shape 0..8 and orientation 0");
  }

  const fnVer = m0.orientation; // 0..3 guaranteed by canonicalize
  const version = Math.floor(fnVer / 2);
  const fn = fnVer % 2;

  const vv = VV_INVERSE[stem][version];
  const cr = decodeRoot(g.base);
  const vr = VR_INVERSE[fn][m0.shape];
  const ca = CA_INVERSE[m1.shape];
  const vc = VC_INVERSE[m2.shape];
  return vv + cr + vr + ca + vc; // all-lowercase, NFC, no separators
}
