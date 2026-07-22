/**
 * codec-v1: LEB128 varints, term algebra ser/de, integer ranking.
 * Normative: ../../CODEC.md; mirrors python/ithkuil/codec.py.
 *
 * Term algebra (tag byte, then payload):
 *
 *   0x00  NAT n     minimal unsigned LEB128 varint of n
 *   0x01  PAIR x y  ser(x) ser(y)
 *   0x02  LIST      varint k, then k serialized elements
 *   0x03  BYTES     varint len, then the raw bytes
 *   0x04  reserved  never emitted in v1; decoders MUST reject
 *
 * JS term representation (small, inspectable):
 *
 *   ["nat", bigint]
 *   ["pair", term, term]
 *   ["list", [term, ...]]
 *   ["bytes", Uint8Array]
 *
 * Integer ranking: with B = ser(word) of byte length m,
 *
 *   S_m  = (256n**BigInt(m) - 1n) / 255n   // number of strings shorter than m
 *   E(t) = S_m + V256(B)                   // V256 = big-endian base-256 value
 *
 * Length intervals are disjoint, so decoding recovers m first (largest m
 * with S_m <= E), then B = E - S_m as exactly m bytes PRESERVING LEADING
 * ZEROS, then parses the term strictly (minimal varints, no reserved or
 * unknown tags, no trailing bytes, canonical word structure).
 *
 * All arithmetic is BigInt end to end. Boundary rule: the integer crosses
 * every language/JSON boundary as an unsigned decimal string
 * (`toIntegerString` / `fromIntegerString`); JSON BigInt is not a thing.
 */

import { IthkuilError, show } from "./errors.js";
import { canonicalize, validate, MAX_ORIENTATION, MAX_SOCKET_ID } from "./coord.js";

export const TAG_NAT = 0x00;
export const TAG_PAIR = 0x01;
export const TAG_LIST = 0x02;
export const TAG_BYTES = 0x03;
export const TAG_RESERVED = 0x04;

const MAX_SAFE = BigInt(Number.MAX_SAFE_INTEGER);

// --------------------------------------------------------------------------
// Helpers.
// --------------------------------------------------------------------------

function toBigNat(v, what) {
  if (typeof v === "bigint") {
    if (v < 0n) throw new IthkuilError("invalid_structure", `${what} must be non-negative, got ${show(v)}`);
    return v;
  }
  if (typeof v === "number" && Number.isSafeInteger(v) && v >= 0) return BigInt(v);
  throw new IthkuilError("invalid_structure", `${what} must be a non-negative integer, got ${show(v)}`);
}

function asBytes(data, what) {
  if (data instanceof Uint8Array) return data;
  if (data instanceof ArrayBuffer) return new Uint8Array(data);
  throw new IthkuilError("invalid_structure", `${what} must be bytes (Uint8Array), got ${show(data)}`);
}

function hexToBytes(hex) {
  if (typeof hex !== "string" || hex.length % 2 !== 0 || /[^0-9a-fA-F]/.test(hex)) {
    throw new IthkuilError("invalid_structure", `expected an even-length hex string, got ${show(hex)}`);
  }
  const out = new Uint8Array(hex.length / 2);
  for (let i = 0; i < out.length; i++) {
    out[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  }
  return out;
}

function bytesToHex(bytes) {
  let out = "";
  for (const b of bytes) out += b.toString(16).padStart(2, "0");
  return out;
}

// --------------------------------------------------------------------------
// Unsigned LEB128 varints (minimal encodings only), over BigInt.
// --------------------------------------------------------------------------

function pushVarint(out, n) {
  let v = n; // bigint >= 0
  for (;;) {
    const group = Number(v & 0x7fn);
    v >>= 7n;
    if (v > 0n) {
      out.push(group | 0x80);
    } else {
      out.push(group);
      return;
    }
  }
}

/**
 * Minimal unsigned LEB128: little-endian 7-bit groups, high bit = continue.
 * `0 -> 00`, `127 -> 7f`, `128 -> 80 01`, `300 -> ac 02`.
 * @param {bigint | number} n
 * @returns {Uint8Array}
 */
export function encodeVarint(n) {
  const out = [];
  pushVarint(out, toBigNat(n, "varint value"));
  return Uint8Array.from(out);
}

/**
 * Decode a varint at `pos`; returns `{ value: bigint, pos }`.
 * Rejects non-minimal encodings: a multi-byte varint whose final (most
 * significant) group is zero has a shorter equivalent, e.g. `80 00` for 0.
 */
function readVarint(data, pos) {
  const start = pos;
  let result = 0n;
  let shift = 0n;
  for (;;) {
    if (pos >= data.length) {
      throw new IthkuilError("truncated", `unexpected end of input inside varint at offset ${start}`);
    }
    const b = data[pos];
    pos += 1;
    result |= BigInt(b & 0x7f) << shift;
    if ((b & 0x80) === 0) {
      if (b === 0 && pos - start > 1) {
        throw new IthkuilError(
          "nonminimal_varint",
          `non-minimal varint at offset ${start}: redundant zero continuation group`,
        );
      }
      return { value: result, pos };
    }
    shift += 7n;
  }
}

// --------------------------------------------------------------------------
// Term serialization / strict deserialization.
// --------------------------------------------------------------------------

function termKind(term) {
  if (!Array.isArray(term) || term.length < 2 || typeof term[0] !== "string") {
    throw new IthkuilError("invalid_structure", `malformed term: ${show(term)}`);
  }
  return term[0];
}

/**
 * `ser(t)`: tag byte followed by payload. Prefix-decodable.
 * @returns {Uint8Array}
 */
export function serializeTerm(term) {
  const out = [];
  writeTerm(out, term);
  return Uint8Array.from(out);
}

function writeTerm(out, term) {
  const kind = termKind(term);
  if (kind === "nat") {
    out.push(TAG_NAT);
    pushVarint(out, toBigNat(term[1], "NAT value"));
    return;
  }
  if (kind === "pair") {
    if (term.length !== 3) throw new IthkuilError("invalid_structure", "pair term must be ['pair', x, y]");
    out.push(TAG_PAIR);
    writeTerm(out, term[1]);
    writeTerm(out, term[2]);
    return;
  }
  if (kind === "list") {
    const items = term[1];
    if (!Array.isArray(items)) throw new IthkuilError("invalid_structure", "list term payload must be an array");
    out.push(TAG_LIST);
    pushVarint(out, BigInt(items.length));
    for (const e of items) writeTerm(out, e);
    return;
  }
  if (kind === "bytes") {
    const b = asBytes(term[1], "bytes term payload");
    out.push(TAG_BYTES);
    pushVarint(out, BigInt(b.length));
    for (const x of b) out.push(x);
    return;
  }
  throw new IthkuilError("invalid_structure", `unknown term kind ${show(kind)}`);
}

/**
 * Strict decode: minimal varints, no reserved/unknown tags, and no trailing
 * bytes after the root term.
 */
export function deserializeTerm(data) {
  const bytes = asBytes(data, "term input");
  const { term, pos } = readTerm(bytes, 0);
  if (pos !== bytes.length) {
    throw new IthkuilError(
      "trailing_bytes",
      `${bytes.length - pos} trailing byte(s) after the root term at offset ${pos}`,
    );
  }
  return term;
}

function readTerm(data, pos) {
  if (pos >= data.length) {
    throw new IthkuilError("truncated", `unexpected end of input: expected tag byte at offset ${pos}`);
  }
  const tag = data[pos];
  pos += 1;
  if (tag === TAG_NAT) {
    const r = readVarint(data, pos);
    return { term: ["nat", r.value], pos: r.pos };
  }
  if (tag === TAG_PAIR) {
    const x = readTerm(data, pos);
    const y = readTerm(data, x.pos);
    return { term: ["pair", x.term, y.term], pos: y.pos };
  }
  if (tag === TAG_LIST) {
    const r = readVarint(data, pos);
    pos = r.pos;
    // Each serialized element occupies at least one byte, so a count larger
    // than the remaining input is necessarily truncated (also guards the loop).
    if (r.value > BigInt(data.length - pos)) {
      throw new IthkuilError("truncated", `list of ${r.value} element(s) truncated at offset ${pos}`);
    }
    const count = Number(r.value);
    const items = [];
    for (let i = 0; i < count; i++) {
      const e = readTerm(data, pos);
      items.push(e.term);
      pos = e.pos;
    }
    return { term: ["list", items], pos };
  }
  if (tag === TAG_BYTES) {
    const r = readVarint(data, pos);
    pos = r.pos;
    if (r.value > BigInt(data.length - pos)) {
      throw new IthkuilError("truncated", `bytes payload of length ${r.value} truncated at offset ${pos}`);
    }
    const len = Number(r.value);
    return { term: ["bytes", data.slice(pos, pos + len)], pos: pos + len };
  }
  if (tag === TAG_RESERVED) {
    throw new IthkuilError("reserved_tag", `reserved tag 0x04 at offset ${pos - 1}`);
  }
  throw new IthkuilError("unknown_tag", `unknown tag 0x${tag.toString(16).padStart(2, "0")} at offset ${pos - 1}`);
}

// --------------------------------------------------------------------------
// Conformance-vector JSON <-> term (["nat", 0], ["bytes", "<hex>"], ...).
// --------------------------------------------------------------------------

export function termFromJson(value) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new IthkuilError("invalid_structure", `malformed term JSON: ${show(value)}`);
  }
  const kind = value[0];
  if (kind === "nat") {
    const n = value[1];
    if (typeof n === "string") {
      if (!/^[0-9]+$/.test(n)) {
        throw new IthkuilError("invalid_structure", `malformed NAT term JSON: ${show(n)}`);
      }
      return ["nat", BigInt(n)];
    }
    return ["nat", toBigNat(n, "NAT term JSON value")];
  }
  if (kind === "pair") return ["pair", termFromJson(value[1]), termFromJson(value[2])];
  if (kind === "list") {
    if (!Array.isArray(value[1])) {
      throw new IthkuilError("invalid_structure", `malformed LIST term JSON: ${show(value[1])}`);
    }
    return ["list", value[1].map(termFromJson)];
  }
  if (kind === "bytes") return ["bytes", hexToBytes(value[1])];
  throw new IthkuilError("invalid_structure", `unknown term kind ${show(kind)}`);
}

export function termToJson(term) {
  const kind = termKind(term);
  if (kind === "nat") {
    const n = toBigNat(term[1], "NAT value");
    return ["nat", n <= MAX_SAFE ? Number(n) : n.toString(10)];
  }
  if (kind === "pair") return ["pair", termToJson(term[1]), termToJson(term[2])];
  if (kind === "list") return ["list", term[1].map(termToJson)];
  if (kind === "bytes") return ["bytes", bytesToHex(asBytes(term[1], "bytes term payload"))];
  throw new IthkuilError("invalid_structure", `unknown term kind ${show(kind)}`);
}

// --------------------------------------------------------------------------
// Byte-string ranking among all finite byte strings (BigInt throughout).
// --------------------------------------------------------------------------

/** `S_m = (256^m - 1) / 255` — byte strings with length < m (exact division). */
export function stringsShorterThan(m) {
  return (256n ** BigInt(m) - 1n) / 255n;
}

/** `E = S_m + V256(B)` for `B = data` of length `m`. @returns {bigint} */
export function rank(data) {
  const bytes = asBytes(data, "rank input");
  let v = 0n;
  for (const b of bytes) v = (v << 8n) | BigInt(b);
  return stringsShorterThan(bytes.length) + v;
}

/**
 * Inverse of `rank`: recover the exact byte string, LEADING ZEROS INCLUDED.
 * Every non-negative integer maps to some byte string.
 * @param {bigint} e
 * @returns {Uint8Array}
 */
export function unrank(e) {
  if (typeof e !== "bigint" || e < 0n) {
    throw new IthkuilError("invalid_natural_number", `expected a non-negative integer, got ${show(e)}`);
  }
  let m = 0;
  let s = 0n; // S_0
  let next = 1n; // S_1;  S_{m+1} = 256*S_m + 1
  while (next <= e) {
    m += 1;
    s = next;
    next = next * 256n + 1n;
  }
  let v = e - s;
  const out = new Uint8Array(m);
  for (let i = m - 1; i >= 0; i--) {
    out[i] = Number(v & 0xffn);
    v >>= 8n;
  }
  return out;
}

// --------------------------------------------------------------------------
// Word <-> term mapping (schema v1, CODEC.md §2).
// --------------------------------------------------------------------------

/** Canonical Coord -> term. Input is canonicalized (lenient native boundary). */
export function wordToTerm(coord) {
  const word = canonicalize(coord);
  return ["pair", ["nat", BigInt(word.version)], ["list", word.glyphs.map(glyphTerm)]];
}

function glyphTerm(g) {
  return [
    "list",
    [
      ["nat", BigInt(g.characterClass)],
      ["nat", BigInt(g.base)],
      ["nat", BigInt(g.orientation)],
      ["list", g.sockets.map(socketTerm)],
    ],
  ];
}

function socketTerm(s) {
  return ["pair", ["nat", BigInt(s.id)], modifierTerm(s.modifier)];
}

function modifierTerm(m) {
  return [
    "list",
    [
      ["nat", BigInt(m.shape)],
      ["nat", BigInt(m.orientation)],
      ["list", m.diacritics.map((d) => ["nat", BigInt(d)])],
      ["list", m.sockets.map(socketTerm)],
    ],
  ];
}

/**
 * STRICT term -> canonical Coord. Enforces the canonical-form rules of
 * CODEC.md §2: version >= 1, orientations 0..3, socket ids 0..7, sockets
 * sorted strictly ascending (duplicates invalid), empty sockets absent by
 * construction (a socket term always carries a modifier).
 */
export function termToWord(term) {
  if (termKind(term) !== "pair" || term.length !== 3) {
    throw new IthkuilError("invalid_structure", "word term must be PAIR(NAT version, LIST glyphs)");
  }
  const version = expectNatNumber(term[1], "word version");
  if (version < 1) {
    throw new IthkuilError("invalid_version", `schema version must be a positive integer, got ${version}`);
  }
  const glyphs = expectList(term[2], "word glyph list").map(termGlyph);
  return validate({ version, glyphs }); // re-checks + deep-freezes
}

function expectNatNumber(term, what) {
  if (termKind(term) !== "nat") {
    throw new IthkuilError("invalid_structure", `${what} must be a NAT term`);
  }
  const n = toBigNat(term[1], what);
  if (n > MAX_SAFE) {
    throw new IthkuilError(
      "invalid_structure",
      `${what} ${n} exceeds Number.MAX_SAFE_INTEGER and cannot be represented in this SDK's coord form`,
    );
  }
  return Number(n);
}

function expectOrientation(term, what) {
  const n = expectNatNumber(term, what);
  if (n > MAX_ORIENTATION) {
    throw new IthkuilError("invalid_orientation", `${what} must be 0..${MAX_ORIENTATION}, got ${n}`);
  }
  return n;
}

function expectList(term, what) {
  if (termKind(term) !== "list") {
    throw new IthkuilError("invalid_structure", `${what} must be a LIST term`);
  }
  return term[1];
}

function termGlyph(term) {
  const items = expectList(term, "glyph");
  if (items.length !== 4) {
    throw new IthkuilError("invalid_structure", "glyph must be LIST[class, base, orientation, sockets]");
  }
  return {
    characterClass: expectNatNumber(items[0], "glyph character class"),
    base: expectNatNumber(items[1], "glyph base"),
    orientation: expectOrientation(items[2], "glyph orientation"),
    sockets: termSockets(items[3]),
  };
}

function termSockets(term) {
  const items = expectList(term, "socket list");
  const sockets = [];
  let prev = -1;
  for (const entry of items) {
    if (termKind(entry) !== "pair" || entry.length !== 3) {
      throw new IthkuilError("invalid_structure", "socket must be PAIR(NAT id, modifier)");
    }
    const id = expectNatNumber(entry[1], "socket id");
    if (id > MAX_SOCKET_ID) {
      throw new IthkuilError("invalid_socket_id", `socket id must be 0..${MAX_SOCKET_ID} in schema v1, got ${id}`);
    }
    if (id === prev) throw new IthkuilError("duplicate_socket", `duplicate socket ${id}`);
    if (id < prev) {
      throw new IthkuilError(
        "unsorted_sockets",
        `sockets must be sorted strictly ascending (socket ${id} after ${prev})`,
      );
    }
    prev = id;
    sockets.push({ id, modifier: termModifier(entry[2]) });
  }
  return sockets;
}

function termModifier(term) {
  const items = expectList(term, "modifier");
  if (items.length !== 4) {
    throw new IthkuilError("invalid_structure", "modifier must be LIST[shape, orientation, diacritics, sockets]");
  }
  return {
    shape: expectNatNumber(items[0], "modifier shape"),
    orientation: expectOrientation(items[1], "modifier orientation"),
    diacritics: expectList(items[2], "diacritic list").map((d) => expectNatNumber(d, "diacritic id")),
    sockets: termSockets(items[3]),
  };
}

// --------------------------------------------------------------------------
// Public word-level API (SDK-INTERFACE.md §2).
// --------------------------------------------------------------------------

/** Canonical codec-v1 serialization `ser(word)`. @returns {Uint8Array} */
export function toBytes(coord) {
  return serializeTerm(wordToTerm(coord));
}

/** Strict decode: only canonical serializations of valid words succeed. */
export function fromBytes(data) {
  return termToWord(deserializeTerm(data));
}

/** `E(t)` per CODEC.md §3. @returns {bigint} */
export function toInteger(coord) {
  return rank(toBytes(coord));
}

/** Strict decode of a natural number (BigInt or safe non-negative Number). */
export function fromInteger(n) {
  let v = n;
  if (typeof v === "number") {
    if (!Number.isSafeInteger(v) || v < 0) {
      throw new IthkuilError("invalid_natural_number", `expected a non-negative integer, got ${show(n)}`);
    }
    v = BigInt(v);
  }
  if (typeof v !== "bigint" || v < 0n) {
    throw new IthkuilError("invalid_natural_number", `expected a non-negative integer, got ${show(n)}`);
  }
  return fromBytes(unrank(v));
}

/** Unsigned decimal string — the only sanctioned cross-boundary integer form. */
export function toIntegerString(coord) {
  return toInteger(coord).toString(10);
}

/**
 * Parse an unsigned decimal string. Rejects sign characters, empty strings,
 * and anything but ASCII digits 0-9 (non-ASCII digit codepoints included).
 */
export function fromIntegerString(s) {
  if (typeof s !== "string" || !/^[0-9]+$/.test(s)) {
    throw new IthkuilError("invalid_natural_number", `expected unsigned decimal string, got ${show(s)}`);
  }
  return fromInteger(BigInt(s));
}
