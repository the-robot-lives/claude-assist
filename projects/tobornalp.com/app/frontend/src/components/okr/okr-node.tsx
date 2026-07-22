"use client";

import { useState } from "react";
import { api, type ObjectiveTreeNode, type KeyResult, type RollupStrategy } from "@/lib/api";
import { Button, Input, Select, ProgressBar, StatusBadge, Spinner } from "@/components/ui";
import { toast } from "sonner";
import { canReparent } from "./reorder";
import { KrEditor } from "./kr-editor";
import { CheckinModal } from "./checkin-modal";

const STRATEGY_LABEL: Record<RollupStrategy, string> = {
  weighted_avg: "Weighted avg",
  min_children: "Min child",
  custom: "Custom",
};

// Shared context threaded through the recursive tree. Keeps per-node props small.
export interface OkrNodeCtx {
  orgId: string;
  forest: ObjectiveTreeNode[];
  expanded: Set<string>;
  toggle: (id: string) => void;
  reload: () => void;
  dragId: string | null;
  setDragId: (id: string | null) => void;
  reparent: (dragId: string, targetId: string) => void;
  reorder: (siblings: ObjectiveTreeNode[], index: number, dir: -1 | 1) => void;
}

export function OkrNode({
  node,
  depth,
  siblings,
  index,
  ctx,
}: {
  node: ObjectiveTreeNode;
  depth: number;
  siblings: ObjectiveTreeNode[];
  index: number;
  ctx: OkrNodeCtx;
}) {
  const [editing, setEditing] = useState(false);
  const [checkinsOpen, setCheckinsOpen] = useState(false);
  const isOpen = ctx.expanded.has(node.id);
  const dropOk = ctx.dragId != null && ctx.dragId !== node.id && canReparent(ctx.dragId, node.id, ctx.forest);
  const pct = Math.round((parseFloat(String(node.progress ?? "0")) || 0) * 100);

  return (
    <li>
      <div
        draggable
        onDragStart={(e) => {
          e.stopPropagation();
          ctx.setDragId(node.id);
        }}
        onDragEnd={() => ctx.setDragId(null)}
        onDragOver={(e) => {
          if (dropOk) e.preventDefault();
        }}
        onDrop={(e) => {
          e.preventDefault();
          e.stopPropagation();
          if (ctx.dragId && dropOk) ctx.reparent(ctx.dragId, node.id);
          ctx.setDragId(null);
        }}
        className={`rounded-lg border bg-surface ${dropOk ? "border-brand-blue ring-1 ring-brand-blue" : "border-border"}`}
        style={{ marginLeft: depth > 0 ? 16 : 0 }}
      >
        <div className="flex items-center gap-2 px-3 py-2.5">
          <button
            type="button"
            onClick={() => ctx.toggle(node.id)}
            className="w-4 shrink-0 text-text-muted"
            aria-label={isOpen ? "Collapse" : "Expand"}
          >
            {node.children.length > 0 ? (isOpen ? "▾" : "▸") : "·"}
          </button>

          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <span className="truncate text-sm font-medium text-text">{node.title}</span>
              <span className="shrink-0 rounded border border-border px-1.5 py-0.5 text-[11px] text-text-secondary">
                {node.level}
              </span>
              <StatusBadge status={node.status} />
              {node.children.length > 0 && (
                <span className="shrink-0 text-[11px] text-text-muted">
                  {node.children.length} child{node.children.length === 1 ? "" : "ren"}
                </span>
              )}
            </div>
            <div className="mt-1.5 flex items-center gap-2">
              <div className="flex-1">
                <ProgressBar value={node.progress} />
              </div>
              <span className="w-9 shrink-0 text-right text-[11px] tabular-nums text-text-muted">{pct}%</span>
            </div>
          </div>

          <div className="flex shrink-0 items-center gap-1">
            <button
              type="button"
              onClick={() => ctx.reorder(siblings, index, -1)}
              disabled={index === 0}
              className="px-1 text-text-muted disabled:opacity-30"
              aria-label="Move up"
            >
              ↑
            </button>
            <button
              type="button"
              onClick={() => ctx.reorder(siblings, index, 1)}
              disabled={index === siblings.length - 1}
              className="px-1 text-text-muted disabled:opacity-30"
              aria-label="Move down"
            >
              ↓
            </button>
            <button
              type="button"
              onClick={() => setCheckinsOpen(true)}
              className="px-1.5 text-xs text-text-muted hover:text-text"
            >
              Check-ins
            </button>
            <button
              type="button"
              onClick={() => setEditing((s) => !s)}
              className="px-1.5 text-xs text-text-muted hover:text-text"
            >
              {editing ? "Close" : "Edit"}
            </button>
          </div>
        </div>

        {editing && <NodeEditor node={node} ctx={ctx} onDone={() => setEditing(false)} />}
        {isOpen && <NodeBody node={node} ctx={ctx} />}
      </div>

      {isOpen && node.children.length > 0 && (
        <ul className="mt-1 space-y-1">
          {node.children.map((child, i) => (
            <OkrNode key={child.id} node={child} depth={depth + 1} siblings={node.children} index={i} ctx={ctx} />
          ))}
        </ul>
      )}

      <CheckinModal orgId={ctx.orgId} objectiveId={node.id} open={checkinsOpen} onClose={() => setCheckinsOpen(false)} />
    </li>
  );
}

// Inline edit of rollup strategy / weight / title + create-child + delete.
function NodeEditor({ node, ctx, onDone }: { node: ObjectiveTreeNode; ctx: OkrNodeCtx; onDone: () => void }) {
  const [title, setTitle] = useState(node.title);
  const [strategy, setStrategy] = useState<RollupStrategy>(node.rollup_strategy ?? "weighted_avg");
  const [weight, setWeight] = useState(String(node.weight ?? "1"));
  const [childTitle, setChildTitle] = useState("");
  const [busy, setBusy] = useState(false);

  const save = async () => {
    setBusy(true);
    try {
      await api.updateObjective(ctx.orgId, node.id, { title: title.trim(), rollup_strategy: strategy, weight });
      toast.success("Objective updated");
      onDone();
      ctx.reload();
    } catch (err) {
      toast.error((err as Error).message);
    } finally {
      setBusy(false);
    }
  };

  const addChild = async () => {
    if (!childTitle.trim()) return;
    setBusy(true);
    try {
      await api.createChildObjective(ctx.orgId, node.id, { title: childTitle.trim(), level: node.level });
      setChildTitle("");
      toast.success("Child objective created");
      ctx.reload();
    } catch (err) {
      toast.error((err as Error).message);
    } finally {
      setBusy(false);
    }
  };

  const remove = async () => {
    setBusy(true);
    try {
      await api.deleteObjective(ctx.orgId, node.id);
      toast.success("Objective deleted");
      ctx.reload();
    } catch (err) {
      // Server returns "has_children" (409) when children block the delete.
      toast.error((err as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="space-y-3 border-t border-border px-3 py-3">
      <div className="grid gap-3 sm:grid-cols-3">
        <label className="text-sm sm:col-span-3">
          <span className="mb-1 block text-text-secondary">Title</span>
          <Input value={title} onChange={(e) => setTitle(e.target.value)} />
        </label>
        <label className="text-sm">
          <span className="mb-1 block text-text-secondary">Rollup</span>
          <Select value={strategy} onChange={(e) => setStrategy(e.target.value as RollupStrategy)}>
            {(Object.keys(STRATEGY_LABEL) as RollupStrategy[]).map((s) => (
              <option key={s} value={s}>
                {STRATEGY_LABEL[s]}
              </option>
            ))}
          </Select>
        </label>
        <label className="text-sm">
          <span className="mb-1 block text-text-secondary">Weight</span>
          <Input value={weight} onChange={(e) => setWeight(e.target.value)} inputMode="decimal" />
        </label>
        <div className="flex items-end">
          <Button type="button" size="sm" onClick={save} disabled={busy}>
            Save
          </Button>
        </div>
      </div>

      <div className="flex items-end gap-2">
        <label className="flex-1 text-sm">
          <span className="mb-1 block text-text-secondary">Add child objective</span>
          <Input value={childTitle} onChange={(e) => setChildTitle(e.target.value)} placeholder="Child objective title" />
        </label>
        <Button type="button" variant="outline" size="sm" onClick={addChild} disabled={busy}>
          Add child
        </Button>
        <Button type="button" variant="danger" size="sm" onClick={remove} disabled={busy}>
          Delete
        </Button>
      </div>
    </div>
  );
}

// Expanded body: the objective's key results with inline create/edit.
function NodeBody({ node, ctx }: { node: ObjectiveTreeNode; ctx: OkrNodeCtx }) {
  const [krs, setKrs] = useState<KeyResult[] | null>(null);
  const [adding, setAdding] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  // Lazy-load key results the first time the node opens.
  if (krs === null) {
    api
      .getObjective(ctx.orgId, node.id)
      .then((r) => setKrs(r.objective.key_results ?? []))
      .catch((e) => {
        toast.error((e as Error).message);
        setKrs([]);
      });
    return (
      <div className="flex justify-center border-t border-border py-3">
        <Spinner />
      </div>
    );
  }

  const onKrSaved = (saved: KeyResult) => {
    setKrs((prev) => {
      const list = prev ?? [];
      const exists = list.some((k) => k.id === saved.id);
      return exists ? list.map((k) => (k.id === saved.id ? saved : k)) : [...list, saved];
    });
    setAdding(false);
    setEditingId(null);
    ctx.reload();
  };

  return (
    <div className="space-y-2 border-t border-border px-3 py-3">
      {krs.length === 0 && !adding ? (
        <p className="text-sm text-text-muted">No key results.</p>
      ) : (
        <ul className="space-y-2">
          {krs.map((kr) =>
            editingId === kr.id ? (
              <li key={kr.id}>
                <KrEditor
                  orgId={ctx.orgId}
                  objectiveId={node.id}
                  kr={kr}
                  onSaved={onKrSaved}
                  onDeleted={(id) => {
                    setKrs((prev) => (prev ?? []).filter((k) => k.id !== id));
                    setEditingId(null);
                    ctx.reload();
                  }}
                  onCancel={() => setEditingId(null)}
                />
              </li>
            ) : (
              <li key={kr.id} className="flex items-center gap-2">
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between text-sm">
                    <span className="truncate text-text">{kr.title}</span>
                    <span className="shrink-0 text-xs text-text-muted">
                      {String(kr.current_value ?? "0")}/{String(kr.target_value ?? "")}
                      {kr.unit ? ` ${kr.unit}` : ""}
                      {kr.auto_progress ? " · auto" : ""}
                    </span>
                  </div>
                  <div className="mt-1">
                    <ProgressBar value={krFraction(kr)} />
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setEditingId(kr.id)}
                  className="shrink-0 text-xs text-text-muted hover:text-text"
                >
                  edit
                </button>
              </li>
            ),
          )}
        </ul>
      )}

      {adding ? (
        <KrEditor orgId={ctx.orgId} objectiveId={node.id} onSaved={onKrSaved} onCancel={() => setAdding(false)} />
      ) : (
        <Button type="button" variant="ghost" size="sm" onClick={() => setAdding(true)}>
          + Add key result
        </Button>
      )}
    </div>
  );
}

// Display-only fraction (direction-aware, clamped) — mirrors the server's kr_fraction.
function krFraction(kr: KeyResult): number {
  const cur = parseFloat(String(kr.current_value ?? "0")) || 0;
  const tgt = parseFloat(String(kr.target_value ?? "0")) || 0;
  if (tgt === 0) return 0;
  const raw = kr.direction === "lower_better" ? 1 - cur / tgt : cur / tgt;
  return Math.max(0, Math.min(1, raw));
}
