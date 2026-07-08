"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api, type Item } from "@/lib/api";
import { toast } from "sonner";
import { PriorityBadge, StatusBadge, SectionCard } from "@/components/pm/priority-badge";

const PRIORITIES = ["low", "medium", "high", "critical"];
const STATUSES = ["open", "in_progress", "in_review", "done", "closed"];

export default function ItemDetailPage() {
  const params = useParams<{ orgId: string; itemId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;

  const [item, setItem] = useState<Item | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!orgId || !params.itemId) return;
    setLoading(true);
    api
      .getItem(orgId, params.itemId)
      .then((r) => setItem(r.item))
      .catch((e) => toast.error(e.message))
      .finally(() => setLoading(false));
  }, [orgId, params.itemId]);

  const patch = async (changes: Partial<Item>) => {
    if (!item) return;
    setSaving(true);
    const prev = item;
    setItem({ ...item, ...changes });
    try {
      const res = await api.updateItem(orgId, item.id, changes);
      setItem(res.item);
    } catch (e) {
      setItem(prev);
      toast.error((e as Error).message);
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <div className="p-8 text-text-muted">Loading item…</div>;
  if (!item) return <div className="p-8 text-text-muted">Item not found.</div>;

  return (
    <div className="mx-auto max-w-3xl px-4 py-6">
      <Link href={`/app/${orgId}/items`} className="text-xs text-text-muted hover:underline">← items</Link>

      <header className="mt-2 mb-6">
        <div className="flex items-center gap-2 font-mono text-xs text-text-muted">
          {item.key && <span>{item.key}</span>}
          <span>·</span>
          <span>{item.item_type}</span>
        </div>
        <h1 className="mt-1 text-2xl font-bold text-text">{item.title}</h1>
        <div className="mt-2 flex items-center gap-2">
          <PriorityBadge priority={item.priority} />
          <StatusBadge status={item.status} />
        </div>
      </header>

      <div className="grid gap-4 md:grid-cols-3">
        <SectionCard title="Details">
          <dl className="space-y-2 text-sm">
            <Field label="Status">
              <select value={item.status} onChange={(e) => patch({ status: e.target.value })} className="rounded border border-border bg-surface-alt px-1.5 py-1 text-text">
                {STATUSES.map((s) => <option key={s} value={s}>{s.replace(/_/g, " ")}</option>)}
              </select>
            </Field>
            <Field label="Priority">
              <select value={item.priority || ""} onChange={(e) => patch({ priority: e.target.value })} className="rounded border border-border bg-surface-alt px-1.5 py-1 text-text">
                {PRIORITIES.map((p) => <option key={p} value={p}>{p}</option>)}
              </select>
            </Field>
            <Field label="Assignee">
              <input
                value={item.assignee || ""}
                onChange={(e) => patch({ assignee: e.target.value })}
                placeholder="unassigned"
                className="w-full rounded border border-border bg-surface-alt px-1.5 py-1 text-text"
              />
            </Field>
          </dl>
        </SectionCard>

        <div className="md:col-span-2">
          <SectionCard title="Description">
            <textarea
              value={item.description || ""}
              onChange={(e) => setItem((it) => (it ? { ...it, description: e.target.value } : it))}
              onBlur={(e) => e.target.value !== item.description && patch({ description: e.target.value })}
              rows={8}
              className="w-full rounded border border-border bg-surface-alt px-2 py-1.5 text-sm text-text"
              placeholder="Add a description…"
            />
          </SectionCard>
        </div>
      </div>
      {saving && <p className="mt-3 text-xs text-text-muted">saving…</p>}
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-3">
      <dt className="text-text-secondary">{label}</dt>
      <dd className="flex-1 text-right">{children}</dd>
    </div>
  );
}
