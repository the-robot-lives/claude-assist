/**
 * Stable machine-readable error codes — SDK-INTERFACE.md §3.
 *
 * Codes are permanent: add, never rename. `conformance/invalid_inputs.jsonl`
 * asserts on `.code`; the human-readable detail after the code is
 * implementation-chosen and non-normative.
 */

export const ERROR_CODES = Object.freeze([
  "invalid_natural_number",
  "nonminimal_varint",
  "reserved_tag",
  "unknown_tag",
  "truncated",
  "trailing_bytes",
  "invalid_version",
  "invalid_orientation",
  "invalid_socket_id",
  "duplicate_socket",
  "unsorted_sockets",
  "invalid_structure",
  "unsupported",
]);

/**
 * Error carrying a stable, machine-readable `.code`.
 *
 * `err.message` always begins with `"<code>: "` (mirroring the Python
 * reference), so callers can assert on either the code attribute or the
 * message text.
 */
export class IthkuilError extends Error {
  /**
   * @param {string} code — one of ERROR_CODES
   * @param {string} detail — human-readable detail (non-normative)
   */
  constructor(code, detail) {
    super(`${code}: ${detail}`);
    this.name = "IthkuilError";
    this.code = code;
  }
}

/** Short, safe repr of an arbitrary value for error details. */
export function show(value) {
  if (typeof value === "bigint") return `${value}n`;
  if (typeof value === "function") return "function";
  try {
    const s = JSON.stringify(value);
    return s === undefined ? String(value) : s;
  } catch {
    return String(value);
  }
}
