/**
 * iffywow/web — coordinate wire-form parsing & canonicalization.
 *
 * Wire form is JSON tagged arrays (order-preserving; never free-form objects):
 *
 *   word      := ["ithkuil-word", version, [glyph, ...]]
 *   glyph     := ["glyph", character_class, base, orientation, [socket, ...]]
 *   socket    := [socket_id, null | modifier]
 *   modifier  := ["modifier", shape, orientation, [diacritic_id, ...], [socket, ...]]
 *
 * This module validates and canonicalizes: sockets sorted ascending, duplicate
 * sockets rejected, and EMPTY sockets ([id, null]) accepted on input but
 * omitted from the canonical form (see ../../CODEC.md — one meaning, one
 * representation). It performs NO Ithkuil semantics — no romanization, no
 * enum ranking, no integer arithmetic. Those live in the Elixir/Python codecs.
 */

export const WORD_TAG = "ithkuil-word";
export const GLYPH_TAG = "glyph";
export const MODIFIER_TAG = "modifier";
export const MAX_SOCKET_ID = 7;

function fail(msg, path) {
  throw new Error(`invalid coordinate at ${path}: ${msg}`);
}

function nat(v, path) {
  if (!Number.isInteger(v) || v < 0) fail("expected non-negative integer", path);
  return v;
}

function orient(v, path) {
  const n = nat(v, path);
  if (n > 3) fail("orientation must be 0..3", path);
  return n;
}

/**
 * Parse a wire coordinate (array or JSON string) into a normalized word plus
 * its canonical wire form.
 * @param {unknown} input
 * @returns {{word: object, wire: unknown[]}}
 */
export function parseCoordinate(input) {
  let value = input;
  if (typeof value === "string") {
    try {
      value = JSON.parse(value);
    } catch (e) {
      throw new Error(`invalid coordinate: not JSON (${e.message})`);
    }
  }
  if (!Array.isArray(value) || value[0] !== WORD_TAG || value.length !== 3) {
    fail(`expected ["${WORD_TAG}", version, glyphs]`, "$");
  }
  const version = value[1];
  if (!Number.isInteger(version) || version < 1) {
    fail("schema version must be a positive integer", "$[1]");
  }
  if (!Array.isArray(value[2])) fail("glyph list must be an array", "$[2]");
  const glyphs = value[2].map((g, i) => parseGlyph(g, `$[2][${i}]`));
  const word = {version, glyphs};
  return {word, wire: toWire(word)};
}

function parseGlyph(g, path) {
  if (!Array.isArray(g) || g[0] !== GLYPH_TAG || g.length !== 5) {
    fail(`expected ["${GLYPH_TAG}", class, base, orientation, sockets]`, path);
  }
  return {
    characterClass: nat(g[1], `${path}[1]`),
    base: nat(g[2], `${path}[2]`),
    orientation: orient(g[3], `${path}[3]`),
    sockets: parseSockets(g[4], `${path}[4]`),
  };
}

function parseSockets(list, path) {
  if (!Array.isArray(list)) fail("sockets must be an array", path);
  const seen = new Set();
  const sockets = list.map((s, i) => {
    const p = `${path}[${i}]`;
    if (!Array.isArray(s) || s.length !== 2) fail("expected [socket_id, null | modifier]", p);
    const id = nat(s[0], `${p}[0]`);
    if (id > MAX_SOCKET_ID) fail(`socket id must be 0..${MAX_SOCKET_ID} in schema v1`, `${p}[0]`);
    if (seen.has(id)) fail(`duplicate socket ${id}`, p);
    seen.add(id);
    return {
      socket: id,
      modifier: s[1] === null ? null : parseModifier(s[1], `${p}[1]`),
    };
  });
  sockets.sort((a, b) => a.socket - b.socket); // canonical ordering
  return sockets.filter((s) => s.modifier !== null); // empties omitted
}

function parseModifier(m, path) {
  if (!Array.isArray(m) || m[0] !== MODIFIER_TAG || m.length !== 5) {
    fail(`expected ["${MODIFIER_TAG}", shape, orientation, diacritics, sockets]`, path);
  }
  if (!Array.isArray(m[3])) fail("diacritics must be an array", `${path}[3]`);
  return {
    shape: nat(m[1], `${path}[1]`),
    orientation: orient(m[2], `${path}[2]`),
    diacritics: m[3].map((d, i) => nat(d, `${path}[3][${i}]`)),
    sockets: parseSockets(m[4], `${path}[4]`),
  };
}

/** Normalized word → canonical wire (tagged arrays). */
export function toWire(word) {
  return [WORD_TAG, word.version, word.glyphs.map(glyphWire)];
}

function glyphWire(g) {
  return [GLYPH_TAG, g.characterClass, g.base, g.orientation, g.sockets.map(socketWire)];
}

function socketWire(s) {
  return [s.socket, s.modifier ? modifierWire(s.modifier) : null];
}

function modifierWire(m) {
  return [MODIFIER_TAG, m.shape, m.orientation, [...m.diacritics], m.sockets.map(socketWire)];
}
