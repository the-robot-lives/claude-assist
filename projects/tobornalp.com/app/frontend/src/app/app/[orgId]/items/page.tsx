"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api, type Item, type ItemQueue } from "@/lib/api";
import { toast } from "sonner";
import { PriorityBadge, StatusBadge, SectionCard, Empty } from "@/components/pm/priority-badge";

export default function ItemsPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;

  const [boards, setBoards] = useState<ItemQueue[]>([]);
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);

  useEffect(() => {
    if (!orgId) return;
    setLoading(true);
    Promise.all([
      api.listQueues(orgId).then((r) => setBoards(r.queues)).catch(() => setBoards([])),
      api.listItems(orgId).then((r) => setItems(r.items)).catch(() => setItems([])),
    ]).finally(() => setLoading(false));
  }, [orgId]);

  return (
    <div className="mx-auto max-w-5xl px-4 py-6">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text">Items</h1>
          <p className="text-sm text-text-secondary">{currentOrg?.name || "Organization"} · work tracking</p>
        </div>
        <button onClick={() => setShowCreate((s) => !s)} className="sg-btn sg-btn--black sg-btn--sm">
          {showCreate ? "Cancel" : "+ New item"}
        </button>
      </header>

      {showCreate && <CreateItem orgId={orgId} onCreated={(it) => { setItems((prev) => [it, ...prev]); setShowCreate(false); }} />}

      {loading ? (
        <p className="text-text-muted">Loading…</p>
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          <SectionCard
            title="Boards"
            count={boards.length}
            action={<button onClick={() => location.reload()} className="text-xs text-text-muted">refresh</button>}
          >
            {boards.length === 0 ? (
              <Empty>No boards yet. Create one via the API or a board-create screen.</Empty>
            ) : (
              <ul className="space-y-1.5">
                {boards.map((b) => (
                  <li key={b.id}>
                    <Link
                      href={`/app/${orgId}/items/boards/${b.id}`}
                      className="flex items-center justify-between rounded border border-transparent px-2 py-1.5 text-sm hover:border-border hover:bg-surface-alt"
                    >
                      <span className="text-text">{b.name}</span>
                      <span className="font-mono text-xs text-text-muted">{b.methodology}</span>
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </SectionCard>

          <SectionCard title="Backlog" count={items.length}>
            {items.length === 0 ? (
              <Empty>No items yet.</Empty>
            ) : (
              <ul className="space-y-1.5">
                {items.slice(0, 40).map((it) => (
                  <li key={it.id}>
                    <Link
                      href={`/app/${orgId}/items/${it.id}`}
                      className="flex items-center gap-2 rounded border border-transparent px-2 py-1.5 text-sm hover:border-border hover:bg-surface-alt"
                    >
                      {it.key && <span className="font-mono text-xs text-text-muted">{it.key}</span>}
                      <span className="flex-1 truncate text-text">{it.title}</span>
                      <PriorityBadge priority={it.priority} />
                      <StatusBadge status={it.status} />
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </SectionCard>
        </div>
      )}
    </div>
  );
}

function CreateItem({ orgId, onCreated }: { orgId: string; onCreated: (it: Item) => void }) {
  const [title, setTitle] = useState("");
  const [itemType, setItemType] = useState("task");
  const [priority, setPriority] = useState("medium");
  const [submitting, setSubmitting] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    setSubmitting(true);
    try {
      const res = await api.createItem(orgId, { title: title.trim(), item_type: itemType, priority });
      onCreated(res.item);
      setTitle("");
      toast.success("Item created");
    } catch (err) {
      toast.error((err as Error).message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form onSubmit={submit} className="mb-4 rounded-lg border border-border bg-surface p-4">
      <div className="grid gap-3 sm:grid-cols-2">
        <label className="sm:col-span-2 text-sm">
          <span className="mb-1 block text-text-secondary">Title</span>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full rounded border border-border bg-surface-alt px-2 py-1.5 text-text outline-none focus:border-brand-blue"
            placeholder="What needs doing?"
            autoFocus
          />
        </label>
        <label className="text-sm">
          <span className="mb-1 block text-text-secondary">Type</span>
          <select value={itemType} onChange={(e) => setItemType(e.target.value)} className="w-full rounded border border-border bg-surface-alt px-2 py-1.5 text-text">
            {["task", "bug", "todo", "epic", "subtask"].map((t) => <option key={t} value={t}>{t}</option>)}
          </select>
        </label>
        <label className="text-sm">
          <span className="mb-1 block text-text-secondary">Priority</span>
          <select value={priority} onChange={(e) => setPriority(e.target.value)} className="w-full rounded border border-border bg-surface-alt px-2 py-1.5 text-text">
            {["low", "medium", "high", "critical"].map((t) => <option key={t} value={t}>{t}</option>)}
          </select>
        </label>
      </div>
      <div className="mt-3 flex justify-end gap-2">
        <button type="submit" disabled={submitting} className="sg-btn sg-btn--black sg-btn--sm">
          {submitting ? "Creating…" : "Create"}
        </button>
      </div>
    </form>
  );
}
