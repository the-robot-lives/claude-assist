"use client";

// DataTable — config-driven console list primitive. Ported from npl-mcp and
// retuned to tobornalp's design tokens + Button primitive. Driven entirely by a
// ConsoleDescriptor: sort / filter / paginate, row + empty/loading/error states,
// density, bulk-select, and an accessible row kebab.
//
// a11y: the table is a roving-tabindex grid — ArrowUp/Down move the active row,
// Home/End jump, Enter opens detail; only the active row is in the tab order.
// Sortable headers are buttons with aria-sort. The kebab is a real menu-button
// (aria-haspopup/expanded, arrow roving, Esc-restores-focus, outside-click dismiss).
// visibleWhen gates action VISIBILITY only; the server guard stays deny-closed.
import { useState, useEffect, useMemo, useRef, useCallback } from "react";
import type { ReactNode, KeyboardEvent } from "react";
import type {
  ConsoleDescriptor,
  ConsoleContext,
  ColumnDef,
  ActionDef,
  BuiltinRowAction,
  FacetOption,
} from "@/lib/console/types";
import { renderField } from "@/lib/console/render-hints";
import { Button, Input, Select } from "@/components/ui";
import { cn } from "@/lib/cn";

type Row = Record<string, unknown>;

/**
 * Serializable snapshot of the table's current view state (facets + sort +
 * search). Emitted via `onStateChange` so a parent can capture the live view
 * (for "Save view"), and accepted via `appliedView` to restore one. The shape is
 * deliberately plain JSON so it round-trips through SavedView.config
 * (Record<string, unknown>) without coercion.
 */
export interface ViewSnapshot {
  facets: Record<string, string | string[]>;
  sortKey: string | null;
  sortDir: "asc" | "desc";
  query: string;
}

export interface DataTableProps<T, TInput> {
  descriptor: ConsoleDescriptor<T, TInput>;
  ctx: ConsoleContext;
  /** Row opened (primary-cell click or Enter) → detail. */
  onOpenRow?: (row: T) => void;
  onEditRow?: (row: T) => void;
  onDeleteRow?: (row: T) => void;
  /** Handler for bare custom row-action keys (e.g. "archive"). */
  onAction?: (key: string, row: T) => void;
  /** Bump to refetch IN PLACE after a create/edit/delete — preserves state. */
  refreshKey?: number;
  /** Per-row class hook — e.g. mark the active scope / unread / selected. */
  rowClassName?: (row: T, ctx: ConsoleContext) => string | undefined;
  /** Resolved options for `dynamic` facets, keyed by filter key. */
  facetOptions?: Record<string, { value: string; label: string }[]>;
  /** Embedded related mini-table: drops the filter/pagination chrome, fixed scope. */
  embedded?: boolean;
  /** Extra api.list opts (related-table scope query, or a parent facet). */
  scope?: Record<string, unknown>;
  density?: "comfortable" | "compact";
  pageSize?: number;
  /**
   * Emitted whenever facets / sort / search change so a parent can capture the
   * live view for "Save current view". Stored in a ref internally (no re-render
   * loop); fire-and-forget — the parent should NOT setState from this.
   */
  onStateChange?: (snapshot: ViewSnapshot) => void;
  /**
   * Restore a previously saved view. When `appliedViewNonce` changes (and is
   * non-zero), facets / sort / search reset to this snapshot. The nonce (not the
   * object identity) is the trigger so re-applying the SAME view still works and
   * a parent re-render that reconstructs the object does not.
   */
  appliedView?: ViewSnapshot;
  appliedViewNonce?: number;
}

function cell(row: Row, key: string): unknown {
  return row[key];
}

export function DataTable<T, TInput>({
  descriptor,
  ctx,
  onOpenRow,
  onEditRow,
  onDeleteRow,
  onAction,
  refreshKey = 0,
  rowClassName,
  facetOptions,
  embedded = false,
  scope,
  density = "comfortable",
  pageSize = 25,
  onStateChange,
  appliedView,
  appliedViewNonce,
}: DataTableProps<T, TInput>) {
  const { columns, filters, labels, idKey = "id", actions } = descriptor;

  const [rows, setRows] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [facets, setFacets] = useState<Record<string, string | string[]>>({});
  const [sortKey, setSortKey] = useState<string | null>(null);
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");
  const [page, setPage] = useState(0);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [activeRow, setActiveRow] = useState(0);

  const rowId = useCallback((row: T) => String((row as Row)[idKey]), [idKey]);

  // Fetch on mount + whenever server-side facet scope changes (search/sort/paginate
  // stay client-side over the result set — console scale, deterministic).
  useEffect(() => {
    let live = true;
    setLoading(true);
    setError(null);
    const opts: Record<string, unknown> = { ...scope };
    for (const [k, v] of Object.entries(facets)) {
      if (Array.isArray(v) ? v.length > 0 : v) opts[k] = v;
    }
    descriptor.api
      .list(ctx.orgId, opts)
      .then((data) => {
        if (!live) return;
        setRows(data);
      })
      .catch((e: unknown) => {
        if (!live) return;
        setError(e instanceof Error ? e.message : `Failed to load ${labels.plural.toLowerCase()}`);
        setRows([]);
      })
      .finally(() => live && setLoading(false));
    return () => {
      live = false;
    };
  }, [descriptor.api, ctx.orgId, facets, scope, refreshKey, labels.plural]);

  // Reset paging/active row only when the dataset SCOPE changes — not on refresh-in-place.
  useEffect(() => {
    setPage(0);
    setActiveRow(0);
  }, [ctx.orgId, facets, scope]);

  // ── Saved-view interop (additive; no-op unless the parent opts in) ───────────
  // Keep the latest onStateChange in a ref so the emit effect doesn't take the
  // callback as a dependency (the parent typically passes a fresh closure each
  // render; depending on it would either loop or fire every render).
  const onStateChangeRef = useRef(onStateChange);
  onStateChangeRef.current = onStateChange;

  // Emit the current view whenever facets/sort/search change. Fire-and-forget:
  // the parent MUST NOT setState from this (it's a snapshot capture for "Save").
  useEffect(() => {
    onStateChangeRef.current?.({ facets, sortKey, sortDir, query });
  }, [facets, sortKey, sortDir, query]);

  // Restore a saved view: when the nonce bumps (and is non-zero), reset facets /
  // sort / search to the supplied snapshot. Keyed on the nonce — NOT the object
  // identity — so a parent re-render that rebuilds the snapshot object is a
  // no-op and re-applying the SAME view still resets state.
  useEffect(() => {
    if (!appliedViewNonce || !appliedView) return;
    setFacets(appliedView.facets ?? {});
    setSortKey(appliedView.sortKey ?? null);
    setSortDir(appliedView.sortDir === "desc" ? "desc" : "asc");
    setQuery(appliedView.query ?? "");
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [appliedViewNonce]);

  const searched = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return rows;
    return rows.filter((r) =>
      columns.some((c) => String(cell(r as Row, c.key) ?? "").toLowerCase().includes(q)),
    );
  }, [rows, query, columns]);

  const sorted = useMemo(() => {
    if (!sortKey) return searched;
    const dir = sortDir === "asc" ? 1 : -1;
    return [...searched].sort((a, b) => {
      const av = cell(a as Row, sortKey);
      const bv = cell(b as Row, sortKey);
      if (av == null) return 1;
      if (bv == null) return -1;
      if (typeof av === "number" && typeof bv === "number") return (av - bv) * dir;
      return String(av).localeCompare(String(bv)) * dir;
    });
  }, [searched, sortKey, sortDir]);

  const pageCount = Math.max(1, Math.ceil(sorted.length / pageSize));
  const pageRows = embedded ? sorted : sorted.slice(page * pageSize, page * pageSize + pageSize);

  function toggleSort(key: string) {
    if (sortKey === key) setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    else {
      setSortKey(key);
      setSortDir("asc");
    }
  }

  function onRowsKeyDown(e: KeyboardEvent<HTMLTableSectionElement>) {
    const n = pageRows.length;
    if (n === 0) return;
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        setActiveRow((i) => Math.min(n - 1, i + 1));
        break;
      case "ArrowUp":
        e.preventDefault();
        setActiveRow((i) => Math.max(0, i - 1));
        break;
      case "Home":
        e.preventDefault();
        setActiveRow(0);
        break;
      case "End":
        e.preventDefault();
        setActiveRow(n - 1);
        break;
      case "Enter":
        e.preventDefault();
        if (onOpenRow && pageRows[activeRow]) onOpenRow(pageRows[activeRow]);
        break;
      default:
        break;
    }
  }

  const bulkEnabled = !embedded && (actions?.bulkActions?.length ?? 0) > 0;
  const compact = density === "compact";

  function renderCell(col: ColumnDef<T>, row: T): ReactNode {
    return renderField(col.render, col.key, row);
  }

  if (loading)
    return (
      <p className="px-3 py-6 font-mono text-sm text-[var(--faint)]" role="status">
        loading {labels.plural.toLowerCase()}…
      </p>
    );
  if (error)
    return (
      <div className="flex items-center gap-3 px-3 py-4 font-mono text-sm text-[var(--err)]" role="alert">
        <span>{error}</span>
        <Button variant="outline" size="sm" onClick={() => setFacets((f) => ({ ...f }))}>
          Retry
        </Button>
      </div>
    );

  return (
    <div className="overflow-hidden rounded-[var(--r)] border border-[var(--line)] bg-[var(--panel)] shadow-[var(--card-shadow)]">
      {!embedded && (filters?.length ?? 0) > 0 && (
        <div className="flex flex-wrap items-center gap-2 border-b border-[var(--line)] bg-[var(--panel2)] p-3" role="search">
          {filters!.map((f) => {
            if (f.type === "search") {
              return (
                <Input
                  key={f.key}
                  type="search"
                  className="max-w-xs"
                  placeholder={`${f.label}…`}
                  aria-label={f.label}
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                />
              );
            }
            const opts = (f.dynamic ? facetOptions?.[f.key] : f.options) ?? [];
            if (f.multi) {
              const sel = Array.isArray(facets[f.key]) ? (facets[f.key] as string[]) : [];
              return (
                <FacetMultiSelect
                  key={f.key}
                  label={f.label}
                  options={opts}
                  selected={sel}
                  onChange={(vals) => setFacets((prev) => ({ ...prev, [f.key]: vals }))}
                />
              );
            }
            const single = typeof facets[f.key] === "string" ? (facets[f.key] as string) : "";
            return (
              <Select
                key={f.key}
                className="max-w-[12rem]"
                aria-label={f.label}
                value={single}
                onChange={(e) => setFacets((prev) => ({ ...prev, [f.key]: e.target.value }))}
              >
                <option value="">{f.label}: all</option>
                {opts.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </Select>
            );
          })}
        </div>
      )}

      {pageRows.length === 0 ? (
        <p className="px-3 py-6 font-mono text-sm text-[var(--faint)]">No {labels.plural.toLowerCase()} found.</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-sm">
            <thead>
              <tr className="bg-[var(--panel2)]">
                {bulkEnabled && <th scope="col" className="w-8 px-3 py-2" aria-label="Select" />}
                {columns.map((c) => {
                  const isSorted = sortKey === c.key;
                  return (
                    <th
                      key={c.key}
                      scope="col"
                      style={c.width ? { width: c.width } : undefined}
                      aria-sort={isSorted ? (sortDir === "asc" ? "ascending" : "descending") : undefined}
                      className={cn(
                        "px-3 py-2 text-left font-mono text-[10px] font-semibold uppercase tracking-wider text-[var(--faint)]",
                        c.align === "right" && "text-right",
                        c.align === "center" && "text-center",
                      )}
                    >
                      {c.sortable ? (
                        <button
                          type="button"
                          className="inline-flex items-center gap-1 hover:text-[var(--ink)]"
                          onClick={() => toggleSort(c.key)}
                        >
                          {c.label}
                          <span aria-hidden className="text-xs">
                            {isSorted ? (sortDir === "asc" ? "▲" : "▼") : ""}
                          </span>
                        </button>
                      ) : (
                        c.label
                      )}
                    </th>
                  );
                })}
                <th scope="col" className="w-10 px-3 py-2" aria-label="Actions" />
              </tr>
            </thead>
            <tbody onKeyDown={onRowsKeyDown}>
              {pageRows.map((row, i) => {
                const id = rowId(row);
                return (
                  <tr
                    key={id}
                    className={cn(
                      "border-t border-[var(--line)] outline-none",
                      compact ? "py-0.5" : "",
                      i === activeRow ? "bg-[var(--sel)]" : "hover:bg-[var(--sel)]",
                      rowClassName?.(row, ctx),
                    )}
                    tabIndex={i === activeRow ? 0 : -1}
                    aria-selected={selected.has(id) || undefined}
                    onFocus={() => setActiveRow(i)}
                  >
                    {bulkEnabled && (
                      <td className="px-3 py-2">
                        <input
                          type="checkbox"
                          aria-label={`Select row ${i + 1}`}
                          checked={selected.has(id)}
                          onChange={(e) =>
                            setSelected((prev) => {
                              const next = new Set(prev);
                              if (e.target.checked) next.add(id);
                              else next.delete(id);
                              return next;
                            })
                          }
                        />
                      </td>
                    )}
                    {columns.map((c) => (
                      <td
                        key={c.key}
                        className={cn(
                          "px-3 py-2 tabular-nums text-[var(--ink)]",
                          c.align === "right" && "text-right",
                          c.align === "center" && "text-center",
                        )}
                      >
                        {c.primary && onOpenRow ? (
                          <button
                            type="button"
                            className="text-left text-[var(--ink)] hover:text-[var(--acc)] hover:underline"
                            onClick={() => onOpenRow(row)}
                          >
                            {renderCell(c, row)}
                          </button>
                        ) : (
                          renderCell(c, row)
                        )}
                      </td>
                    ))}
                    <td className="px-3 py-2 text-right">
                      <RowMenu
                        row={row}
                        ctx={ctx}
                        actions={actions?.rowActions}
                        api={descriptor.api}
                        onOpenRow={onOpenRow}
                        onEditRow={onEditRow}
                        onDeleteRow={onDeleteRow}
                        onAction={onAction}
                        canEdit={actions?.canEdit}
                        canDelete={actions?.canDelete}
                        builtinLabels={actions?.builtinLabels}
                        label={labels.singular}
                      />
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {!embedded && pageCount > 1 && (
        <nav className="flex items-center justify-center gap-3 border-t border-[var(--line)] p-3 text-sm" aria-label="Pagination">
          <Button variant="outline" size="sm" disabled={page === 0} onClick={() => setPage((p) => p - 1)}>
            ← Prev
          </Button>
          <span className="font-mono tabular-nums text-[var(--mut)]" aria-live="polite">
            Page {page + 1} of {pageCount}
          </span>
          <Button
            variant="outline"
            size="sm"
            disabled={page >= pageCount - 1}
            onClick={() => setPage((p) => p + 1)}
          >
            Next →
          </Button>
        </nav>
      )}
    </div>
  );
}

// Accessible per-row kebab menu-button (same focus contract as the source):
// aria-haspopup/expanded, arrow-key roving, Home/End, Esc-closes-and-restores-focus,
// outside-click dismiss. Built-ins (view/edit/delete) wire from the api + callbacks;
// custom ActionDefs honor their visibleWhen(ctx) gate (visibility only).
function RowMenu<T, TInput>({
  row,
  ctx,
  actions,
  api,
  onOpenRow,
  onEditRow,
  onDeleteRow,
  onAction,
  canEdit,
  canDelete,
  builtinLabels,
  label,
}: {
  row: T;
  ctx: ConsoleContext;
  actions?: (BuiltinRowAction | (string & {}) | ActionDef<T>)[];
  api: ConsoleDescriptor<T, TInput>["api"];
  onOpenRow?: (row: T) => void;
  onEditRow?: (row: T) => void;
  onDeleteRow?: (row: T) => void;
  onAction?: (key: string, row: T) => void;
  canEdit?: (row: T, ctx: ConsoleContext) => boolean;
  canDelete?: (row: T, ctx: ConsoleContext) => boolean;
  builtinLabels?: { view?: string; edit?: string; delete?: string };
  label: string;
}) {
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const itemRefs = useRef<(HTMLButtonElement | null)[]>([]);

  type Item = { key: string; label: string; run: () => void | Promise<void>; danger?: boolean };
  const items: Item[] = [];
  const titleCase = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);
  const list: (BuiltinRowAction | (string & {}) | ActionDef<T>)[] = actions ?? ["view", "edit", "delete"];
  for (const a of list) {
    if (a === "view" && onOpenRow)
      items.push({ key: "view", label: builtinLabels?.view ?? "View", run: () => onOpenRow(row) });
    else if (a === "edit" && api.update && onEditRow && (canEdit?.(row, ctx) ?? true))
      items.push({ key: "edit", label: builtinLabels?.edit ?? "Edit", run: () => onEditRow(row) });
    else if (a === "delete" && api.remove && onDeleteRow && (canDelete?.(row, ctx) ?? true))
      items.push({ key: "delete", label: builtinLabels?.delete ?? "Delete", run: () => onDeleteRow(row), danger: true });
    else if (typeof a === "object") {
      if (a.visibleWhen && !a.visibleWhen(row, ctx)) continue;
      items.push({ key: a.key, label: a.label, run: () => a.run(row, ctx), danger: a.danger });
    } else if (typeof a === "string" && onAction) {
      items.push({ key: a, label: titleCase(a), run: () => onAction(a, row) });
    }
  }

  useEffect(() => {
    if (!open) return;
    function onDown(e: PointerEvent) {
      const t = e.target as Node;
      if (!menuRef.current?.contains(t) && !triggerRef.current?.contains(t)) setOpen(false);
    }
    document.addEventListener("pointerdown", onDown);
    return () => document.removeEventListener("pointerdown", onDown);
  }, [open]);

  useEffect(() => {
    if (open) itemRefs.current[active]?.focus();
  }, [open, active]);

  if (items.length === 0) return null;

  function close(restore: boolean) {
    setOpen(false);
    if (restore) triggerRef.current?.focus();
  }

  function onMenuKey(e: KeyboardEvent<HTMLDivElement>) {
    const n = items.length;
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        setActive((i) => (i + 1) % n);
        break;
      case "ArrowUp":
        e.preventDefault();
        setActive((i) => (i - 1 + n) % n);
        break;
      case "Home":
        e.preventDefault();
        setActive(0);
        break;
      case "End":
        e.preventDefault();
        setActive(n - 1);
        break;
      case "Escape":
        e.preventDefault();
        close(true);
        break;
      case "Tab":
        setOpen(false);
        break;
      default:
        break;
    }
  }

  return (
    <div className="relative inline-block text-left">
      <button
        ref={triggerRef}
        type="button"
        className="rounded px-2 py-1 text-[var(--faint)] hover:bg-[var(--sel)] hover:text-[var(--ink)] focus:outline-none focus:ring-2 focus:ring-[var(--acc-line)]"
        aria-haspopup="true"
        aria-expanded={open}
        aria-label={`${label} actions`}
        onClick={() => (open ? close(false) : (setActive(0), setOpen(true)))}
        onKeyDown={(e) => {
          if (!open && (e.key === "ArrowDown" || e.key === "ArrowUp")) {
            e.preventDefault();
            setActive(0);
            setOpen(true);
          }
        }}
      >
        ⋯
      </button>
      {open && (
        <div
          ref={menuRef}
          className="absolute right-0 z-20 mt-1 min-w-[10rem] rounded-[var(--r-sm)] border border-[var(--line)] bg-[var(--panel2)] py-1 shadow-[var(--card-shadow)]"
          role="menu"
          aria-label={`${label} actions`}
          onKeyDown={onMenuKey}
        >
          {items.map((it, i) => (
            <button
              key={it.key}
              ref={(el) => {
                itemRefs.current[i] = el;
              }}
              type="button"
              role="menuitem"
              tabIndex={open && i === active ? 0 : -1}
              className={cn(
                "block w-full px-3 py-1.5 text-left text-sm hover:bg-[var(--sel)] focus:outline-none",
                it.danger ? "text-[var(--err)] hover:bg-[var(--err-bg)]" : "text-[var(--ink)]",
              )}
              onClick={() => {
                void it.run();
                close(true);
              }}
            >
              {it.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

// Multi-select facet: a keyboard-accessible checklist popover — pick several values,
// OR-within-facet, passed to api.list as an array. Same focus contract as the kebab.
// NOTE: tobornalp's listItems does not serialize array params, so prefer single-select
// facets unless the api adapter coerces arrays.
function FacetMultiSelect({
  label,
  options,
  selected,
  onChange,
}: {
  label: string;
  options: FacetOption[];
  selected: string[];
  onChange: (values: string[]) => void;
}) {
  const [open, setOpen] = useState(false);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    function onDown(e: PointerEvent) {
      const t = e.target as Node;
      if (!menuRef.current?.contains(t) && !triggerRef.current?.contains(t)) setOpen(false);
    }
    document.addEventListener("pointerdown", onDown);
    return () => document.removeEventListener("pointerdown", onDown);
  }, [open]);

  function toggle(value: string, checked: boolean) {
    onChange(checked ? [...selected, value] : selected.filter((v) => v !== value));
  }

  const summary = selected.length === 0 ? `${label}: all` : `${label}: ${selected.length}`;

  return (
    <div className="relative inline-block">
      <button
        ref={triggerRef}
        type="button"
        className="inline-flex items-center gap-1 rounded-[var(--r-sm)] border border-[var(--line2)] bg-[var(--panel2)] px-2 py-1.5 text-sm text-[var(--ink)] hover:bg-[var(--sel)]"
        aria-haspopup="true"
        aria-expanded={open}
        onClick={() => setOpen((o) => !o)}
      >
        {summary}
        <span aria-hidden className="text-xs text-[var(--faint)]">
          ▾
        </span>
      </button>
      {open && (
        <div
          ref={menuRef}
          className="absolute left-0 z-20 mt-1 min-w-[12rem] rounded-[var(--r-sm)] border border-[var(--line)] bg-[var(--panel2)] py-1 shadow-[var(--card-shadow)]"
          role="group"
          aria-label={label}
          onKeyDown={(e) => {
            if (e.key === "Escape") {
              e.preventDefault();
              setOpen(false);
              triggerRef.current?.focus();
            }
          }}
        >
          {options.length === 0 ? (
            <p className="px-3 py-1.5 text-sm text-[var(--faint)]">No options</p>
          ) : (
            options.map((o) => (
              <label key={o.value} className="flex cursor-pointer items-center gap-2 px-3 py-1.5 text-sm text-[var(--ink)] hover:bg-[var(--sel)]">
                <input
                  type="checkbox"
                  checked={selected.includes(o.value)}
                  onChange={(e) => toggle(o.value, e.target.checked)}
                />
                {o.label}
              </label>
            ))
          )}
          {selected.length > 0 && (
            <button
              type="button"
              className="mt-1 block w-full border-t border-[var(--line)] px-3 py-1.5 text-left text-xs text-[var(--faint)] hover:bg-[var(--sel)] hover:text-[var(--ink)]"
              onClick={() => onChange([])}
            >
              Clear
            </button>
          )}
        </div>
      )}
    </div>
  );
}
