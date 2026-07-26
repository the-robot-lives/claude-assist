"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api, type Notification } from "@/lib/api";
import { toast } from "sonner";
import { SectionCard, Empty } from "@/components/pm/priority-badge";

const KIND_TONE: Record<string, string> = {
  item_assigned: "border-[var(--info)] bg-[var(--info-bg)]",
  item_update: "border-[var(--line)]",
  comment: "border-[var(--warn)] bg-[var(--warn-bg)]",
  mention: "border-[var(--warn)] bg-[var(--warn-bg)]",
  dm: "border-[var(--info)] bg-[var(--info-bg)]",
  ping: "border-[var(--err)] bg-[var(--err-bg)]",
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
    <div className="mx-auto max-w-2xl px-4 py-6 text-[var(--ink)]">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="font-mono text-2xl font-bold uppercase tracking-wide text-[var(--ink)]">Inbox</h1>
          <p className="mt-1 font-mono text-sm text-[var(--mut)]">
            {currentOrg?.name || "organization"} · notifications
          </p>
        </div>
        <button
          onClick={markAll}
          className="rounded-[var(--r-pill)] border border-[var(--line2)] bg-[var(--panel2)] px-3 py-1.5 font-mono text-xs uppercase tracking-wide text-[var(--mut)] hover:border-[var(--acc-line)] hover:text-[var(--ink)]"
        >
          mark all read
        </button>
      </header>

      {loading ? (
        <p className="font-mono text-sm text-[var(--mut)]">loading…</p>
      ) : items.length === 0 ? (
        <SectionCard title="Nothing here">
          <Empty>You're all caught up.</Empty>
        </SectionCard>
      ) : (
        <ul className="space-y-2">
          {items.map((n) => {
            const tone = KIND_TONE[n.kind] || "border-[var(--line)]";
            return (
              <li
                key={n.id}
                className={`rounded-[var(--r-sm)] border bg-[var(--panel)] px-3 py-2.5 transition-colors hover:bg-[var(--sel)] ${tone} ${n.read ? "opacity-60" : ""}`}
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="font-mono text-xs uppercase tracking-wide text-[var(--faint)]">
                    {n.kind.replace(/_/g, " ")}
                  </span>
                  <span className="font-mono text-xs tabular-nums text-[var(--faint)]">
                    {n.inserted_at ? new Date(n.inserted_at).toLocaleString() : ""}
                  </span>
                </div>
                {n.body && <p className="mt-1 text-sm text-[var(--ink)]">{n.body}</p>}
                {n.sender && <p className="mt-0.5 font-mono text-xs text-[var(--mut)]">from {n.sender}</p>}
                {n.subject_type === "item" && n.subject_id && (
                  <Link
                    href={`/app/${orgId}/items/${n.subject_id}`}
                    className="mt-1 inline-block font-mono text-xs text-[var(--acc)] hover:text-[var(--acc-hi)] hover:underline"
                  >
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
