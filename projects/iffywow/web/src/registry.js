/**
 * iffywow/web — seed enum + geometry registry (schema v1).
 *
 * STAND-IN for output code-generated from ../../spec/*.yaml. IDs follow the
 * enum stability rule (an integer ID is never reassigned). Shapes are
 * deterministic placeholder paths — distinct per ID, stable across releases of
 * this file — until official Ithkuil IV glyph paths land in spec/geometry/.
 * Replacing a placeholder path with the official path is a rendering change,
 * not a semantic change: the tuple, not the path, is canonical.
 */
import {hash32, rng, r1} from "./util.js";

export const SCHEMA_VERSION = 1;

/**
 * Every possible socket has a fixed angular position (degrees, SVG y-down:
 * -90 is up). Empty sockets are hidden; occupied sockets never move.
 */
export const SOCKETS = [
  {id: 0, name: "upper", angle: -90},
  {id: 1, name: "upper_right", angle: -45},
  {id: 2, name: "right", angle: 0},
  {id: 3, name: "lower_right", angle: 45},
  {id: 4, name: "lower", angle: 90},
  {id: 5, name: "lower_left", angle: 135},
  {id: 6, name: "left", angle: 180},
  {id: 7, name: "upper_left", angle: -135},
];

export const SOCKET_COUNT = SOCKETS.length;

/** @param {number} id */
export function socketById(id) {
  return SOCKETS[((id % SOCKET_COUNT) + SOCKET_COUNT) % SOCKET_COUNT];
}

/** @param {number} id 0..3 @returns {number} degrees */
export function orientationDegrees(id) {
  return (((id % 4) + 4) % 4) * 90;
}

/* ------------------------------------------------------------------ *
 *  Deterministic placeholder geometry.                                *
 *  Seed namespaces keep base/modifier/diacritic shape spaces          *
 *  independent: base 0x10000+id, modifier 0x20000+id, diacritic       *
 *  0x30000+id.                                                        *
 * ------------------------------------------------------------------ */

function ringPoints(rand, k, radius) {
  const pts = [];
  for (let i = 0; i < k; i++) {
    const a = -Math.PI / 2 + (i / k) * 2 * Math.PI + (rand() - 0.5) * 0.9;
    const d = radius * (0.55 + 0.45 * rand());
    pts.push([Math.cos(a) * d, Math.sin(a) * d]);
  }
  return pts;
}

function polyline(pts, rand, wobble) {
  let d = `M ${r1(pts[0][0])} ${r1(pts[0][1])}`;
  for (let i = 1; i < pts.length; i++) {
    if (i % 2 === 1) {
      const mx = (pts[i - 1][0] + pts[i][0]) / 2 + (rand() - 0.5) * wobble;
      const my = (pts[i - 1][1] + pts[i][1]) / 2 + (rand() - 0.5) * wobble;
      d += ` Q ${r1(mx)} ${r1(my)} ${r1(pts[i][0])} ${r1(pts[i][1])}`;
    } else {
      d += ` L ${r1(pts[i][0])} ${r1(pts[i][1])}`;
    }
  }
  return d;
}

/**
 * Base glyph stroke path, centered on (0,0), extent ≈ ±40.
 * A tilted spine stroke gives every base a script-like axis.
 * @param {number} id @returns {string}
 */
export function basePath(id) {
  const rand = rng(hash32(0x10000 + id));
  const k = 4 + Math.floor(rand() * 3);
  let d = polyline(ringPoints(rand, k, 34), rand, 26);
  const tilt = (rand() - 0.5) * 0.45;
  const sx = Math.cos(tilt) * 34;
  const sy = Math.sin(tilt) * 34;
  d += ` M ${r1(-sx)} ${r1(-sy)} L ${r1(sx)} ${r1(sy)}`;
  return d;
}

/**
 * Modifier stroke path, centered on (0,0), extent ≈ ±16.
 * @param {number} id @returns {string}
 */
export function modifierPath(id) {
  const rand = rng(hash32(0x20000 + id));
  const k = 3 + Math.floor(rand() * 2);
  return polyline(ringPoints(rand, k, 15), rand, 12);
}

/**
 * Diacritic mark, centered on (0,0), extent ≈ ±5.
 * Four families (dot, bar, chevron, arc); orientation applied via placement.
 * @param {number} id @returns {string}
 */
export function diacriticPath(id) {
  switch (hash32(0x30000 + id) % 4) {
    case 0:
      return "M -3 0 A 3 3 0 1 0 3 0 A 3 3 0 1 0 -3 0";
    case 1:
      return "M -5 0 L 5 0";
    case 2:
      return "M -5 3 L 0 -4 L 5 3";
    default:
      return "M -5 2 Q 0 -6 5 2";
  }
}

/** Deterministic rotation (multiples of 45°) for a diacritic mark. */
export function diacriticRotation(id) {
  return (hash32(0x40000 + id) % 8) * 45;
}
