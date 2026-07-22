/**
 * @noizu/ithkuil — New Ithkuil codec-v1 core SDK for Node.
 *
 * The full SDK-INTERFACE.md surface (camelCase per §4). Conversions only:
 * no scene graphs, no SVG, no rendering — those live in web/ (and the
 * Elixir/Python scene layers).
 *
 * Interface v1 · schema v1 · codec-v1 · romanization profile core-v1.
 */

export { IthkuilError, ERROR_CODES } from "./errors.js";
export { validate, canonicalize, MAX_SOCKET_ID, MAX_ORIENTATION } from "./coord.js";
export {
  toInteger,
  fromInteger,
  toIntegerString,
  fromIntegerString,
  toBytes,
  fromBytes,
} from "./codec.js";
export { toWire, fromWire, toWireJson, fromWireJson, WORD_TAG, GLYPH_TAG, MODIFIER_TAG } from "./wire.js";
export { fromLatin, toLatin, MAX_ROOT_CODE } from "./romanization.js";
