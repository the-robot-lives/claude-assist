"use client";

import { useCallback, useEffect, useState } from "react";
import { api, type ObjectiveTreeNode } from "@/lib/api";
import { EmptyState, Spinner } from "@/components/ui";
import { toast } from "sonner";
import { OkrNode, type OkrNodeCtx } from "./okr-node";

// Collapsible OKR hierarchy with rolled-up progress bars, inline KR + child editing,
// check-ins, cycle-safe drag-reparent (client pre-check + server 422 reconcile) and
// button reorder (US-069). Consumes the tree endpoint; reloads to reconcile.
export function OkrTree({ orgId, reloadKey }: { orgId: string; reloadKey?: number }) {
  const [forest, setForest] = useState<ObjectiveTreeNode[]>([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState<Set<string>>(new Set());
  const [dragId, setDragId] = useState<string | null>(null);

  const reload = useCallback(() => {
    setLoading(true);
    api
      .getObjectiveTree(orgId)
      .then((r) => setForest(r.tree))
      .catch((e) => toast.error((e as Error).message))
      .finally(() => setLoading(false));
  }, [orgId]);

  useEffect(() => {
    reload();
  }, [reload, reloadKey]);

  const toggle = useCallback((id: string) => {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const reparent = useCallback(
    async (childId: string, targetId: string | null) => {
      try {
        await api.updateObjective(orgId, childId, { parent_id: targetId });
        toast.success("Objective moved");
      } catch (e) {
        // Server independently re-validates (cycle / max_depth) → reconcile from truth.
        toast.error((e as Error).message);
      } finally {
        reload();
      }
    },
    [orgId, reload],
  );

  const reorder = useCallback(
    async (siblings: ObjectiveTreeNode[], index: number, dir: -1 | 1) => {
      const j = index + dir;
      if (j < 0 || j >= siblings.length) return;
      const next = [...siblings];
      const [moved] = next.splice(index, 1);
      next.splice(j, 0, moved);
      try {
        await Promise.all(next.map((o, i) => api.updateObjective(orgId, o.id, { sort_order: i })));
      } catch (e) {
        toast.error((e as Error).message);
      } finally {
        reload();
      }
    },
    [orgId, reload],
  );

  const ctx: OkrNodeCtx = {
    orgId,
    forest,
    expanded,
    toggle,
    reload,
    dragId,
    setDragId,
    reparent: (childId, targetId) => reparent(childId, targetId),
    reorder,
  };

  if (loading && forest.length === 0) {
    return (
      <div className="flex justify-center py-10">
        <Spinner />
      </div>
    );
  }

  if (forest.length === 0) {
    return <EmptyState title="No objectives">Set your first objective to start the tree.</EmptyState>;
  }

  return (
    <div>
      {/* Drop target to promote a node to top-level (reparent to null). */}
      <div
        onDragOver={(e) => {
          if (dragId) e.preventDefault();
        }}
        onDrop={(e) => {
          e.preventDefault();
          if (dragId) reparent(dragId, null);
          setDragId(null);
        }}
        className={`mb-2 rounded-md border border-dashed px-3 py-1.5 text-center text-[11px] ${
          dragId ? "border-brand-blue text-brand-blue" : "border-border text-text-muted"
        }`}
      >
        Drop here to make top-level
      </div>

      <ul className="space-y-1">
        {forest.map((node, i) => (
          <OkrNode key={node.id} node={node} depth={0} siblings={forest} index={i} ctx={ctx} />
        ))}
      </ul>
    </div>
  );
}
