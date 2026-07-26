"use client";

// SavedViewsToolbar — save/load/delete persisted list views for a console table.
// Companion to DataTable's saved-view interop (onStateChange + appliedView):
//   - "Save current as…" captures the parent's live ViewSnapshot and POSTs it
//     under SavedView.config (entity_type/view_type scoped).
//   - Picking a view parses its config back into a ViewSnapshot and hands it to
//     onApply, which the parent pushes into DataTable via appliedView + nonce.
//   - Per-view delete removes it server-side and refetches the list.
//
// Self-contained: no new npm deps. Uses the same accessible popover pattern as
// DataTable's FacetMultiSelect (trigger button + absolute menu + outside-click
// dismiss + Esc restore-focus) and the shared Dialog/Input/Button primitives.
import { useCallback, useEffect, useRef, useState } from "react";
import { api, type SavedView, type SavedViewInput } from "@/lib/api";
import { Btn, Input, Dialog, FieldLabel } from "@/components/ui";
import type { ViewSnapshot } from "@/components/console/DataTable";
import { cn } from "@/lib/cn";

export interface SavedViewScope {
  entity_type: string;
  view_type: string;
  /** Optional project scope (omit for org-wide views). */
  project_id?: string;
}

export interface SavedViewsToolbarProps {
  orgId: string;
  scope: SavedViewScope;
  /** Read the table's current view (parent keeps a ref via DataTable.onStateChange). */
  getCurrentSnapshot: () => ViewSnapshot | null;
  /** Push a saved view back into the table. */
  onApply: (snapshot: ViewSnapshot) => void;
}

/**
 * Defensive parse of SavedView.config → ViewSnapshot. A malformed/legacy config
 * yields null (apply silently no-ops) rather than throwing into the table state.
 */
export function parseViewConfig(config: unknown): ViewSnapshot | null {
  if (!config || typeof config !== "object") return null;
  const c = config as Record<string, unknown>;
  const rawFacets = c.facets;
  const facets: Record<string, string | string[]> = {};
  if (rawFacets && typeof rawFacets === "object") {
    for (const [k, v] of Object.entries(rawFacets as Record<string, unknown>)) {
      if (typeof v === "string") facets[k] = v;
      else if (Array.isArray(v) && v.every((x) => typeof x === "string")) facets[k] = v;
    }
  }
  return {
    facets,
    sortKey: typeof c.sortKey === "string" ? c.sortKey : null,
    sortDir: c.sortDir === "desc" ? "desc" : "asc",
    query: typeof c.query === "string" ? c.query : "",
  };
}

export function SavedViewsToolbar({ orgId, scope, getCurrentSnapshot, onApply }: SavedViewsToolbarProps) {
  const [views, setViews] = useState<SavedView[]>([]);
  const [loading, setLoading] = useState(true);
  const [menuOpen, setMenuOpen] = useState(false);
  const [saveOpen, setSaveOpen] = useState(false);
  const [name, setName] = useState("");
  const [saving, setSaving] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const triggerRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  const fetchViews = useCallback(async () => {
    if (!orgId) return;
    try {
      const { saved_views } = await api.listSavedViews(orgId, {
        entity_type: scope.entity_type,
        view_type: scope.view_type,
        project_id: scope.project_id,
      });
      setViews(saved_views ?? []);
    } catch {
      // Non-fatal: the toolbar still works for saving; just show nothing loaded.
      setViews([]);
    } finally {
      setLoading(false);
    }
  }, [orgId, scope.entity_type, scope.view_type, scope.project_id]);

  useEffect(() => {
    fetchViews();
  }, [fetchViews]);

  // Outside-click dismiss (same contract as FacetMultiSelect).
  useEffect(() => {
    if (!menuOpen) return;
    function onDown(e: PointerEvent) {
      const t = e.target as Node;
      if (!menuRef.current?.contains(t) && !triggerRef.current?.contains(t)) setMenuOpen(false);
    }
    document.addEventListener("pointerdown", onDown);
    return () => document.removeEventListener("pointerdown", onDown);
  }, [menuOpen]);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    const snapshot = getCurrentSnapshot();
    if (!snapshot || !name.trim()) return;
    setSaving(true);
    setError(null);
    try {
      const payload: SavedViewInput = {
        name: name.trim(),
        entity_type: scope.entity_type,
        view_type: scope.view_type,
        project_id: scope.project_id,
        // config is typed Record<string, unknown> on the wire; ViewSnapshot is plain JSON.
        config: snapshot as unknown as Record<string, unknown>,
      };
      await api.createSavedView(orgId, payload);
      setName("");
      setSaveOpen(false);
      await fetchViews();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save view");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(id: string) {
    setBusyId(id);
    setError(null);
    try {
      await api.deleteSavedView(orgId, id);
      await fetchViews();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete view");
    } finally {
      setBusyId(null);
    }
  }

  function handleApply(v: SavedView) {
    const snap = parseViewConfig(v.config);
    if (snap) {
      onApply(snap);
      setMenuOpen(false);
      triggerRef.current?.focus();
    } else {
      setError(`Saved view "${v.name}" has an unrecognized config.`);
    }
  }

  return (
    <div className="flex items-center gap-2">
      <div className="relative inline-block">
        <Btn
          ref={triggerRef}
          type="button"
          aria-haspopup="true"
          aria-expanded={menuOpen}
          onClick={() => setMenuOpen((o) => !o)}
          onKeyDown={(e) => {
            if (!menuOpen && (e.key === "ArrowDown" || e.key === "ArrowUp")) {
              e.preventDefault();
              setMenuOpen(true);
            }
          }}
        >
          Views
          <span aria-hidden className="text-[11px] text-faint">
            ▾
          </span>
        </Btn>
        {menuOpen && (
          <div
            ref={menuRef}
            className="absolute left-0 z-30 mt-1 min-w-[14rem] rounded-card border border-line2 bg-panel py-1 shadow-pop"
            role="menu"
            aria-label="Saved views"
            onKeyDown={(e) => {
              if (e.key === "Escape") {
                e.preventDefault();
                setMenuOpen(false);
                triggerRef.current?.focus();
              }
            }}
          >
            {loading ? (
              <p className="px-3 py-1.5 text-[12px] text-faint">Loading…</p>
            ) : views.length === 0 ? (
              <p className="px-3 py-1.5 text-[12px] text-faint">No saved views yet</p>
            ) : (
              views.map((v) => (
                <div
                  key={v.id}
                  className="group flex items-center justify-between gap-2 px-2 py-1 hover:bg-sel"
                >
                  <button
                    type="button"
                    role="menuitem"
                    className="flex-1 truncate text-left text-[12px] text-ink"
                    title={`Apply "${v.name}"`}
                    onClick={() => handleApply(v)}
                  >
                    {v.name}
                  </button>
                  <button
                    type="button"
                    aria-label={`Delete view ${v.name}`}
                    title="Delete view"
                    disabled={busyId === v.id}
                    onClick={() => handleDelete(v.id)}
                    className={cn(
                      "rounded-pill px-1.5 py-0.5 text-[12px] text-faint hover:bg-error/10 hover:text-error focus:outline-none disabled:opacity-50",
                    )}
                  >
                    ×
                  </button>
                </div>
              ))
            )}
            <div className="mt-1 border-t border-line">
              <button
                type="button"
                role="menuitem"
                className="block w-full px-3 py-1.5 text-left text-[12px] text-acc hover:bg-sel"
                onClick={() => {
                  setSaveOpen(true);
                  setMenuOpen(false);
                }}
              >
                Save current as…
              </button>
            </div>
          </div>
        )}
      </div>

      {error && <span className="text-[11px] text-error">{error}</span>}

      <Dialog
        open={saveOpen}
        onClose={() => {
          setSaveOpen(false);
          setError(null);
        }}
        title="Save current view"
        footer={
          <>
            <Btn
              onClick={() => {
                setSaveOpen(false);
                setError(null);
              }}
            >
              Cancel
            </Btn>
            <Btn type="submit" variant="primary" form="save-view-form" disabled={saving || !name.trim()}>
              {saving ? "Saving…" : "Save"}
            </Btn>
          </>
        }
      >
        <form id="save-view-form" onSubmit={handleSave} className="space-y-3">
          <FieldLabel
            label="View name"
            hint="Saves the current filters, sort, and search as a personal list view."
          >
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Critical bugs this iteration"
              autoFocus
            />
          </FieldLabel>
        </form>
      </Dialog>
    </div>
  );
}
