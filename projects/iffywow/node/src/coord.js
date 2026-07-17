/**
 * Canonical coordinate tuple — the language-native `Coord` value for Node.
 *
 * Mirrors `web/src/coordinate.js` and `python/ithkuil/coord.py`
 * (CODEC.md §2, schema v1). Canonical form (deep-frozen plain objects):
 *
 *   word     = { version, glyphs: [glyph, ...] }
 *   glyph    = { characterClass, base, orientation, sockets: [socket, ...] }
 *   socket   = { id, modifier }               // a socket ALWAYS carries a modifier
 *   modifier = { shape, orientation, diacritics: [nat, ...], sockets: [socket, ...] }
 *
 * Canonical-form invariants:
 *   - version >= 1; orientation in 0..3; socket id in 0..7 (schema v1);
 *   - sockets sorted strictly ascending by id (duplicates always an error);
 *   - EMPTY SOCKETS ARE OMITTED — there is no "empty" socket value in the
 *     canonical form. `[id, null]` empties exist only at the wire boundary
 *     (see wire.js) and `modifier: null` empties only at the lenient
 *     language-native boundary (`canonicalize`); both are dropped.
 *
 * `validate` is STRICT (canonical shape only); `canonicalize` is LENIENT but
 * canonicalizing (sorts sockets, drops empties, defaults missing collection
 * fields to []). Both return fresh, deep-frozen coords — they never mutate
 * or alias the input.
 */

import { IthkuilError, show } from "./errors.js";

export const MAX_SOCKET_ID = 7;
export const MAX_ORIENTATION = 3;

function fail(code, msg, path) {
  throw new IthkuilError(code, `invalid coordinate at ${path}: ${msg}`);
}

function nat(v, path) {
  if (typeof v !== "number" || !Number.isSafeInteger(v) || v < 0) {
    fail("invalid_structure", `expected non-negative integer, got ${show(v)}`, path);
  }
  return v === 0 ? 0 : v; // normalize -0 -> 0
}

function orient(v, path) {
  const n = nat(v, path);
  if (n > MAX_ORIENTATION) {
    fail("invalid_orientation", `orientation must be 0..${MAX_ORIENTATION}, got ${n}`, path);
  }
  return n;
}

function isPlainObjectLike(v) {
  return v !== null && typeof v === "object" && !Array.isArray(v);
}

function parseWord(data, lenient) {
  if (!isPlainObjectLike(data)) {
    fail("invalid_structure", `expected a coord object {version, glyphs}, got ${show(data)}`, "$");
  }
  const version = data.version;
  if (typeof version !== "number" || !Number.isSafeInteger(version) || version < 1) {
    fail("invalid_version", `schema version must be a positive integer, got ${show(version)}`, "$.version");
  }
  let glyphs = data.glyphs;
  if (glyphs === undefined && lenient) glyphs = [];
  if (!Array.isArray(glyphs)) fail("invalid_structure", "glyphs must be an array", "$.glyphs");
  const parsed = glyphs.map((g, i) => parseGlyph(g, lenient, `$.glyphs[${i}]`));
  return Object.freeze({ version, glyphs: Object.freeze(parsed) });
}

function parseGlyph(g, lenient, path) {
  if (!isPlainObjectLike(g)) {
    fail("invalid_structure", "expected a glyph object {characterClass, base, orientation, sockets}", path);
  }
  return Object.freeze({
    characterClass: nat(g.characterClass, `${path}.characterClass`),
    base: nat(g.base, `${path}.base`),
    orientation: orient(g.orientation, `${path}.orientation`),
    sockets: parseSockets(g.sockets, lenient, `${path}.sockets`),
  });
}

function parseSockets(list, lenient, path) {
  if (list === undefined && lenient) list = [];
  if (!Array.isArray(list)) fail("invalid_structure", "sockets must be an array", path);
  const seen = new Set();
  const entries = [];
  let prev = -1;
  let sorted = true;
  for (let i = 0; i < list.length; i++) {
    const s = list[i];
    const p = `${path}[${i}]`;
    if (!isPlainObjectLike(s)) {
      fail("invalid_structure", "expected a socket object {id, modifier}", p);
    }
    const id = nat(s.id, `${p}.id`);
    if (id > MAX_SOCKET_ID) {
      fail("invalid_socket_id", `socket id must be 0..${MAX_SOCKET_ID} in schema v1, got ${id}`, `${p}.id`);
    }
    if (seen.has(id)) fail("duplicate_socket", `duplicate socket ${id}`, p); // never repaired
    seen.add(id);
    if (id <= prev) sorted = false;
    prev = id;
    const rawModifier = s.modifier;
    if (rawModifier === null || rawModifier === undefined) {
      if (!lenient) {
        fail(
          "invalid_structure",
          "empty sockets are omitted from the canonical form (socket modifier must be present)",
          p,
        );
      }
      entries.push([id, null]); // lenient: dropped below
    } else {
      entries.push([id, parseModifier(rawModifier, lenient, `${p}.modifier`)]);
    }
  }
  if (!sorted) {
    if (!lenient) fail("unsorted_sockets", "sockets must be sorted strictly ascending by id", path);
    entries.sort((a, b) => a[0] - b[0]); // canonical ordering
  }
  const sockets = entries
    .filter(([, modifier]) => modifier !== null) // empties omitted
    .map(([id, modifier]) => Object.freeze({ id, modifier }));
  return Object.freeze(sockets);
}

function parseModifier(m, lenient, path) {
  if (!isPlainObjectLike(m)) {
    fail("invalid_structure", "expected a modifier object {shape, orientation, diacritics, sockets}", path);
  }
  let diacritics = m.diacritics;
  if (diacritics === undefined && lenient) diacritics = [];
  if (!Array.isArray(diacritics)) fail("invalid_structure", "diacritics must be an array", `${path}.diacritics`);
  return Object.freeze({
    shape: nat(m.shape, `${path}.shape`),
    orientation: orient(m.orientation, `${path}.orientation`),
    diacritics: Object.freeze(diacritics.map((d, i) => nat(d, `${path}.diacritics[${i}]`))),
    sockets: parseSockets(m.sockets, lenient, `${path}.sockets`),
  });
}

/**
 * STRICT structural check of a language-native coord value.
 * Input must already be canonical (sorted sockets, no empties).
 * Returns a fresh, deep-frozen canonical Coord.
 */
export function validate(data) {
  return parseWord(data, false);
}

/**
 * LENIENT repair + validate of a language-native coord value: sorts
 * sockets, drops `modifier: null`/missing-modifier empties, defaults
 * missing `glyphs`/`diacritics`/`sockets` collections to []. Duplicate
 * sockets are still an error — never repaired.
 * Returns a fresh, deep-frozen canonical Coord.
 */
export function canonicalize(data) {
  return parseWord(data, true);
}
