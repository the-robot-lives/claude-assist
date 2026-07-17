/**
 * iffywow/web — deterministic scene compiler: coordinate → render model.
 *
 * Produces a flat node list where every node carries a stable ID and TWO
 * precomputed absolute placements (compact, exploded). The renderer's only
 * "logic" is choosing one of the two projections. Exploded socket geometry:
 * socket i sits at its FIXED registry angle (rotated by its parent's
 * orientation); empty sockets draw nothing and occupied sockets never move.
 *
 *   marker  p_i = c + dir(θ̂_i) · r_s · k        (socket indicator circle)
 *   orbit   q_i = c + dir(θ̂_i) · r_o · k        (orbit box center)
 *   ray     c → q_i                              (radial connector)
 *
 * with k = CHILD_FACTOR^depth shrinking each recursion level.
 *
 * NOTE: in production this compiler is the Elixir `Ithkuil.Scene` module; this
 * JS twin exists so <ithkuil-word> works standalone from a bare coordinate.
 * Both must agree on conformance/scene_graph.jsonl vectors.
 */
import {
  SCHEMA_VERSION,
  socketById,
  orientationDegrees,
  basePath,
  modifierPath,
  diacriticPath,
  diacriticRotation,
} from "./registry.js";
import {parseCoordinate} from "./coordinate.js";
import {r1} from "./util.js";

export const BASE_R = 40; // base glyph half-extent
export const ANCHOR_R = 46; // compact attachment radius from center
export const MARKER_R = 64; // exploded socket-marker radius
export const ORBIT_R = 118; // exploded orbit-box center radius
export const BOX_HALF = 26; // exploded orbit-box half-size
export const CHILD_FACTOR = 0.5; // per-depth shrink
export const COMPACT_MOD_SCALE = 0.5;
export const EXPLODED_MOD_SCALE = 1.4;
export const DIAC_RING_COMPACT = 18;
export const DIAC_RING_EXPLODED = 36;
export const COMPACT_ADVANCE = 130; // glyph-to-glyph advance, compact
export const EXPLODED_ADVANCE = 400; // glyph-to-glyph advance, exploded
const PAD = 18;

const rad = (deg) => (deg * Math.PI) / 180;

function placement(tx, ty, rotate = 0, scale = 1, visible = true) {
  return {
    translate: [r1(tx), r1(ty)],
    rotate: r1(rotate),
    scale: Math.round(scale * 1000) / 1000,
    visible,
  };
}

const HIDDEN = placement(0, 0, 0, 1, false);

function circlePath(cx, cy, r) {
  const [x0, x1] = [r1(cx - r), r1(cx + r)];
  const [y, rr] = [r1(cy), r1(r)];
  return `M ${x0} ${y} A ${rr} ${rr} 0 1 0 ${x1} ${y} A ${rr} ${rr} 0 1 0 ${x0} ${y}`;
}

function rectPath(cx, cy, h) {
  return `M ${r1(cx - h)} ${r1(cy - h)} H ${r1(cx + h)} V ${r1(cy + h)} H ${r1(cx - h)} Z`;
}

class Bounds {
  constructor() {
    this.minX = Infinity;
    this.minY = Infinity;
    this.maxX = -Infinity;
    this.maxY = -Infinity;
  }
  extend(x, y, r) {
    this.minX = Math.min(this.minX, x - r);
    this.minY = Math.min(this.minY, y - r);
    this.maxX = Math.max(this.maxX, x + r);
    this.maxY = Math.max(this.maxY, y + r);
  }
  viewBox(pad) {
    if (!Number.isFinite(this.minX)) return [-60, -60, 120, 120];
    return [
      r1(this.minX - pad),
      r1(this.minY - pad),
      r1(this.maxX - this.minX + 2 * pad),
      r1(this.maxY - this.minY + 2 * pad),
    ];
  }
}

/**
 * Compile a coordinate (wire array or JSON string) into a render model.
 * @param {unknown} input coordinate wire form
 * @param {{latinized?: string, integer?: string}} [opts]
 *   Optional codec-provided facts. The browser NEVER computes these — they
 *   come from the Elixir/Python codec or are omitted.
 */
export function compileScene(input, opts = {}) {
  const {word, wire} = parseCoordinate(input);
  const nodes = [];
  const bounds = new Bounds();

  word.glyphs.forEach((glyph, gi) => {
    const id = `g${gi}`;
    const cCompact = [gi * COMPACT_ADVANCE, 0];
    const cExploded = [gi * EXPLODED_ADVANCE, 0];
    const orientDeg = orientationDegrees(glyph.orientation);

    nodes.push({
      id,
      kind: "base",
      path: basePath(glyph.base),
      compact: placement(cCompact[0], cCompact[1], orientDeg, 1),
      exploded: placement(cExploded[0], cExploded[1], orientDeg, 1),
    });
    bounds.extend(cCompact[0], cCompact[1], BASE_R + 8);
    bounds.extend(cExploded[0], cExploded[1], BASE_R + 8);

    for (const sock of glyph.sockets) {
      if (sock.modifier) {
        emitSocket(nodes, bounds, id, sock, cCompact, cExploded, orientDeg, 0);
      }
    }
  });

  return {
    schema: `ithkuil-coordinate/${SCHEMA_VERSION}`,
    latinized: opts.latinized,
    integer: opts.integer,
    coordinate: wire,
    viewBox: bounds.viewBox(PAD),
    nodes,
  };
}

function emitSocket(nodes, bounds, parentId, sock, cCompact, cExploded, frameDeg, depth) {
  const def = socketById(sock.socket);
  const angle = def.angle + frameDeg;
  const dx = Math.cos(rad(angle));
  const dy = Math.sin(rad(angle));
  const k = CHILD_FACTOR ** depth;
  const prefix = `${parentId}.s${sock.socket}`;

  const anchor = [cCompact[0] + dx * ANCHOR_R * k, cCompact[1] + dy * ANCHOR_R * k];
  const marker = [cExploded[0] + dx * MARKER_R * k, cExploded[1] + dy * MARKER_R * k];
  const orbit = [cExploded[0] + dx * ORBIT_R * k, cExploded[1] + dy * ORBIT_R * k];
  const boxH = BOX_HALF * k;

  // 1. radial connector: exact center → orbit box
  nodes.push({
    id: `${prefix}.link`,
    parentId,
    kind: "connector",
    path: `M ${r1(cExploded[0])} ${r1(cExploded[1])} L ${r1(orbit[0])} ${r1(orbit[1])}`,
    compact: HIDDEN,
    exploded: placement(0, 0),
  });

  // 2. socket indicator circle + orbit box outline
  nodes.push({
    id: `${prefix}.marker`,
    parentId,
    kind: "socket-marker",
    path: `${circlePath(marker[0], marker[1], Math.max(2.5, 4 * k))} ${rectPath(orbit[0], orbit[1], boxH)}`,
    compact: HIDDEN,
    exploded: placement(0, 0),
    socket: {
      id: sock.socket,
      name: def.name,
      occupied: true,
      anchor: [r1(anchor[0]), r1(anchor[1])],
      orbitCenter: [r1(orbit[0]), r1(orbit[1])],
    },
  });

  // 3. the modifier itself — same node, two projections
  const m = sock.modifier;
  const modDeg = orientationDegrees(m.orientation) + frameDeg;
  const modId = `${prefix}.mod`;
  nodes.push({
    id: modId,
    parentId,
    kind: "modifier",
    path: modifierPath(m.shape),
    compact: placement(anchor[0], anchor[1], modDeg, COMPACT_MOD_SCALE * k),
    exploded: placement(orbit[0], orbit[1], modDeg, EXPLODED_MOD_SCALE * k),
  });
  bounds.extend(anchor[0], anchor[1], (16 + DIAC_RING_COMPACT) * k + 8);
  bounds.extend(orbit[0], orbit[1], boxH + DIAC_RING_EXPLODED * k + 10);
  bounds.extend(marker[0], marker[1], 6);

  // 4. diacritics orbit the modifier's own local center in fixed 45° slots
  m.diacritics.forEach((d, j) => {
    const slot = rad(-90 + j * 45 + modDeg);
    const sx = Math.cos(slot);
    const sy = Math.sin(slot);
    const rot = diacriticRotation(d);
    nodes.push({
      id: `${modId}.d${j}`,
      parentId: modId,
      kind: "diacritic",
      path: diacriticPath(d),
      compact: placement(
        anchor[0] + sx * DIAC_RING_COMPACT * k,
        anchor[1] + sy * DIAC_RING_COMPACT * k,
        rot,
        Math.max(0.5, 0.8 * k)
      ),
      exploded: placement(
        orbit[0] + sx * DIAC_RING_EXPLODED * k,
        orbit[1] + sy * DIAC_RING_EXPLODED * k,
        rot,
        Math.max(0.5, k)
      ),
    });
  });

  // 5. recurse: the modifier's own sockets orbit ITS center
  for (const child of m.sockets) {
    if (child.modifier) {
      emitSocket(nodes, bounds, modId, child, anchor, orbit, modDeg, depth + 1);
    }
  }
}
