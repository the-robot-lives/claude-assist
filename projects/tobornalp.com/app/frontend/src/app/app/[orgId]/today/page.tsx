"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api, type TodayPlan, type Item, type Objective } from "@/lib/api";
import { toast } from "sonner";
import { PriorityBadge, StatusBadge, ProgressBar, SectionCard, Empty } from "@/components/pm/priority-badge";

export default function TodayPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;
  const [plan, setPlan] = useState<TodayPlan | null>(null);
  const [loading, setLoading] = useState(true);

  // Decorative hero date line — purely presentational, computed client-side.
  const heroDate = useMemo(() => {
    const d = new Date();
    return d
      .toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" })
      .toLowerCase();
  }, []);

  useEffect(() => {
    if (!orgId) return;
    setLoading(true);
    api
      .today(orgId, 7)
      .then((r) => setPlan(r.plan))
      .catch((e) => toast.error(e.message))
      .finally(() => setLoading(false));
  }, [orgId]);

  if (loading) return <div className="p-8 font-mono text-sm text-[var(--mut)]">loading your day…</div>;
  if (!plan) return <Empty>Could not load your plan.</Empty>;

  return (
    <div className="mx-auto max-w-4xl px-4 py-6 text-[var(--ink)]">
      <header className="mb-6">
        <div className="flex items-baseline gap-3">
          <h1 className="font-mono text-2xl font-bold uppercase tracking-wide text-[var(--ink)]">Today</h1>
          <span className="font-mono text-xs text-[var(--faint)]">{heroDate}</span>
        </div>
        <p className="mt-1 font-mono text-sm text-[var(--mut)]">
          {currentOrg?.name ? `${currentOrg.name} · ` : ""}everything competing for your time.
          {(plan.unread_notifications ?? 0) > 0 && (
            <Link
              href={`/app/${orgId}/inbox`}
              className="ml-2 text-[var(--acc)] hover:text-[var(--acc-hi)] hover:underline"
            >
              {plan.unread_notifications} unread →
            </Link>
          )}
        </p>
      </header>

      <div className="grid gap-[14px] md:grid-cols-2">
        <SectionCard title="Assigned to you" count={plan.assigned?.length}>
          <ItemList items={plan.assigned} orgId={orgId} empty="Nothing assigned — enjoy the calm." />
        </SectionCard>

        <SectionCard title="Due soon" count={plan.due_soon?.length}>
          <ItemList items={plan.due_soon} orgId={orgId} empty="Nothing due this week." />
        </SectionCard>

        <SectionCard
          title="Your objectives"
          count={plan.objectives?.length}
          action={
            <Link
              href={`/app/${orgId}/goals`}
              className="font-mono text-xs text-[var(--acc)] hover:text-[var(--acc-hi)] hover:underline"
            >
              all
            </Link>
          }
        >
          <ObjectiveList objectives={plan.objectives} />
        </SectionCard>

        <SectionCard title="Key results" count={plan.key_results?.length}>
          {plan.key_results && plan.key_results.length > 0 ? (
            <ul className="space-y-3">
              {plan.key_results.map((kr) => (
                <li key={kr.kr_id}>
                  <div className="flex items-center justify-between text-sm text-[var(--ink)]">
                    <span className="truncate">{kr.title}</span>
                    <span className="ml-2 shrink-0 font-mono text-[var(--mut)] tabular-nums">
                      {fmt(kr.current)}/{fmt(kr.target)}
                    </span>
                  </div>
                  <div className="mt-1">
                    <ProgressBar value={ratio(kr.current, kr.target)} />
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <Empty>No item-backed key results.</Empty>
          )}
        </SectionCard>
      </div>
    </div>
  );
}

function ItemList({ items, orgId, empty }: { items?: Item[]; orgId: string; empty: string }) {
  if (!items || items.length === 0) return <Empty>{empty}</Empty>;
  return (
    <ul className="space-y-1.5">
      {items.map((it) => (
        <li key={it.id}>
          <Link
            href={`/app/${orgId}/items/${it.id}`}
            className="flex items-center gap-2 border-b border-[var(--line)] px-2 py-1.5 text-sm last:border-0 hover:bg-[var(--sel)] hover:rounded-[var(--r-sm)]"
          >
            {it.key && <span className="font-mono text-xs text-[var(--faint)]">{it.key}</span>}
            <span className="flex-1 truncate text-[var(--ink)]">{it.title}</span>
            <PriorityBadge priority={it.priority} />
            <StatusBadge status={it.status} />
          </Link>
        </li>
      ))}
    </ul>
  );
}

function ObjectiveList({ objectives }: { objectives?: Objective[] }) {
  if (!objectives || objectives.length === 0) return <Empty>No active objectives.</Empty>;
  return (
    <ul className="space-y-3">
      {objectives.map((o) => (
        <li key={o.id}>
          <div className="flex items-center justify-between text-sm">
            <span className="truncate text-[var(--ink)]">{o.title}</span>
            <span className="ml-2 shrink-0 font-mono text-xs uppercase tracking-wide text-[var(--faint)]">{o.level}</span>
          </div>
          <div className="mt-1">
            <ProgressBar value={o.progress} />
          </div>
        </li>
      ))}
    </ul>
  );
}

const fmt = (v?: string | number) => (v == null ? "0" : String(v).replace(/\.0$/, ""));
const ratio = (cur?: string | number, tgt?: string | number) => {
  const c = parseFloat(String(cur ?? "0"));
  const t = parseFloat(String(tgt ?? "1"));
  return t === 0 ? 0 : c / t;
};
