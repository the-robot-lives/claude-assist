"use client";

import type { DragEvent } from "react";
import "./docks.css";
import { KindMark, MoreMark } from "./KindMark";
import { ELEMENT_KINDS, type ElementKindKey } from "./menu-data";

/** DataTransfer type for a dragged palette chip. The payload is an `ElementKindKey`,
 * the same vocabulary `onArm` uses — drag and click are one gesture ("place this kind"),
 * so the drop site resolves key → NodeKind once via ELEMENT_KINDS rather than each
 * entry point carrying its own translation. */
export const TRD_KIND_DRAG_TYPE = "application/x-trd-kind";

export interface PaletteDockProps {
  collapsed: boolean;
  armedKey: ElementKindKey | null;
  onArm: (key: ElementKindKey) => void;
  onOpenKindBrowser: () => void;
}

export function PaletteDock({ collapsed, armedKey, onArm, onOpenKindBrowser }: PaletteDockProps) {
  function handleDragStart(event: DragEvent<HTMLButtonElement>, key: ElementKindKey) {
    event.dataTransfer.setData(TRD_KIND_DRAG_TYPE, key);
    event.dataTransfer.effectAllowed = "copy";
  }

  return (
    <aside
      className={collapsed ? "trd-palette-dock is-collapsed" : "trd-palette-dock"}
      aria-label="Element palette"
      inert={collapsed}
    >
      <h5>Elements</h5>
      {ELEMENT_KINDS.map((entry) => {
        const supported = entry.nodeKind !== null;
        return (
          <button
            key={entry.key}
            type="button"
            className={armedKey === entry.key ? "trd-chip is-armed" : "trd-chip"}
            aria-pressed={supported ? armedKey === entry.key : undefined}
            disabled={!supported}
            draggable={supported}
            title={
              supported
                ? `${entry.label} — click to arm Place mode, or drag into the scene`
                : `${entry.label} — no document kind for this element yet`
            }
            onDragStart={supported ? (event) => handleDragStart(event, entry.key) : undefined}
            onClick={() => supported && onArm(entry.key)}
          >
            <span className="trd-glyph trd-glyph-mark">
              <KindMark kind={entry.key} />
            </span>
            {entry.label}
          </button>
        );
      })}
      <button type="button" className="trd-chip" title="Kind browser (⇧⌘K)" onClick={onOpenKindBrowser}>
        <span className="trd-glyph trd-glyph-mark">
          <MoreMark />
        </span>
        More
      </button>
    </aside>
  );
}
