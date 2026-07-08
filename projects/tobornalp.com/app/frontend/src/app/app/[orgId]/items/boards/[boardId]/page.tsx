"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api, type ItemQueue, type Item } from "@/lib/api";
import { toast } from "sonner";
import { PriorityBadge } from "@/components/pm/priority-badge";

export default function BoardPage() {
  const params = useParams<{ orgId: string; boardId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;
  const boardId = params.boardId;

  const [board, setBoard] = useState<ItemQueue | null>(null);
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!orgId || !boardId) return;
    setLoading(true);
    Promise.all([
      api.getQueue(orgId, boardId).then((r) => setBoard(r.queue)).catch(() => setBoard(null)),
      api.listItems(orgId, { queue_id: boardId }).then((r) => setItems(r.items)).catch(() => setItems([])),
    ]).finally(() => setLoading(false));
  }, [orgId, boardId]);

  const stages = (board?.stages || []).slice().sort((a, b) => a.position - b.position);
  const byStage = (stageId?: string) => items.filter((i) => (i.stage_id || null) === (stageId || null));

  const moveItem = async (item: Item, stageId: string | "") => {
    const prev = item.stage_id;
    setItems((cur) => cur.map((i) => (i.id === item.id ? { ...i, stage_id: stageId || undefined } : i)));
    try {
      const res = await api.updateItem(orgId, item.id, { stage_id: stageId || undefined });
      setItems((cur) => cur.map((i) => (i.id === item.id ? res.item : i)));
    } catch (e) {
      // revert on failure
      setItems((cur) => cur.map((i) => (i.id === item.id ? { ...i, stage_id: prev } : i)));
      toast.error((e as Error).message);
    }
  };

  if (loading) return <div className="p-8 text-text-muted">Loading board…</div>;
  if (!board) return <div className="p-8 text-text-muted">Board not found.</div>;

  return (
    <div className="px-4 py-6">
      <header className="mb-6">
        <Link href={`/app/${orgId}/items`} className="text-xs text-text-muted hover:underline">← boards</Link>
        <h1 className="mt-1 text-2xl font-bold text-text">{board.name}</h1>
        <p className="text-sm text-text-secondary">{board.methodology} · {items.length} items</p>
      </header>

      <div className="flex gap-3 overflow-x-auto pb-4">
        {stages.map((stage) => {
          const cards = byStage(stage.id);
          return (
            <div key={stage.id} className="flex w-72 shrink-0 flex-col rounded-lg border border-border bg-surface-alt">
              <div className="flex items-center justify-between border-b border-border px-3 py-2">
                <span className="text-sm font-semibold text-text">{stage.name}</span>
                <span className="text-xs text-text-muted">
                  {cards.length}
                  {stage.wip_limit ? `/${stage.wip_limit}` : ""}
                </span>
              </div>
              <div className="flex flex-col gap-2 p-2">
                {cards.map((it) => (
                  <Card key={it.id} item={it} stages={stages} onMove={(sid) => moveItem(it, sid)} />
                ))}
                {cards.length === 0 && <p className="px-1 py-4 text-center text-xs text-text-muted">empty</p>}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function Card({ item, stages, onMove }: { item: Item; stages: { id: string; name: string }[]; onMove: (stageId: string) => void }) {
  return (
    <div className="rounded border border-border bg-surface p-2.5 shadow-sm">
      <Link href={`#`} className="block text-sm text-text hover:text-brand-blue">
        <span className="font-mono text-xs text-text-muted">{item.key || item.id.slice(0, 8)}</span>
        <div className="mt-0.5 line-clamp-2">{item.title}</div>
      </Link>
      <div className="mt-2 flex items-center justify-between gap-2">
        <PriorityBadge priority={item.priority} />
        <select
          value={item.stage_id || ""}
          onChange={(e) => onMove(e.target.value)}
          className="rounded border border-border bg-surface-alt px-1 py-0.5 text-xs text-text outline-none"
          aria-label="Move to stage"
        >
          {stages.map((s) => (
            <option key={s.id} value={s.id}>{s.name}</option>
          ))}
        </select>
      </div>
    </div>
  );
}
