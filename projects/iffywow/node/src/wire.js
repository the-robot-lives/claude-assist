/**
 * Wire form — JSON tagged arrays (order-preserving; never free-form objects).
 * Mirrors `web/src/coordinate.js` (same acceptance/rejection behavior, with
 * registry error codes) and CODEC.md §2:
 *
 *   word      := ["ithkuil-word", version, [glyph, ...]]
 *   glyph     := ["glyph", character_class, base, orientation, [socket, ...]]
 *   socket    := [socket_id, null | modifier]
 *   modifier  := ["modifier", shape, orientation, [diacritic_id, ...], [socket, ...]]
 *
 * `fromWire` is LENIENT-canonicalizing: unsorted sockets are sorted, empty
 * sockets (`[id, null]`) are accepted on input and dropped, duplicate socket
 * ids are always an error. `toWire` emits the canonical form: sockets
 * sorted, empties absent — one meaning, one representation.
 */

import { IthkuilError, show } from "./errors.js";
import { validate, canonicalize, MAX_SOCKET_ID, MAX_ORIENTATION } from "./coord.js";

export const WORD_TAG = "ithkuil-word";
export const GLYPH_TAG = "glyph";
export const MODIFIER_TAG = "modifier";

function fail(code, msg, path) {
  throw new IthkuilError(code, `invalid coordinate at ${path}: ${msg}`);
}

function nat(v, path) {
  if (typeof v !== "number" || !Number.isSafeInteger(v) || v < 0) {
    fail("invalid_structure", "expected non-negative integer", path);
  }
  return v === 0 ? 0 : v; // normalize -0 -> 0
}

function orient(v, path) {
  const n = nat(v, path);
  if (n > MAX_ORIENTATION) fail("invalid_orientation", `orientation must be 0..${MAX_ORIENTATION}`, path);
  return n;
}

/**
 * Parse a wire coordinate (tagged arrays, or a JSON text containing them)
 * into a canonical, deep-frozen Coord.
 */
export function fromWire(input) {
  let value = input;
  if (typeof value === "string") {
    value = parseJson(value); // single level of JSON decoding, as in web/
  }
  return parseWireValue(value);
}

/** Canonical Coord (or lenient native coord) -> canonical wire tagged arrays. */
export function toWire(coord) {
  const word = canonicalize(coord);
  return [WORD_TAG, word.version, word.glyphs.map(glyphWire)];
}

/** Canonical wire JSON text. Matches `JSON.stringify` of `toWire(coord)`. */
export function toWireJson(coord) {
  return JSON.stringify(toWire(coord));
}

/** Parse wire JSON text into a canonical, deep-frozen Coord. */
export function fromWireJson(text) {
  if (typeof text !== "string") {
    throw new IthkuilError("invalid_structure", `expected wire JSON text, got ${show(text)}`);
  }
  return parseWireValue(parseJson(text));
}

// --------------------------------------------------------------------------
// Internals.
// --------------------------------------------------------------------------

function parseJson(text) {
  try {
    return JSON.parse(text);
  } catch (e) {
    throw new IthkuilError("invalid_structure", `invalid coordinate: not JSON (${e.message})`);
  }
}

function parseWireValue(value) {
  if (!Array.isArray(value) || value.length !== 3 || value[0] !== WORD_TAG) {
    fail("invalid_structure", `expected ["${WORD_TAG}", version, glyphs]`, "$");
  }
  const version = value[1];
  if (typeof version !== "number" || !Number.isSafeInteger(version) || version < 1) {
    fail("invalid_version", "schema version must be a positive integer", "$[1]");
  }
  if (!Array.isArray(value[2])) fail("invalid_structure", "glyph list must be an array", "$[2]");
  const glyphs = value[2].map((g, i) => parseGlyph(g, `$[2][${i}]`));
  return validate({ version, glyphs }); // already canonical here; validate deep-freezes
}

function parseGlyph(g, path) {
  if (!Array.isArray(g) || g.length !== 5 || g[0] !== GLYPH_TAG) {
    fail("invalid_structure", `expected ["${GLYPH_TAG}", class, base, orientation, sockets]`, path);
  }
  return {
    characterClass: nat(g[1], `${path}[1]`),
    base: nat(g[2], `${path}[2]`),
    orientation: orient(g[3], `${path}[3]`),
    sockets: parseSockets(g[4], `${path}[4]`),
  };
}

function parseSockets(list, path) {
  if (!Array.isArray(list)) fail("invalid_structure", "sockets must be an array", path);
  const seen = new Set();
  const parsed = list.map((s, i) => {
    const p = `${path}[${i}]`;
    if (!Array.isArray(s) || s.length !== 2) fail("invalid_structure", "expected [socket_id, null | modifier]", p);
    const id = nat(s[0], `${p}[0]`);
    if (id > MAX_SOCKET_ID) {
      fail("invalid_socket_id", `socket id must be 0..${MAX_SOCKET_ID} in schema v1`, `${p}[0]`);
    }
    if (seen.has(id)) fail("duplicate_socket", `duplicate socket ${id}`, p); // even when one side is null
    seen.add(id);
    return [id, s[1] === null ? null : parseModifier(s[1], `${p}[1]`)];
  });
  parsed.sort((a, b) => a[0] - b[0]); // canonical ordering
  return parsed
    .filter(([, modifier]) => modifier !== null) // empties omitted
    .map(([id, modifier]) => ({ id, modifier }));
}

function parseModifier(m, path) {
  if (!Array.isArray(m) || m.length !== 5 || m[0] !== MODIFIER_TAG) {
    fail("invalid_structure", `expected ["${MODIFIER_TAG}", shape, orientation, diacritics, sockets]`, path);
  }
  if (!Array.isArray(m[3])) fail("invalid_structure", "diacritics must be an array", `${path}[3]`);
  return {
    shape: nat(m[1], `${path}[1]`),
    orientation: orient(m[2], `${path}[2]`),
    diacritics: m[3].map((d, i) => nat(d, `${path}[3][${i}]`)),
    sockets: parseSockets(m[4], `${path}[4]`),
  };
}

function glyphWire(g) {
  return [GLYPH_TAG, g.characterClass, g.base, g.orientation, g.sockets.map(socketWire)];
}

function socketWire(s) {
  return [s.id, modifierWire(s.modifier)];
}

function modifierWire(m) {
  return [MODIFIER_TAG, m.shape, m.orientation, [...m.diacritics], m.sockets.map(socketWire)];
}
