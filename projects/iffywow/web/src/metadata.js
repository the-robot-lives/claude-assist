/**
 * iffywow/web — standalone SVG export with embedded coordinate metadata, and
 * exact tuple recovery from any SDK-generated SVG.
 *
 * Every SVG we generate carries its own coordinate:
 *   - data-ithkuil-schema / data-ithkuil-integer attributes
 *   - a <metadata id="ithkuil-coordinate"> JSON block
 *
 * so `extractCoordinate(render(coord)) == coord` holds with no vision, OCR, or
 * geometric inference. Recognition of UNANNOTATED glyphs is a deferred,
 * separate subsystem — deliberately not implemented here.
 */

const KIND_ATTRS = {
  base: 'stroke-width="3"',
  modifier: 'stroke-width="2.4"',
  diacritic: 'stroke-width="2"',
  connector: 'stroke-width="1" stroke-dasharray="4 3" opacity="0.65"',
  "socket-marker": 'stroke-width="1.25"',
};

function esc(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/**
 * Render a scene model to a standalone SVG document string.
 * @param {object} model render model from compileScene / the Elixir codec
 * @param {"compact" | "exploded"} [mode]
 * @returns {string}
 */
export function sceneToSVG(model, mode = "compact") {
  if (mode !== "compact" && mode !== "exploded") {
    throw new Error(`unknown mode: ${mode}`);
  }
  const [x, y, w, h] = model.viewBox;
  const body = model.nodes
    .map((node) => {
      const p = node[mode];
      if (!p?.visible || !node.path) return "";
      const t = `translate(${p.translate[0]} ${p.translate[1]}) rotate(${p.rotate}) scale(${p.scale})`;
      const extra = KIND_ATTRS[node.kind] ?? "";
      return `  <g data-node-id="${esc(node.id)}" data-kind="${esc(node.kind)}" transform="${t}" ${extra}><path d="${esc(node.path)}"/></g>`;
    })
    .filter(Boolean)
    .join("\n");

  // Escape & and < as JSON \u escapes (both only ever occur inside JSON
  // strings) so the metadata body can never break strict XML parsing.
  const meta = JSON.stringify({
    schema: model.schema,
    latinized: model.latinized ?? null,
    integer: model.integer ?? null,
    mode,
    coordinate: model.coordinate,
  })
    .replace(/&/g, "\\u0026")
    .replace(/</g, "\\u003c");

  const integerAttr = model.integer ? ` data-ithkuil-integer="${esc(model.integer)}"` : "";
  const title = model.latinized ? `  <title>${esc(model.latinized)}</title>\n` : "";

  return (
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${x} ${y} ${w} ${h}"` +
    ` data-ithkuil-schema="${esc(model.schema)}"${integerAttr}` +
    ` fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">\n` +
    title +
    `  <metadata id="ithkuil-coordinate">${meta}</metadata>\n` +
    `${body}\n</svg>\n`
  );
}

/**
 * Exact tuple recovery from an SDK-generated SVG string.
 * @param {string} svgText
 * @returns {unknown[] | null} coordinate wire form, or null when the metadata
 *   was stripped (at which point the file is an ordinary unannotated drawing
 *   and belongs to the deferred recognition subsystem).
 */
export function extractCoordinate(svgText) {
  try {
    const doc = new DOMParser().parseFromString(svgText, "image/svg+xml");
    if (doc.querySelector("parsererror")) return null;
    const meta =
      doc.getElementById("ithkuil-coordinate") ?? doc.querySelector("metadata");
    if (!meta?.textContent) return null;
    const parsed = JSON.parse(meta.textContent);
    return Array.isArray(parsed?.coordinate) ? parsed.coordinate : null;
  } catch {
    return null;
  }
}

/** Full metadata block (schema, latinized, integer, mode, coordinate) or null. */
export function extractMetadata(svgText) {
  try {
    const doc = new DOMParser().parseFromString(svgText, "image/svg+xml");
    if (doc.querySelector("parsererror")) return null;
    const meta =
      doc.getElementById("ithkuil-coordinate") ?? doc.querySelector("metadata");
    return meta?.textContent ? JSON.parse(meta.textContent) : null;
  } catch {
    return null;
  }
}
