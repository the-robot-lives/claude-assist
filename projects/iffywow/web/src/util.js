/**
 * iffywow/web — shared deterministic helpers.
 * All randomness is seeded; identical inputs produce identical output on every
 * JS engine (Math.imul + >>> keep everything in 32-bit integer space).
 */

/** @param {number} n @returns {number} 32-bit avalanche hash */
export function hash32(n) {
  let x = (n ^ 0x9e3779b9) >>> 0;
  x = Math.imul(x ^ (x >>> 16), 0x045d9f3b) >>> 0;
  x = Math.imul(x ^ (x >>> 16), 0x045d9f3b) >>> 0;
  return (x ^ (x >>> 16)) >>> 0;
}

/** @param {number} seed @returns {() => number} deterministic PRNG in [0, 1) */
export function rng(seed) {
  let s = seed >>> 0;
  return () => {
    s = (Math.imul(s, 1664525) + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

/** @param {number} n @returns {number} rounded to 0.1 (stable SVG output) */
export function r1(n) {
  const v = Math.round(n * 10) / 10;
  return Object.is(v, -0) ? 0 : v;
}
