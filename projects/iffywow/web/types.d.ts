/**
 * iffywow/web — type declarations for the <ithkuil-word> component and its
 * render-model contract. Runtime source is plain ES modules (src/*.js).
 */
import type {LitElement} from "lit";

/** ["ithkuil-word", version, glyphs] — JSON tagged arrays, order-preserving. */
export type CoordinateWire = [tag: "ithkuil-word", version: number, glyphs: GlyphWire[]];
export type GlyphWire = [
  tag: "glyph",
  characterClass: number,
  base: number,
  orientation: number,
  sockets: SocketWire[],
];
export type SocketWire = [socketId: number, occupant: ModifierWire | null];
export type ModifierWire = [
  tag: "modifier",
  shape: number,
  orientation: number,
  diacritics: number[],
  sockets: SocketWire[],
];

export interface Placement {
  translate: [number, number];
  rotate: number;
  scale: number;
  visible: boolean;
}

export interface RenderNode {
  id: string;
  parentId?: string;
  kind: "base" | "modifier" | "diacritic" | "connector" | "socket-marker";
  path?: string;
  compact: Placement;
  exploded: Placement;
  socket?: {
    id: number;
    name: string;
    occupied: boolean;
    anchor: [number, number];
    orbitCenter: [number, number];
  };
}

export interface IthkuilWordModel {
  schema: `ithkuil-coordinate/${number}`;
  /** Canonical romanization — codec-provided, optional. */
  latinized?: string;
  /** Natural-number code as an unsigned DECIMAL STRING — codec-provided, optional. */
  integer?: string;
  coordinate: CoordinateWire;
  viewBox: [number, number, number, number];
  nodes: RenderNode[];
}

export declare function compileScene(
  input: CoordinateWire | string,
  opts?: {latinized?: string; integer?: string},
): IthkuilWordModel;

export declare function parseCoordinate(input: unknown): {word: object; wire: CoordinateWire};

export declare function sceneToSVG(model: IthkuilWordModel, mode?: "compact" | "exploded"): string;
export declare function extractCoordinate(svgText: string): CoordinateWire | null;

export declare class IthkuilWordElement extends LitElement {
  model?: IthkuilWordModel;
  coordinate?: CoordinateWire | string;
  latinized?: string;
  integer?: string;
  exploded: boolean;
  readonly scene?: IthkuilWordModel;
  toSVG(mode?: "compact" | "exploded"): string;
  static extractCoordinate: typeof extractCoordinate;
}

declare global {
  interface HTMLElementTagNameMap {
    "ithkuil-word": IthkuilWordElement;
  }
  interface HTMLElementEventMap {
    "ithkuil-mode-change": CustomEvent<{exploded: boolean}>;
  }
}
