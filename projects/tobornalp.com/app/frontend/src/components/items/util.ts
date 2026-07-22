"use client";

// Small helpers shared by the item-detail custom sections (Comments / Activity /
// Links). Kept here so each section file stays focused; not exported outside this
// folder. The shared console `RelativeDate` renderer (lib/console/render-hints) is
// not exported, and these sections sit BELOW the descriptor-driven detail view, so
// a local relative-time helper is the honest seam.

import type { Item } from "@/lib/api";

/** Human-relative time ("just now" / "5m ago" / "3h ago" / "2d ago"), UTC-safe. */
export function timeAgo(iso?: string | null): string {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  const mins = Math.floor((Date.now() - d.getTime()) / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  if (mins < 1440) return `${Math.floor(mins / 60)}h ago`;
  return `${Math.floor(mins / 1440)}d ago`;
}

/**
 * Link types accepted by addItemLink. Mirrors the backend's item_links.link_type
 * domain (blocks / blocked_by / relates_to / duplicates). Direction semantics:
 * "this item {link_type} target" — e.g. link_type=blocks, target=T ⇒ this blocks T.
 */
export const LINK_TYPES: Array<{ value: string; label: string }> = [
  { value: "blocks", label: "Blocks" },
  { value: "blocked_by", label: "Blocked by" },
  { value: "relates_to", label: "Relates to" },
  { value: "duplicates", label: "Duplicates" },
];

/** Stable display label for an item in a picker / list cell. */
export function itemLabel(it: Item): string {
  return it.key ? `${it.key} · ${it.title}` : it.title;
}

/** Short id chip for UUIDs (head…tail) with full value for hover. */
export function shortId(id: string): string {
  return id.length <= 11 ? id : `${id.slice(0, 8)}…${id.slice(-4)}`;
}
