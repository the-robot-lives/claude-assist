import type { GraphNode } from "@/lib/holograph/types";
import { accentFor, nodeVisual, shadeToward, type NodeBadge, type NodeVisualSpec } from "@/lib/holograph/node-visuals";

/** Canvas2D painter for a node's face card.
 *
 * The previous `labelTexture()` drew the identical card for every kind: white box, coloured
 * stroke, stereotype, name, attributes, operations. This version follows Unity's
 * `UmlNodeView.BuildClassifierCard` (`Assets/Scripts/Uml/UmlNodeView.cs:151-205`) -- the
 * stereotype row is omitted where the kind has none, compartments are per-kind rather than
 * unconditional, kinds with no compartments get Unity's titled-box variant, and each kind
 * carries the UML mark its notation specifies. */

const CARD_W = 768;
const CARD_H_FULL = 448;
const CARD_H_COMPACT = 192;

const INK = "rgba(24, 29, 30, 0.92)";
const INK_DIM = "rgba(60, 68, 72, 0.78)";
const PAPER = "rgba(250, 251, 252, 0.97)";

function escapeLabel(value: string | undefined) {
  return (value ?? "").replace(/[<>]/g, "");
}

/** UML marks. Each is drawn into the box (x, y, size), stroked in the kind's accent. */
function paintBadge(ctx: CanvasRenderingContext2D, badge: NodeBadge, x: number, y: number, size: number, accent: string) {
  ctx.save();
  ctx.strokeStyle = accent;
  ctx.fillStyle = accent;
  ctx.lineWidth = Math.max(3, size * 0.07);
  ctx.lineJoin = "miter";

  switch (badge) {
    /** Rectangle with two tabs protruding from the left edge. */
    case "component-tabs": {
      const bw = size * 0.72;
      const bh = size * 0.86;
      const bx = x + size - bw;
      const by = y + (size - bh) / 2;
      ctx.strokeRect(bx, by, bw, bh);
      const tw = size * 0.3;
      const th = size * 0.2;
      for (const ty of [by + bh * 0.18, by + bh * 0.58]) {
        ctx.clearRect(bx - tw / 2 + 1, ty + 1, tw - 2, th - 2);
        ctx.strokeRect(bx - tw / 2, ty, tw, th);
      }
      break;
    }

    /** Folder: tab over a body rectangle. */
    case "folder-tab": {
      const tabH = size * 0.2;
      const tabW = size * 0.44;
      ctx.strokeRect(x, y, tabW, tabH);
      ctx.strokeRect(x, y + tabH, size, size - tabH);
      break;
    }

    /** Stick figure: head, spine, arms, legs. */
    case "actor-figure": {
      const cx = x + size / 2;
      const headR = size * 0.16;
      const headY = y + headR + size * 0.04;
      ctx.beginPath();
      ctx.arc(cx, headY, headR, 0, Math.PI * 2);
      ctx.stroke();
      const spineTop = headY + headR;
      const spineBottom = y + size * 0.64;
      ctx.beginPath();
      ctx.moveTo(cx, spineTop);
      ctx.lineTo(cx, spineBottom);
      ctx.moveTo(x + size * 0.12, y + size * 0.46);
      ctx.lineTo(x + size * 0.88, y + size * 0.46);
      ctx.moveTo(cx, spineBottom);
      ctx.lineTo(x + size * 0.16, y + size);
      ctx.moveTo(cx, spineBottom);
      ctx.lineTo(x + size * 0.84, y + size);
      ctx.stroke();
      break;
    }

    /** Drum seen from the side: top ellipse, straight walls, curved base. */
    case "cylinder-profile": {
      const ry = size * 0.15;
      const top = y + ry;
      const bottom = y + size - ry;
      ctx.beginPath();
      ctx.ellipse(x + size / 2, top, size * 0.42, ry, 0, 0, Math.PI * 2);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(x + size * 0.08, top);
      ctx.lineTo(x + size * 0.08, bottom);
      ctx.ellipse(x + size / 2, bottom, size * 0.42, ry, 0, Math.PI, 0, true);
      ctx.moveTo(x + size * 0.92, bottom);
      ctx.lineTo(x + size * 0.92, top);
      ctx.stroke();
      break;
    }

    /** Provided interface: ball on a stem. */
    case "lollipop": {
      const r = size * 0.2;
      const cy = y + size / 2;
      ctx.beginPath();
      ctx.moveTo(x, cy);
      ctx.lineTo(x + size * 0.55 - r, cy);
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(x + size * 0.55 + r * 0.2, cy, r, 0, Math.PI * 2);
      ctx.stroke();
      break;
    }

    /** Enumeration: a box of stacked literal rules. */
    case "enum-bars": {
      ctx.strokeRect(x, y, size, size);
      ctx.lineWidth = Math.max(2, size * 0.05);
      for (let i = 1; i <= 3; i += 1) {
        const ly = y + (size / 4) * i;
        ctx.beginPath();
        ctx.moveTo(x + size * 0.16, ly);
        ctx.lineTo(x + size * 0.84, ly);
        ctx.stroke();
      }
      break;
    }

    /** Note: rectangle with the top-right corner folded. */
    case "dog-ear": {
      const fold = size * 0.3;
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo(x + size - fold, y);
      ctx.lineTo(x + size, y + fold);
      ctx.lineTo(x + size, y + size);
      ctx.lineTo(x, y + size);
      ctx.closePath();
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(x + size - fold, y);
      ctx.lineTo(x + size - fold, y + fold);
      ctx.lineTo(x + size, y + fold);
      ctx.stroke();
      break;
    }

    /** Region / frame: dashed container with a name tab in the top-left. */
    case "region-tab": {
      const tabH = size * 0.22;
      const tabW = size * 0.5;
      ctx.strokeRect(x, y, tabW, tabH);
      ctx.setLineDash([size * 0.1, size * 0.07]);
      ctx.strokeRect(x, y, size, size);
      ctx.setLineDash([]);
      break;
    }

    /** System boundary: a frame inset within a frame. */
    case "system-frame": {
      ctx.strokeRect(x, y, size, size);
      ctx.lineWidth = Math.max(2, size * 0.05);
      ctx.setLineDash([size * 0.12, size * 0.08]);
      ctx.strokeRect(x + size * 0.18, y + size * 0.18, size * 0.64, size * 0.64);
      ctx.setLineDash([]);
      break;
    }

    case "none":
    default:
      break;
  }
  ctx.restore();
}

function compartmentRows(node: GraphNode, spec: NodeVisualSpec) {
  const rows: Array<{ items: string[] }> = [];
  for (const compartment of spec.compartments) {
    if (compartment === "attributes" || compartment === "literals") {
      const items = node.uml?.attributes?.length ? node.uml.attributes : node.members ?? [];
      if (items.length) rows.push({ items });
    } else if (compartment === "operations") {
      const items = node.uml?.operations ?? [];
      if (items.length) rows.push({ items });
    }
  }
  return rows;
}

export function paintNodeFace(node: GraphNode, compact = false): HTMLCanvasElement {
  const spec = nodeVisual(node.kind);
  const bodyHex = node.trd3d?.color ?? spec.body;
  const accent = accentFor(bodyHex);
  const height = compact ? CARD_H_COMPACT : CARD_H_FULL;

  const canvas = document.createElement("canvas");
  canvas.width = CARD_W;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Canvas unavailable for TRD 3D label texture.");

  ctx.clearRect(0, 0, CARD_W, height);
  ctx.fillStyle = PAPER;
  ctx.fillRect(0, 0, CARD_W, height);

  // Header band, tinted with the kind's hue -- Unity's non-EA header uses the same idea
  // (`UmlNodeView.cs`: header = lerp(hue, white, 0.52)).
  const stereotype = node.stereotype ?? spec.stereotype;
  const hasStereotype = Boolean(stereotype);
  const headerH = compact ? height : hasStereotype ? 168 : 130;
  ctx.fillStyle = shadeToward(bodyHex, "#ffffff", 0.62);
  ctx.fillRect(0, 0, CARD_W, headerH);

  ctx.strokeStyle = accent;
  ctx.lineWidth = 16;
  ctx.strokeRect(8, 8, CARD_W - 16, height - 16);

  const badgeSize = compact ? 84 : 96;
  paintBadge(ctx, spec.badge, CARD_W - badgeSize - 44, 34, badgeSize, accent);

  ctx.textAlign = "center";
  ctx.textBaseline = "top";

  let y = hasStereotype ? 30 : 44;
  if (hasStereotype) {
    ctx.fillStyle = INK_DIM;
    ctx.font = "700 38px ui-monospace, Menlo, monospace";
    ctx.fillText(`<<${escapeLabel(stereotype ?? undefined)}>>`, CARD_W / 2, y);
    y += 50;
  }

  ctx.fillStyle = INK;
  ctx.font = "900 58px Inter, ui-sans-serif, system-ui";
  // Abstract classifiers are italicised, per UML.
  if (node.uml?.abstract) ctx.font = `italic ${ctx.font}`;
  ctx.fillText(escapeLabel(node.label), CARD_W / 2, compact ? (hasStereotype ? y : 62) : y);

  if (compact) {
    return canvas;
  }

  const rows = compartmentRows(node, spec);
  if (!rows.length) {
    // Unity's titled-box variant: no compartments, so no dividing rules either.
    return canvas;
  }

  ctx.strokeStyle = "rgba(24, 29, 30, 0.24)";
  ctx.lineWidth = 4;
  ctx.textAlign = "left";
  ctx.fillStyle = INK;
  ctx.font = "600 30px ui-monospace, Menlo, monospace";

  let cursor = headerH;
  for (const row of rows) {
    ctx.beginPath();
    ctx.moveTo(8, cursor);
    ctx.lineTo(CARD_W - 8, cursor);
    ctx.stroke();
    cursor += 26;
    for (const item of row.items.slice(0, 4)) {
      if (cursor > height - 44) break;
      ctx.fillText(escapeLabel(item), 52, cursor);
      cursor += 36;
    }
    cursor += 6;
  }

  return canvas;
}
