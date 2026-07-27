import type { NodeKind } from "@/lib/holograph/types";

/** Per-kind visual identity for TRD nodes -- the single source of truth the three.js
 * renderer, the palette chips and the kind browser all read from.
 *
 * Before this existed, node colour lived as a hardcoded if-chain in `trd-three-scene.tsx`
 * and every kind rendered as the same `BoxGeometry`: `actor-hex`, `interface-card`,
 * `component-capsule` and `namespace-slab` were all declared but all fell through to a box.
 *
 * Unity is the reference (`Assets/Scripts/Authoring/Model/Kinds.cs`, `Uml/UmlNodeView.cs`,
 * `Uml/Uml3D/UmlNode3D.cs`). Ported conventions:
 *   - one hue per kind is the identity; the border is that hue darkened, not a second token
 *     (`UmlNode3D.cs:451` -- `border = lerp(fill, black, 0.55)`)
 *   - the title card is stereotype row / bold name row / rule / attributes / rule / operations
 *     (`UmlNodeView.cs:151-205`)
 *   - kinds with no compartments use Unity's titled-box variant (`IsSingleLabelNode`)
 *   - each kind carries the UML mark its notation actually specifies
 *
 * Body hues for kinds already shipping on the web are kept as-is; `function` and `agent`
 * previously shared the generic teal default and are given their own, sourced from Unity's
 * hue table (`Function #2CA02C`, and the mint the Unity 3D `<<agent>>` card renders with). */

/** The 2D UML mark painted onto a node's face card, over and above its 3D silhouette.
 * These are marks UML itself specifies -- a component's two protruding tabs, a package's
 * folder tab, an actor's stick figure, a note's dog-eared corner. */
export type NodeBadge =
  | "none"
  | "component-tabs"
  | "folder-tab"
  | "actor-figure"
  | "cylinder-profile"
  | "lollipop"
  | "enum-bars"
  | "dog-ear"
  | "region-tab"
  | "system-frame";

/** 3D silhouette. Mirrors `Trd3dNodeShapeKind` in `lib/trd-3d`, but this is the vocabulary
 * the renderer switches on directly -- no lossy `shapeHint()` downcast in between. */
export type NodeSilhouette =
  | "class-box"
  | "interface-card"
  | "namespace-slab"
  | "component-capsule"
  | "database-cylinder"
  | "method-pill"
  | "actor-hex"
  | "compound-slab";

export interface NodeVisualSpec {
  /** Rendered as `<<stereotype>>` on the face card. `null` = no stereotype row, matching
   * Unity, where Class/Package/Actor/Datastore/Note carry none. */
  stereotype: string | null;
  /** Two-letter palette glyph, retained as the compact fallback behind the SVG marks. */
  glyph: string;
  /** The kind's identity hue: 3D body fill, and the tint the face card's border and
   * header rule derive from. */
  body: string;
  silhouette: NodeSilhouette;
  badge: NodeBadge;
  /** UML compartments the face card draws, in order. Empty = Unity's titled-box variant. */
  compartments: Array<"attributes" | "operations" | "literals">;
}

export const NODE_VISUALS: Record<NodeKind, NodeVisualSpec> = {
  system: {
    stereotype: "system",
    glyph: "Sy",
    body: "#4d9a8f",
    silhouette: "compound-slab",
    badge: "system-frame",
    compartments: [],
  },
  package: {
    stereotype: null,
    glyph: "Pk",
    body: "#6a7f55",
    silhouette: "namespace-slab",
    badge: "folder-tab",
    compartments: [],
  },
  service: {
    stereotype: "component",
    glyph: "Co",
    body: "#8262a8",
    silhouette: "component-capsule",
    badge: "component-tabs",
    compartments: ["operations"],
  },
  class: {
    stereotype: null,
    glyph: "Cl",
    body: "#4d9a8f",
    silhouette: "class-box",
    badge: "none",
    compartments: ["attributes", "operations"],
  },
  interface: {
    stereotype: "interface",
    glyph: "If",
    body: "#6d8fbd",
    silhouette: "interface-card",
    badge: "lollipop",
    compartments: ["operations"],
  },
  function: {
    stereotype: "operation",
    glyph: "Fn",
    body: "#5a9a5e",
    silhouette: "method-pill",
    badge: "none",
    compartments: [],
  },
  database: {
    stereotype: null,
    glyph: "Db",
    body: "#5f7f9d",
    silhouette: "database-cylinder",
    badge: "cylinder-profile",
    compartments: ["attributes"],
  },
  agent: {
    stereotype: "agent",
    glyph: "Ac",
    body: "#71c4b8",
    silhouette: "actor-hex",
    badge: "actor-figure",
    compartments: ["operations"],
  },
};

export function nodeVisual(kind: NodeKind): NodeVisualSpec {
  return NODE_VISUALS[kind] ?? NODE_VISUALS.class;
}

/** Palette-only kinds. `enum`, `note` and `region` have no `NodeKind` yet -- their chips
 * render disabled -- but the palette still needs a distinct mark for each so the dock does
 * not show three identical squares. Hues from Unity's `KindInfo.Hue()`:
 * Enumeration `#E69F00`, Note `#F2E2A0`, Boundary/Frame `#8893A0`. */
export const PALETTE_ONLY_VISUALS: Record<
  "enum" | "note" | "region",
  { body: string; badge: NodeBadge; glyph: string; stereotype: string | null }
> = {
  enum: { body: "#c08a55", badge: "enum-bars", glyph: "En", stereotype: "enumeration" },
  note: { body: "#c9c297", badge: "dog-ear", glyph: "Nt", stereotype: null },
  region: { body: "#7e8f99", badge: "region-tab", glyph: "Rg", stereotype: "region" },
};

/** Border / rule colour for a body hue. Unity derives it the same way
 * (`UmlNode3D.cs:451` -- `lerp(fill, black, 0.55)`); the web outline already used a
 * near-identical lerp toward `#080b0d`, so this keeps one rule for both 2D and 3D. */
function parseHex(value: string): [number, number, number] | null {
  const raw = value.trim().replace(/^#/, "");
  const full = raw.length === 3 ? raw.replace(/./g, (c) => c + c) : raw;
  if (!/^[0-9a-f]{6}$/i.test(full)) return null;
  const n = parseInt(full, 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

export function shadeToward(hex: string, target: string, t: number) {
  const from = parseHex(hex);
  const to = parseHex(target);
  // `trd3d.color` is author-supplied and may be any CSS colour (`rebeccapurple`, `hsl(...)`).
  // Canvas can paint those directly even though we cannot interpolate them, so pass the
  // original through rather than emitting `rgb(NaN, NaN, NaN)`.
  if (!from || !to) return hex;
  const mix = (a: number, b: number) => Math.round(a + (b - a) * t);
  return `rgb(${mix(from[0], to[0])}, ${mix(from[1], to[1])}, ${mix(from[2], to[2])})`;
}

/** The saturated border/stroke tone for a kind -- used by the face card and the SVG marks. */
export function accentFor(body: string) {
  return shadeToward(body, "#0a0f12", 0.45);
}
