"use client";

// Cell-renderer registry. Ported from npl-mcp and retuned to tobornalp's design
// tokens. Resolves a string `render` hint on a column/detail-field into a ReactNode
// — `render: "slugChip"` "just works" across all domains. Value-based + cross-domain
// only; domain-specific presentation stays a function renderer in the descriptor.
//
// Division of labor: this owns STRUCTURE + a11y (copyable chips, dot+label, title
// tooltips). statusChip emits a `data-status` hook so CSS can map each status to a
// palette; we never hardcode hue here.
import type { ReactNode } from "react";
import type { CellRenderHint, CellRenderer } from "./types";

const CHIP_BASE =
  "inline-block rounded px-1.5 py-0.5 font-mono text-xs text-text-secondary align-middle";
const MUTATED = "text-text-muted";

/** Human-relative time with the absolute timestamp as a title (a11y + hover). */
function RelativeDate({ value }: { value: unknown }) {
  if (value == null || value === "") return <span className={MUTATED}>—</span>;
  const iso = String(value);
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return <>{iso}</>;
  const diff = Date.now() - d.getTime();
  const mins = Math.floor(diff / 60000);
  let rel: string;
  if (mins < 1) rel = "just now";
  else if (mins < 60) rel = `${mins}m ago`;
  else if (mins < 1440) rel = `${Math.floor(mins / 60)}h ago`;
  else rel = `${Math.floor(mins / 1440)}d ago`;
  return (
    <time dateTime={iso} title={d.toLocaleString()} className="text-text-secondary">
      {rel}
    </time>
  );
}

/** Deterministic hue from a string so an identity's dot is stable across renders. */
export function hueFor(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 360;
  return h;
}

function truncMiddle(s: string, head = 6, tail = 4): string {
  return s.length <= head + tail + 1 ? s : `${s.slice(0, head)}…${s.slice(-tail)}`;
}

/**
 * The registry. Each renderer takes the cell value (row[column.key]) + the full row.
 */
export const CELL_RENDERERS: Record<
  CellRenderHint,
  (value: unknown, row: Record<string, unknown>) => ReactNode
> = {
  // Mono slug chip.
  slugChip: (value) =>
    value == null || value === "" ? (
      <span className={MUTATED}>—</span>
    ) : (
      <span className={`${CHIP_BASE} bg-surface-alt`} title={String(value)}>
        {String(value)}
      </span>
    ),

  // Middle-truncated UUID; full value revealed via title.
  idChip: (value) =>
    value == null || value === "" ? (
      <span className={MUTATED}>—</span>
    ) : (
      <span className={`${CHIP_BASE} bg-surface-alt`} title={String(value)}>
        {truncMiddle(String(value))}
      </span>
    ),

  // Status pill. Color comes from CSS via the data-status hook, never here.
  statusChip: (value) =>
    value == null || value === "" ? (
      <span className={MUTATED}>—</span>
    ) : (
      <span
        className="inline-block rounded-full border border-border px-2 py-0.5 text-xs text-text-secondary align-middle"
        data-status={String(value)}
      >
        {String(value)}
      </span>
    ),

  relativeDate: (value) => <RelativeDate value={value} />,

  // Color-dot + label identity cell.
  identityChip: (value) => {
    if (value == null || value === "") return <span className={MUTATED}>—</span>;
    const label = String(value);
    return (
      <span className="inline-flex items-center gap-1.5 align-middle">
        <span
          className="inline-block h-2 w-2 rounded-full"
          aria-hidden
          style={{ background: `hsl(${hueFor(label)} 55% 45%)` }}
        />
        <span className="text-text-secondary">{label}</span>
      </span>
    );
  },
};

/** True when a `render` value is a registry hint (vs a function renderer). */
export function isRenderHint(r: unknown): r is CellRenderHint {
  return typeof r === "string" && r in CELL_RENDERERS;
}

/**
 * Resolve a column/detail-field `render` to a ReactNode — shared by DataTable +
 * DetailView so cells look identical in the list and the detail. A function runs
 * against the row; a hint resolves through the registry; absent falls back to the
 * raw value (em-dash for empty).
 */
export function renderField<T>(render: CellRenderer<T> | undefined, key: string, row: T): ReactNode {
  if (typeof render === "function") return render(row);
  if (isRenderHint(render))
    return CELL_RENDERERS[render]((row as Record<string, unknown>)[key], row as Record<string, unknown>);
  const v = (row as Record<string, unknown>)[key];
  return v == null || v === "" ? <span className={MUTATED}>—</span> : <>{String(v)}</>;
}
