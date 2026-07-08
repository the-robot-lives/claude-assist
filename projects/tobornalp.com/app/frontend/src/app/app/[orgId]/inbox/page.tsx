"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api, type Notification } from "@/lib/api";
import { toast } from "sonner";
import { SectionCard, Empty } from "@/components/pm/priority-badge";

const KIND_TONE: Record<string, string> = {
  item_assigned: "border-brand-blue/40 bg-brand-blue/10",
  item_update: "border-border",
  comment: "border-warning/40 bg-warning/10",
  mention: "border-warning/40 bg-warning/10",
  dm: "border-brand-blue/40 bg-brand-blue/10",
  ping: "border-brand-red/40 bg-brand-red/10",
};

export default function InboxPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;

  const [items, setItems] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);

  const load = () => {
    setLoading(true);
    api
      .listNotifications(orgId)
      .then((r) => setItems(r.notifications))
      .catch((e) => toast.error(e.message))
      .finally(() => setLoading(false));
  };

  useEffect(load, [orgId]);

  const markAll = async () => {
    try {
      await api.markNotificationsRead(orgId);
      setItems((cur) => cur.map((n) => ({ ...n, read: true })));
      toast.success("Marked all read");
    } catch (e) {
      toast.error((e as Error).message);
    }
  };

  return (
    <div className="mx-auto max-w-2xl px-4 py-6">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text">Inbox</h1>
          <p className="text-sm text-text-secondary">{currentOrg?.name || "Organization"} · notifications</p>
        </div>
        <button onClick={markAll} className="sg-btn sg-btn--outline sg-btn--sm">Mark all read</button>
      </header>

      {loading ? (
        <p className="text-text-muted">Loading…</p>
      ) : items.length === 0 ? (
        <SectionCard title="Nothing here">
          <Empty>You're all caught up.</Empty>
        </SectionCard>
      ) : (
        <ul className="space-y-2">
          {items.map((n) => {
            const tone = KIND_TONE[n.kind] || "border-border";
            return (
              <li key={n.id} className={`rounded-lg border px-3 py-2.5 ${tone} ${n.read ? "opacity-60" : ""}`}>
                <div className="flex items-center justify-between gap-2">
                  <span className="text-xs font-medium uppercase text-text-secondary">{n.kind.replace(/_/g, " ")}</span>
                  <span className="text-xs text-text-muted">{n.inserted_at ? new Date(n.inserted_at).toLocaleString() : ""}</span>
                </div>
                {n.body && <p className="mt-1 text-sm text-text">{n.body}</p>}
                {n.sender && <p className="mt-0.5 text-xs text-text-muted">from {n.sender}</p>}
                {n.subject_type === "item" && n.subject_id && (
                  <Link href={`/app/${orgId}/items/${n.subject_id}`} className="mt-1 inline-block text-xs text-brand-blue hover:underline">
                    view item →
                  </Link>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
