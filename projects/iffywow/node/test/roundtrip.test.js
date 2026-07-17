/**
 * Seeded property tests — the SDK-INTERFACE.md §5 laws over ~300 random
 * valid coordinates (deterministic LCG; no dependencies).
 *
 *   fromInteger(toInteger(c))               == c
 *   fromIntegerString(toIntegerString(c))   == c
 *   fromBytes(toBytes(c))                   == c
 *   fromWire(toWire(c))                     == c
 *   fromWireJson(toWireJson(c))             == c
 *   fromLatin(toLatin(c))                   == c        (for c in profile)
 *   toLatin(fromLatin(w))                   == canonicalize(w)
 */

import { test } from "node:test";
import assert from "node:assert/strict";

import {
  IthkuilError,
  validate,
  canonicalize,
  toInteger,
  fromInteger,
  toIntegerString,
  fromIntegerString,
  toBytes,
  fromBytes,
  toWire,
  fromWire,
  toWireJson,
  fromWireJson,
  fromLatin,
  toLatin,
  MAX_ROOT_CODE,
} from "../src/index.js";

// ---------------------------------------------------------------------------
// Deterministic PRNG (32-bit LCG) + generators.
// ---------------------------------------------------------------------------

function makeRng(seed) {
  let s = seed >>> 0;
  return () => {
    s = (Math.imul(1664525, s) + 1013904223) >>> 0;
    return s / 4294967296; // [0, 1)
  };
}

const ri = (rnd, lo, hi) => lo + Math.floor(rnd() * (hi - lo + 1));

function shuffled(rnd, arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rnd() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

const ALL_IDS = [0, 1, 2, 3, 4, 5, 6, 7];

function genSockets(rnd, depth) {
  const count = ri(rnd, 0, depth === 0 ? 4 : 2);
  const ids = shuffled(rnd, ALL_IDS)
    .slice(0, count)
    .sort((a, b) => a - b); // canonical: strictly ascending
  return ids.map((id) => ({ id, modifier: genModifier(rnd, depth) }));
}

function genModifier(rnd, depth) {
  return {
    shape: ri(rnd, 0, 9),
    orientation: ri(rnd, 0, 3),
    diacritics: Array.from({ length: ri(rnd, 0, 3) }, () => ri(rnd, 0, 40)),
    sockets: depth >= 2 ? [] : genSockets(rnd, depth + 1),
  };
}

function genWord(rnd) {
  return {
    version: rnd() < 0.8 ? 1 : ri(rnd, 1, 999),
    glyphs: Array.from({ length: ri(rnd, 0, 3) }, () => ({
      characterClass: ri(rnd, 0, 4),
      base: ri(rnd, 0, 1_000_000),
      orientation: ri(rnd, 0, 3),
      sockets: genSockets(rnd, 0),
    })),
  };
}

/** Random in-profile (romanization core-v1) coordinate. */
function genProfileWord(rnd) {
  const stem = ri(rnd, 0, 3);
  const version = ri(rnd, 0, 1);
  const fn = ri(rnd, 0, 1);
  const spec = ri(rnd, 0, 3);
  const perspective = ri(rnd, 0, 3);
  const caseIndex = ri(rnd, 0, 8);
  const base = ri(rnd, 1, MAX_ROOT_CODE);
  return {
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
  };
}

// Lenient-input scramblers: reverse socket order and add empty sockets at
// unused ids. Canonicalization must recover the original coordinate.

function scrambleNativeSockets(rnd, sockets) {
  const out = sockets.map((s) => ({
    id: s.id,
    modifier: {
      shape: s.modifier.shape,
      orientation: s.modifier.orientation,
      diacritics: [...s.modifier.diacritics],
      sockets: scrambleNativeSockets(rnd, s.modifier.sockets),
    },
  }));
  const used = new Set(sockets.map((s) => s.id));
  const free = ALL_IDS.filter((id) => !used.has(id));
  if (free.length > 0 && rnd() < 0.7) {
    out.push({ id: free[ri(rnd, 0, free.length - 1)], modifier: null }); // empty: dropped
  }
  out.reverse(); // unsorted: repaired
  return out;
}

function scrambleNative(rnd, word) {
  return {
    version: word.version,
    glyphs: word.glyphs.map((g) => ({
      characterClass: g.characterClass,
      base: g.base,
      orientation: g.orientation,
      sockets: scrambleNativeSockets(rnd, g.sockets),
    })),
  };
}

function scrambleWireSockets(rnd, list) {
  const out = list.map(([id, m]) => [
    id,
    m === null ? null : [m[0], m[1], m[2], [...m[3]], scrambleWireSockets(rnd, m[4])],
  ]);
  const used = new Set(list.map(([id]) => id));
  const free = ALL_IDS.filter((id) => !used.has(id));
  if (free.length > 0 && rnd() < 0.7) {
    out.push([free[ri(rnd, 0, free.length - 1)], null]); // [id, null] empty: dropped
  }
  out.reverse();
  return out;
}

function scrambleWire(rnd, wire) {
  return [
    wire[0],
    wire[1],
    wire[2].map((g) => [g[0], g[1], g[2], g[3], scrambleWireSockets(rnd, g[4])]),
  ];
}

// ---------------------------------------------------------------------------
// §5 laws over random valid coordinates.
// ---------------------------------------------------------------------------

test("laws: integer/bytes/wire round-trips over 300 seeded random coords", () => {
  const rnd = makeRng(0xc0ffee);
  for (let i = 0; i < 300; i++) {
    const raw = genWord(rnd);
    const c = validate(raw);

    assert.deepEqual(fromInteger(toInteger(c)), c, `fromInteger(toInteger(c)) != c at i=${i}`);
    assert.deepEqual(fromIntegerString(toIntegerString(c)), c, `integer-string law failed at i=${i}`);
    assert.deepEqual(fromBytes(toBytes(c)), c, `fromBytes(toBytes(c)) != c at i=${i}`);
    assert.deepEqual(fromWire(toWire(c)), c, `fromWire(toWire(c)) != c at i=${i}`);
    assert.deepEqual(fromWireJson(toWireJson(c)), c, `wire JSON law failed at i=${i}`);

    // validate/canonicalize agree on canonical input
    assert.deepEqual(canonicalize(raw), c, `canonicalize(raw) != validate(raw) at i=${i}`);

    // integer string is unsigned decimal
    assert.match(toIntegerString(c), /^[0-9]+$/);
    assert.equal(typeof toInteger(c), "bigint");
  }
});

test("laws: results are deep-frozen and detached from input", () => {
  const rnd = makeRng(0xf00d);
  for (let i = 0; i < 20; i++) {
    const raw = genWord(rnd);
    const c = validate(raw);
    assert.ok(Object.isFrozen(c));
    assert.ok(Object.isFrozen(c.glyphs));
    for (const g of c.glyphs) {
      assert.ok(Object.isFrozen(g));
      assert.ok(Object.isFrozen(g.sockets));
      for (const s of g.sockets) {
        assert.ok(Object.isFrozen(s));
        assert.ok(Object.isFrozen(s.modifier));
        assert.ok(Object.isFrozen(s.modifier.diacritics));
        assert.ok(Object.isFrozen(s.modifier.sockets));
      }
    }
    // mutating the input after validation must not affect the result
    const before = toIntegerString(c);
    raw.version = 999;
    if (raw.glyphs.length > 0) raw.glyphs[0].base = 123456;
    assert.equal(toIntegerString(c), before);
  }
});

test("leniency: fromWire sorts unsorted sockets and drops [id, null] empties", () => {
  const rnd = makeRng(0x5eed);
  for (let i = 0; i < 60; i++) {
    const c = validate(genWord(rnd));
    assert.deepEqual(fromWire(scrambleWire(rnd, toWire(c))), c, `wire leniency failed at i=${i}`);
  }
});

test("leniency: canonicalize repairs native input; validate rejects it", () => {
  const rnd = makeRng(0xbead);
  for (let i = 0; i < 60; i++) {
    const c = validate(genWord(rnd));
    const messy = scrambleNative(rnd, c);
    assert.deepEqual(canonicalize(messy), c, `native leniency failed at i=${i}`);

    // strict validate must reject the same input when it is actually messy
    const hasEmpty = JSON.stringify(messy).includes('"modifier":null');
    const hasUnsorted = messy.glyphs.some(function unsortedAnywhere(g) {
      const check = (sockets) =>
        sockets.some((s, j) => (j > 0 && sockets[j - 1].id > s.id) || (s.modifier && check(s.modifier.sockets)));
      return check(g.sockets);
    });
    if (hasEmpty || hasUnsorted) {
      assert.throws(
        () => validate(messy),
        (err) =>
          err instanceof IthkuilError && (err.code === "unsorted_sockets" || err.code === "invalid_structure"),
        `validate should reject messy input at i=${i}`,
      );
    }
  }
});

test("duplicates are always an error, never repaired", () => {
  const wireDup = [
    "ithkuil-word",
    1,
    [["glyph", 0, 0, 0, [[1, ["modifier", 0, 0, [], []]], [1, null]]]],
  ];
  assert.throws(() => fromWire(wireDup), (e) => e instanceof IthkuilError && e.code === "duplicate_socket");

  const nativeDup = {
    version: 1,
    glyphs: [
      {
        characterClass: 0,
        base: 0,
        orientation: 0,
        sockets: [
          { id: 2, modifier: { shape: 0, orientation: 0, diacritics: [], sockets: [] } },
          { id: 2, modifier: null },
        ],
      },
    ],
  };
  assert.throws(() => canonicalize(nativeDup), (e) => e instanceof IthkuilError && e.code === "duplicate_socket");
});

// ---------------------------------------------------------------------------
// Romanization laws (profile core-v1).
// ---------------------------------------------------------------------------

test("laws: fromLatin(toLatin(c)) == c over 100 seeded in-profile coords", () => {
  const rnd = makeRng(0x17ec1); // arbitrary fixed seed
  for (let i = 0; i < 100; i++) {
    const c = validate(genProfileWord(rnd));
    const w = toLatin(c);

    assert.deepEqual(fromLatin(w), c, `fromLatin(toLatin(c)) != c at i=${i} (latin ${JSON.stringify(w)})`);
    assert.equal(toLatin(fromLatin(w)), w, `canonical spelling not a fixed point at i=${i}`);

    // to_latin(from_latin(w)) == canonicalize(w): trim/case/NFC variants
    assert.deepEqual(fromLatin(`  ${w} `), c, `trim preprocessing failed at i=${i}`);
    assert.deepEqual(fromLatin(w.toUpperCase()), c, `lowercase preprocessing failed at i=${i}`);
    assert.deepEqual(fromLatin(w.normalize("NFD")), c, `NFC preprocessing failed at i=${i}`);
    assert.equal(toLatin(fromLatin(`  ${w.toUpperCase()} `)), w);
  }
});

test("romanization: out-of-profile coordinates are rejected with `unsupported`", () => {
  const unsupportedCases = [
    { version: 1, glyphs: [] }, // zero glyphs
    { version: 2, glyphs: [] }, // wrong schema version for the profile
    {
      version: 1,
      glyphs: [
        { characterClass: 1, base: 1, orientation: 0, sockets: [] }, // wrong class + socket layout
      ],
    },
    {
      version: 1,
      glyphs: [
        {
          characterClass: 0,
          base: 0, // root code 0 is not a bijective base-27 numeral
          orientation: 0,
          sockets: [
            { id: 0, modifier: { shape: 0, orientation: 0, diacritics: [], sockets: [] } },
            { id: 1, modifier: { shape: 0, orientation: 0, diacritics: [], sockets: [] } },
            { id: 2, modifier: { shape: 0, orientation: 0, diacritics: [], sockets: [] } },
          ],
        },
      ],
    },
  ];
  for (const [i, coord] of unsupportedCases.entries()) {
    assert.throws(
      () => toLatin(coord),
      (e) => e instanceof IthkuilError && e.code === "unsupported",
      `case ${i} should be unsupported`,
    );
  }
  // case index 9 (socket 2 shape out of range for the profile)
  const c9 = genProfileWord(makeRng(9));
  c9.glyphs[0].sockets[2].modifier.shape = 9;
  assert.throws(() => toLatin(c9), (e) => e instanceof IthkuilError && e.code === "unsupported");
});

// ---------------------------------------------------------------------------
// Worked example and edge cases (CODEC.md §4).
// ---------------------------------------------------------------------------

test("worked example: empty word ranks to 8606843649", () => {
  const empty = validate({ version: 1, glyphs: [] });
  assert.equal(toIntegerString(empty), "8606843649");
  assert.deepEqual(fromIntegerString("8606843649"), empty);
  assert.deepEqual(fromInteger(8606843649n), empty);
  assert.equal(toWireJson(empty), '["ithkuil-word",1,[]]');
  assert.deepEqual(fromWireJson('["ithkuil-word",1,[]]'), empty);
});

test("edge cases: fromInteger strictness", () => {
  // 0 unranks to the empty byte string, which cannot hold a root term
  assert.throws(() => fromInteger(0n), (e) => e instanceof IthkuilError && e.code === "truncated");
  assert.throws(() => fromInteger(-1n), (e) => e instanceof IthkuilError && e.code === "invalid_natural_number");
  assert.throws(() => fromInteger(1.5), (e) => e instanceof IthkuilError && e.code === "invalid_natural_number");
  assert.throws(
    () => fromIntegerString("+5"),
    (e) => e instanceof IthkuilError && e.code === "invalid_natural_number",
  );
  // non-ASCII digits are rejected
  assert.throws(
    () => fromIntegerString("١٢"),
    (e) => e instanceof IthkuilError && e.code === "invalid_natural_number",
  );
});
