/**
 * Pure-module tests for web/src/coordinate.js — run with `node --test`.
 * (The Lit element and metadata.js need a DOM; they're exercised in-browser
 * via demo/index.html's round-trip verifier.)
 */
import test from "node:test";
import assert from "node:assert/strict";
import {parseCoordinate, toWire} from "../src/coordinate.js";

const MOD = (shape, orient = 0) => ["modifier", shape, orient, [], []];

test("canonicalization sorts sockets and drops empties", () => {
  const {wire} = parseCoordinate([
    "ithkuil-word", 1,
    [["glyph", 0, 5, 0, [[4, MOD(1)], [0, null], [1, MOD(2, 1)]]]],
  ]);
  assert.deepEqual(wire, [
    "ithkuil-word", 1,
    [["glyph", 0, 5, 0, [[1, MOD(2, 1)], [4, MOD(1)]]]],
  ]);
});

test("canonical form is a fixpoint", () => {
  const once = parseCoordinate(["ithkuil-word", 1, [["glyph", 0, 5, 0, [[4, MOD(1)], [0, null]]]]]).wire;
  const twice = parseCoordinate(once).wire;
  assert.deepEqual(twice, once);
});

test("JSON string input is accepted", () => {
  const {wire} = parseCoordinate('["ithkuil-word",1,[]]');
  assert.deepEqual(wire, ["ithkuil-word", 1, []]);
});

test("duplicate sockets rejected (even when empty)", () => {
  assert.throws(
    () => parseCoordinate(["ithkuil-word", 1, [["glyph", 0, 0, 0, [[1, null], [1, null]]]]]),
    /duplicate socket/
  );
});

test("orientation out of range rejected", () => {
  assert.throws(
    () => parseCoordinate(["ithkuil-word", 1, [["glyph", 0, 0, 4, []]]]),
    /orientation must be 0\.\.3/
  );
});

test("socket id out of range rejected", () => {
  assert.throws(
    () => parseCoordinate(["ithkuil-word", 1, [["glyph", 0, 0, 0, [[8, MOD(0)]]]]]),
    /socket id must be 0\.\.7/
  );
});

test("bad version rejected", () => {
  assert.throws(() => parseCoordinate(["ithkuil-word", 0, []]), /schema version/);
});

test("toWire(word) mirrors parse output", () => {
  const {word, wire} = parseCoordinate(["ithkuil-word", 1, [["glyph", 2, 9, 3, [[6, MOD(7, 2)]]]]]);
  assert.deepEqual(toWire(word), wire);
});
