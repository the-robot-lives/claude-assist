"use client";

import { useState } from "react";
import { api, type ObjectiveTreeNode, type KeyResult, type RollupStrategy } from "@/lib/api";
import { Btn, Input, Select, ProgressBar, StatusBadge, Spinner, Chip, FieldLabel } from "@/components/ui";
import { toast } from "sonner";
import { canReparent } from "./reorder";
import { KrEditor } from "./kr-editor";
import { CheckinModal } from "./checkin-modal";

const STRATEGY_LABEL: Record<RollupStrategy, string> = {
  weighted_avg: "weighted avg",
  min_children: "min child",
  custom: "custom",
};

// Destructive pill — coral outline on its own tint, filling solid (with #000 ink)
// on hover. Written out rather than layered on <Btn> so no colour class collides.
const DANGER_PILL =
  "inline-flex items-center justify-center rounded-pill border border-err bg-err-bg px-3.5 py-[5px] text-[12px] font-bold text-err transition-colors hover:bg-err hover:text-black disabled:cursor-not-allowed disabled:opacity-60";

// Terse inline control in a header/footer strip — faint until hovered.
const GHOST_LINK = "px-1.5 text-[11px] text-faint transition-colors hover:text-ink";

// Objective status reads as "behind pace" for the roll-up % / bar tone —
// mirrors the meaning FlatList already gives these statuses via StatusBadge.
function isBehind(status?: string): boolean {
  return status === "at_risk" || status === "off_track";
}

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
  const behind = isBehind(node.status);

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
        className={`overflow-hidden rounded-panel border bg-panel shadow-card ${dropOk ? "border-acc ring-1 ring-acc" : "border-line"}`}
        style={{ marginLeft: depth > 0 ? 16 : 0 }}
      >
        <div className="flex items-center gap-2 bg-panel2 px-[18px] py-3">
          <button
            type="button"
            onClick={() => ctx.toggle(node.id)}
            className="w-4 shrink-0 text-faint transition-colors hover:text-ink"
            aria-label={isOpen ? "Collapse" : "Expand"}
          >
            {node.children.length > 0 ? (isOpen ? "▾" : "▸") : "·"}
          </button>

          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <span className="truncate text-[14.5px] font-bold text-ink">{node.title}</span>
              <Chip variant="scope">{node.level}</Chip>
              <StatusBadge status={node.status} />
              {node.children.length > 0 && (
                <span className="num shrink-0 text-[11px] text-faint">
                  {node.children.length} child{node.children.length === 1 ? "" : "ren"}
                </span>
              )}
              <span className={`num ml-auto shrink-0 text-[16px] font-bold ${behind ? "text-warn" : "text-acc"}`}>
                {pct}%
              </span>
            </div>
            <div className="mt-1.5 flex items-center gap-2">
              <div className="flex-1">
                <ProgressBar value={node.progress} tone={behind ? "warned" : "ok"} />
              </div>
            </div>
          </div>

          <div className="flex shrink-0 items-center gap-1">
            <button
              type="button"
              onClick={() => ctx.reorder(siblings, index, -1)}
              disabled={index === 0}
              className="px-1 text-[12px] text-faint transition-colors hover:text-ink disabled:opacity-30 disabled:hover:text-faint"
              aria-label="Move up"
            >
              ↑
            </button>
            <button
              type="button"
              onClick={() => ctx.reorder(siblings, index, 1)}
              disabled={index === siblings.length - 1}
              className="px-1 text-[12px] text-faint transition-colors hover:text-ink disabled:opacity-30 disabled:hover:text-faint"
              aria-label="Move down"
            >
              ↓
            </button>
            <button type="button" onClick={() => setCheckinsOpen(true)} className={GHOST_LINK}>
              check-ins
            </button>
            <button type="button" onClick={() => setEditing((s) => !s)} className={GHOST_LINK}>
              {editing ? "close" : "edit"}
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
    <div className="space-y-3 border-t border-line2 bg-panel2 px-[18px] py-3">
      <div className="grid gap-3 sm:grid-cols-3">
        <FieldLabel label="title" className="sm:col-span-3">
          <Input value={title} onChange={(e) => setTitle(e.target.value)} />
        </FieldLabel>
        <FieldLabel label="rollup">
          <Select value={strategy} onChange={(e) => setStrategy(e.target.value as RollupStrategy)}>
            {(Object.keys(STRATEGY_LABEL) as RollupStrategy[]).map((s) => (
              <option key={s} value={s}>
                {STRATEGY_LABEL[s]}
              </option>
            ))}
          </Select>
        </FieldLabel>
        <FieldLabel label="weight">
          <Input value={weight} onChange={(e) => setWeight(e.target.value)} inputMode="decimal" />
        </FieldLabel>
        <div className="flex items-end">
          <Btn variant="primary" onClick={save} disabled={busy}>
            save
          </Btn>
        </div>
      </div>

      <div className="flex items-end gap-2">
        <FieldLabel label="add child objective" className="flex-1">
          <Input value={childTitle} onChange={(e) => setChildTitle(e.target.value)} placeholder="child objective title" />
        </FieldLabel>
        <Btn onClick={addChild} disabled={busy}>
          add child
        </Btn>
        <button type="button" onClick={remove} disabled={busy} className={DANGER_PILL}>
          delete
        </button>
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
      <div className="flex justify-center border-t border-line2 py-3">
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
    <div className="border-t border-line2">
      {krs.length === 0 && !adding ? (
        <p className="px-[18px] py-3 text-[12px] text-faint">no key results.</p>
      ) : (
        <ul>
          {krs.map((kr) =>
            editingId === kr.id ? (
              <li key={kr.id} className="border-b border-line px-[18px] py-3 last:border-b-0">
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
              <li
                key={kr.id}
                className="grid grid-cols-[minmax(0,5fr)_minmax(120px,2fr)_auto] items-center gap-x-4 gap-y-1.5 border-b border-line px-[18px] py-[11px] last:border-b-0 hover:bg-sel"
              >
                <div className="min-w-0">
                  <span className="text-[12.5px] text-ink">{kr.title}</span>
                  <span className="num mt-[3px] block text-[10.5px] text-faint">
                    {String(kr.current_value ?? "0")}/{String(kr.target_value ?? "")}
                    {kr.unit ? ` ${kr.unit}` : ""}
                    {kr.auto_progress ? " · auto" : ""}
                  </span>
                </div>
                <ProgressBar value={krFraction(kr)} />
                <div className="flex items-center gap-2">
                  <span className="num min-w-[44px] text-right text-[12.5px] font-bold text-acc">
                    {Math.round(krFraction(kr) * 100)}%
                  </span>
                  <button type="button" onClick={() => setEditingId(kr.id)} className={`shrink-0 ${GHOST_LINK}`}>
                    edit
                  </button>
                </div>
              </li>
            ),
          )}
        </ul>
      )}

      <div className="px-[18px] py-3">
        {adding ? (
          <KrEditor orgId={ctx.orgId} objectiveId={node.id} onSaved={onKrSaved} onCancel={() => setAdding(false)} />
        ) : (
          <Btn onClick={() => setAdding(true)}>+ add key result</Btn>
        )}
      </div>
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
