/**
 * Deterministic scene-compiler tests for web/src/scene.js — run with
 * `node --test`. These assert the invariants shared with the Elixir/Python
 * scene compilers (same snapshot used in their suites).
 */
import test from "node:test";
import assert from "node:assert/strict";
import {compileScene} from "../src/scene.js";

const SAMPLE = ["ithkuil-word", 1, [["glyph", 0, 17, 1, [[1, ["modifier", 6, 2, [3], []]]]]]];

test("stable node ids (cross-runtime snapshot)", () => {
  const ids = compileScene(SAMPLE).nodes.map((n) => n.id);
  assert.deepEqual(ids, ["g0", "g0.s1.link", "g0.s1.marker", "g0.s1.mod", "g0.s1.mod.d0"]);
});

test("compilation is deterministic", () => {
  assert.deepEqual(compileScene(SAMPLE), compileScene(SAMPLE));
});

test("occupied sockets never move when other sockets fill in", () => {
  const one = compileScene(["ithkuil-word", 1, [["glyph", 0, 17, 1, [[1, ["modifier", 6, 2, [], []]]]]]]);
  const many = compileScene([
    "ithkuil-word", 1,
    [["glyph", 0, 17, 1, [
      [1, ["modifier", 6, 2, [], []]],
      [4, ["modifier", 2, 0, [], []]],
      [6, ["modifier", 3, 1, [], []]],
    ]]],
  ]);
  const a = one.nodes.find((n) => n.id === "g0.s1.marker").socket;
  const b = many.nodes.find((n) => n.id === "g0.s1.marker").socket;
  assert.deepEqual(a.orbitCenter, b.orbitCenter);
  assert.deepEqual(a.anchor, b.anchor);
});

test("every node has both placements; hidden compact for exploded-only nodes", () => {
  for (const node of compileScene(SAMPLE).nodes) {
    assert.ok(node.compact && node.exploded, node.id);
    if (node.kind === "connector" || node.kind === "socket-marker") {
      assert.equal(node.compact.visible, false, node.id);
      assert.equal(node.exploded.visible, true, node.id);
    }
  }
});

test("viewBox is finite and non-degenerate", () => {
  const [x, y, w, h] = compileScene(SAMPLE).viewBox;
  for (const v of [x, y, w, h]) assert.ok(Number.isFinite(v));
  assert.ok(w > 0 && h > 0);
});

test("empty word gets the default viewBox", () => {
  assert.deepEqual(compileScene(["ithkuil-word", 1, []]).viewBox, [-60, -60, 120, 120]);
});

test("nested modifier sockets recurse with shrinking geometry", () => {
  const nested = compileScene([
    "ithkuil-word", 1,
    [["glyph", 0, 5, 0, [[1, ["modifier", 2, 1, [], [[4, ["modifier", 9, 0, [], []]]]]]]]],
  ]);
  const ids = nested.nodes.map((n) => n.id);
  assert.ok(ids.includes("g0.s1.mod.s4.mod"), "child modifier present");
  const parent = nested.nodes.find((n) => n.id === "g0.s1.mod");
  const child = nested.nodes.find((n) => n.id === "g0.s1.mod.s4.mod");
  assert.ok(child.exploded.scale < parent.exploded.scale, "child shrinks");
});
