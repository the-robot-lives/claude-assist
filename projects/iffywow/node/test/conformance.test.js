/**
 * Golden-vector conformance tests — every row of ../../conformance/*.jsonl,
 * both directions where defined. These vectors, not shared code, keep this
 * SDK in sync with the Elixir production codec and the Python reference
 * (SDK-INTERFACE.md §5: conformance/ is the arbiter).
 */

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { Buffer } from "node:buffer";

import {
  IthkuilError,
  fromWire,
  toWire,
  toWireJson,
  fromWireJson,
  toBytes,
  fromBytes,
  toInteger,
  fromInteger,
  toIntegerString,
  fromIntegerString,
  fromLatin,
  toLatin,
} from "../src/index.js";
import { serializeTerm, deserializeTerm, termFromJson, termToJson, rank, unrank } from "../src/codec.js";

// node/test/ -> ../../conformance/
function loadVectors(name) {
  const url = new URL(`../../conformance/${name}`, import.meta.url);
  return readFileSync(url, "utf8")
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .map((line) => JSON.parse(line));
}

const hexToBytes = (hex) => new Uint8Array(Buffer.from(hex, "hex"));
const bytesToHex = (bytes) => Buffer.from(bytes).toString("hex");

function assertIthkuilError(fn, code, context) {
  let threw = false;
  try {
    fn();
  } catch (err) {
    threw = true;
    assert.ok(
      err instanceof IthkuilError,
      `${context}: expected IthkuilError, got ${err && err.constructor ? err.constructor.name : typeof err}: ${err}`,
    );
    assert.equal(err.code, code, `${context}: expected code ${code}, got ${err.code} (${err.message})`);
    assert.ok(
      err.message.startsWith(`${code}:`),
      `${context}: message must start with "${code}:", got "${err.message}"`,
    );
  }
  assert.ok(threw, `${context}: expected IthkuilError ${code}, but nothing was thrown`);
}

// ---------------------------------------------------------------------------
// codec_units.jsonl — term-level ser/rank vectors (hand-computed, normative).
// ---------------------------------------------------------------------------

for (const row of loadVectors("codec_units.jsonl")) {
  test(`codec_units: bytes ${row.bytes} (${JSON.stringify(row.term)})`, () => {
    const term = termFromJson(row.term);
    const data = hexToBytes(row.bytes);

    // serialize / deserialize
    assert.equal(bytesToHex(serializeTerm(term)), row.bytes);
    assert.deepEqual(termToJson(deserializeTerm(data)), row.term);

    // rank / unrank (BigInt end to end; decimal string at the boundary)
    assert.equal(rank(data).toString(10), row.integer);
    assert.equal(bytesToHex(unrank(BigInt(row.integer))), row.bytes);

    // JSON helper round-trip keeps the vector format itself honest
    assert.deepEqual(termToJson(termFromJson(termToJson(term))), row.term);
  });
}

// ---------------------------------------------------------------------------
// coordinate_to_integer.jsonl — word-level coordinate <-> bytes <-> integer.
// ---------------------------------------------------------------------------

for (const row of loadVectors("coordinate_to_integer.jsonl")) {
  test(`coordinate_to_integer: integer ${row.integer}`, () => {
    const data = hexToBytes(row.bytes);
    const coord = fromWire(row.coordinate);

    // encode direction
    assert.equal(bytesToHex(toBytes(coord)), row.bytes);
    assert.equal(toInteger(coord).toString(10), row.integer);
    assert.equal(toIntegerString(coord), row.integer);

    // decode direction (leading zeros preserved, strict parse)
    assert.deepEqual(fromBytes(data), coord);
    assert.deepEqual(fromInteger(BigInt(row.integer)), coord);
    assert.deepEqual(fromIntegerString(row.integer), coord);

    // the vector's coordinate is already canonical
    assert.deepEqual(toWire(coord), row.coordinate);

    // wire JSON text round-trip
    assert.equal(toWireJson(coord), JSON.stringify(row.coordinate));
    assert.deepEqual(fromWireJson(JSON.stringify(row.coordinate)), coord);
  });
}

// ---------------------------------------------------------------------------
// invalid_inputs.jsonl — inputs that MUST be rejected, by error code.
// ---------------------------------------------------------------------------

for (const [i, row] of loadVectors("invalid_inputs.jsonl").entries()) {
  test(`invalid_inputs[${i}]: ${row.kind} -> ${row.error}`, () => {
    const context = `${row.kind} ${JSON.stringify(row.value)}`;
    if (row.kind === "integer_string") {
      assertIthkuilError(() => fromIntegerString(row.value), row.error, context);
    } else if (row.kind === "bytes") {
      assertIthkuilError(() => fromBytes(hexToBytes(row.value)), row.error, context);
    } else if (row.kind === "coordinate") {
      assertIthkuilError(() => fromWire(row.value), row.error, context);
      assertIthkuilError(() => fromWireJson(JSON.stringify(row.value)), row.error, `${context} (JSON text)`);
    } else {
      assert.fail(`unknown vector kind ${JSON.stringify(row.kind)}`);
    }
  });
}

// ---------------------------------------------------------------------------
// latin_to_coordinate.jsonl — romanization profile core-v1 (ROMANIZATION.md §10).
// ---------------------------------------------------------------------------

for (const [i, row] of loadVectors("latin_to_coordinate.jsonl").entries()) {
  if (row.error !== undefined) {
    test(`latin_to_coordinate[${i}]: ${JSON.stringify(row.latin)} -> ${row.error}`, () => {
      assertIthkuilError(() => fromLatin(row.latin), row.error, `latin ${JSON.stringify(row.latin)}`);
    });
  } else {
    test(`latin_to_coordinate[${i}]: ${JSON.stringify(row.latin)}`, () => {
      const coord = fromLatin(row.latin);

      // from_latin(latin) == coordinate (wire deep-equality)
      assert.deepEqual(toWire(coord), row.coordinate);

      // to_latin(coordinate) == canonical
      assert.equal(toLatin(fromWire(row.coordinate)), row.canonical);
      assert.equal(toLatin(coord), row.canonical);

      // canonical spelling round-trips exactly
      assert.deepEqual(toWire(fromLatin(row.canonical)), row.coordinate);
      assert.equal(toLatin(fromLatin(row.canonical)), row.canonical);
    });
  }
}
