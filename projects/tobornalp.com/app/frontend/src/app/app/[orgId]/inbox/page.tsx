"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api, type Notification } from "@/lib/api";
import { toast } from "sonner";
import { SectionCard, Empty, Btn, StatusSeg, type StatusTone } from "@/components/ui";

// Notification kind → severity, expressed through the shared [OK]/[WARN]/[ERR]/[INFO]
// vocabulary (see reviews' statusTone / board's chipVariantForType) instead of a bespoke
// per-kind border/bg wash on the row.
function kindTone(kind: string): StatusTone {
  if (kind === "ping") return "err";
  if (kind === "comment" || kind === "mention") return "warn";
  return "info"; // item_assigned, item_update, dm, and any unrecognized kind
}

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
    <div className="app-content max-w-2xl">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">inbox</h1>
          <p className="mt-1 text-[11px] text-mut">
            {(currentOrg?.name || "organization").toLowerCase()} · notifications
          </p>
        </div>
        <Btn onClick={markAll}>mark all read</Btn>
      </header>

      {loading ? (
        <p className="text-[12px] text-faint">loading…</p>
      ) : items.length === 0 ? (
        <SectionCard title="Nothing here">
          <Empty>you're all caught up.</Empty>
        </SectionCard>
      ) : (
        <ul className="space-y-2">
          {items.map((n) => (
            <li
              key={n.id}
              className={`rounded-card border border-line bg-panel px-3 py-2.5 transition-colors hover:bg-sel ${n.read ? "opacity-60" : ""}`}
            >
              <div className="flex items-center justify-between gap-2">
                <StatusSeg tone={kindTone(n.kind)} className="text-[11px] uppercase tracking-wide text-faint">
                  {n.kind.replace(/_/g, " ")}
                </StatusSeg>
                <span className="text-[11px] tabular-nums text-faint">
                  {n.inserted_at ? new Date(n.inserted_at).toLocaleString() : ""}
                </span>
              </div>
              {n.body && <p className="mt-1 text-sm text-ink">{n.body}</p>}
              {n.sender && <p className="mt-0.5 text-xs text-mut">from {n.sender}</p>}
              {n.subject_type === "item" && n.subject_id && (
                <Link
                  href={`/app/${orgId}/items/${n.subject_id}`}
                  className="mt-1 inline-block text-xs text-acc hover:text-acc-hi hover:underline"
                >
                  view item →
                </Link>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
