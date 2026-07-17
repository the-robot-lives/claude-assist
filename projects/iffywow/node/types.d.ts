/**
 * Type definitions for @noizu/ithkuil — New Ithkuil codec-v1 core SDK.
 *
 * Interface v1 · schema v1 · codec-v1 · romanization profile core-v1.
 * See ../SDK-INTERFACE.md, ../CODEC.md, ../ROMANIZATION.md.
 */

// ---------------------------------------------------------------------------
// Error model (SDK-INTERFACE.md §3). Codes are permanent: add, never rename.
// ---------------------------------------------------------------------------

export type ErrorCode =
  | "invalid_natural_number"
  | "nonminimal_varint"
  | "reserved_tag"
  | "unknown_tag"
  | "truncated"
  | "trailing_bytes"
  | "invalid_version"
  | "invalid_orientation"
  | "invalid_socket_id"
  | "duplicate_socket"
  | "unsorted_sockets"
  | "invalid_structure"
  | "unsupported";

export const ERROR_CODES: readonly ErrorCode[];

/** Error carrying a stable machine-readable `.code`; `message` begins with `"<code>: "`. */
export class IthkuilError extends Error {
  readonly code: ErrorCode;
  constructor(code: ErrorCode, detail: string);
}

// ---------------------------------------------------------------------------
// Canonical coordinate tuple (CODEC.md §2, schema v1). Deep-frozen.
// ---------------------------------------------------------------------------

export interface Modifier {
  readonly shape: number;
  readonly orientation: number; // 0..3
  readonly diacritics: readonly number[];
  readonly sockets: readonly Socket[]; // sorted strictly ascending by id
}

export interface Socket {
  readonly id: number; // 0..7 in schema v1
  readonly modifier: Modifier; // canonical sockets always carry a modifier
}

export interface Glyph {
  readonly characterClass: number;
  readonly base: number;
  readonly orientation: number; // 0..3
  readonly sockets: readonly Socket[]; // sorted strictly ascending by id
}

export interface Coord {
  readonly version: number; // >= 1
  readonly glyphs: readonly Glyph[];
}

/**
 * Lenient language-native input shape accepted by `canonicalize` (and the
 * `to*` projections): sockets may be unsorted, `modifier: null | undefined`
 * marks an empty socket (dropped), and collection fields may be omitted.
 * Duplicate socket ids are always an error.
 */
export interface CoordInput {
  version: number;
  glyphs?: ReadonlyArray<{
    characterClass: number;
    base: number;
    orientation: number;
    sockets?: ReadonlyArray<SocketInput>;
  }>;
}

export interface SocketInput {
  id: number;
  modifier?: ModifierInput | null;
}

export interface ModifierInput {
  shape: number;
  orientation: number;
  diacritics?: readonly number[];
  sockets?: ReadonlyArray<SocketInput>;
}

// ---------------------------------------------------------------------------
// Wire form — JSON tagged arrays (CODEC.md §2).
// ---------------------------------------------------------------------------

export type WireModifier = ["modifier", number, number, number[], WireSocket[]];
export type WireSocket = [number, WireModifier | null];
export type WireGlyph = ["glyph", number, number, number, WireSocket[]];
export type WireWord = ["ithkuil-word", number, WireGlyph[]];

export const WORD_TAG: "ithkuil-word";
export const GLYPH_TAG: "glyph";
export const MODIFIER_TAG: "modifier";

export const MAX_SOCKET_ID: 7;
export const MAX_ORIENTATION: 3;
export const MAX_ROOT_CODE: 551880;

// ---------------------------------------------------------------------------
// Operations (SDK-INTERFACE.md §2). Fallible operations throw IthkuilError.
// ---------------------------------------------------------------------------

/** STRICT structural check of a language-native coord value; returns a deep-frozen Coord. */
export function validate(data: unknown): Coord;

/** LENIENT repair (sort sockets, drop empties) + validate; duplicates still error. */
export function canonicalize(data: unknown): Coord;

/** `E(t)` per CODEC.md §3 — arbitrary precision. */
export function toInteger(coord: Coord | CoordInput): bigint;

/** Strict decode of a natural number (BigInt, or a safe non-negative Number). */
export function fromInteger(n: bigint | number): Coord;

/** Unsigned decimal string — the ONLY cross-boundary integer form. */
export function toIntegerString(coord: Coord | CoordInput): string;

/** Rejects sign/empty/non-digits with code `invalid_natural_number`. */
export function fromIntegerString(s: string): Coord;

/** Canonical codec-v1 serialization `ser(word)`. */
export function toBytes(coord: Coord | CoordInput): Uint8Array;

/** Strict decode: minimal varints, sorted sockets, no trailing bytes. */
export function fromBytes(bytes: Uint8Array | ArrayBuffer): Coord;

/** Canonical wire tagged arrays. */
export function toWire(coord: Coord | CoordInput): WireWord;

/**
 * LENIENT-canonicalizing wire parse: accepts unsorted sockets and
 * `[id, null]` empties; sorts, drops empties; duplicate ids still error.
 * Also accepts a JSON text containing the tagged arrays.
 */
export function fromWire(data: unknown): Coord;

/** `JSON.stringify` of the canonical wire form. */
export function toWireJson(coord: Coord | CoordInput): string;

/** Parse wire JSON text (lenient-canonicalizing, as `fromWire`). */
export function fromWireJson(json: string): Coord;

/**
 * Romanized New Ithkuil text -> Coord (profile core-v1).
 * Preprocesses trim -> NFC -> lowercase; everything outside the profile is
 * rejected with code `unsupported`.
 */
export function fromLatin(text: string): Coord;

/**
 * Coord -> canonical spelling (trimmed, NFC, lowercase). Accepts exactly the
 * core-v1 coordinate shape; everything else is rejected with `unsupported`.
 */
export function toLatin(coord: Coord | CoordInput): string;
