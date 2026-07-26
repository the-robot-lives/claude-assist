"use client";

// Item-detail Activity timeline. Read-only render of item_events (append-only
// audit): each entry is a field transition (old_value → new_value) with actor +
// timestamp. Rendered below the descriptor detail view so the shared items
// descriptor stays untouched. No write surface here.
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { SectionCard, Empty } from "@/components/ui";
import { timeAgo } from "./util";

export interface ActivitySectionProps {
  orgId: string;
  itemId: string;
}

export function ActivitySection({ orgId, itemId }: ActivitySectionProps) {
  const { data, loading, error } = useApi(
    () => api.listItemActivity(orgId, itemId),
    [orgId, itemId],
  );

  // Most-recent first (timeline reads top-down as "what just happened").
  const events = [...(data?.activity ?? [])].sort(byOccurredDesc);

  return (
    <SectionCard title="Activity" count={events.length}>
      {loading ? (
        <p className="py-4 text-center font-mono text-sm text-[var(--faint)]">loading activity…</p>
      ) : error ? (
        <p className="py-4 text-center font-mono text-sm text-[var(--err)]">{error.message}</p>
      ) : events.length === 0 ? (
        <Empty>No activity recorded.</Empty>
      ) : (
        <ol className="relative space-y-3 border-l border-[var(--line)] pl-4">
          {events.map((ev) => (
            <li key={ev.id} className="text-sm">
              <div className="flex flex-wrap items-center gap-x-1.5 gap-y-0.5 font-mono text-[11.5px] text-[var(--ink)]">
                <span className="font-semibold text-[var(--acc)]">{ev.actor ?? "someone"}</span>
                {ev.field ? (
                  <>
                    <span className="text-[var(--mut)]">changed</span>
                    <code className="rounded border border-[var(--line)] bg-[var(--panel2)] px-1 py-0.5 text-xs text-[var(--mut)]">
                      {ev.field}
                    </code>
                    <span className="text-[var(--mut)]">from</span>
                    <code className="rounded border border-[var(--line)] bg-[var(--panel2)] px-1 py-0.5 text-xs text-[var(--mut)]">
                      {ev.old_value ?? "∅"}
                    </code>
                    <span className="text-[var(--mut)]">to</span>
                    <code className="rounded border border-[var(--line)] bg-[var(--panel2)] px-1 py-0.5 text-xs text-[var(--ink)]">
                      {ev.new_value ?? "∅"}
                    </code>
                  </>
                ) : (
                  <span className="text-[var(--mut)]">touched this item</span>
                )}
              </div>
              {ev.occurred_at && (
                <time
                  className="font-mono text-xs text-[var(--faint)]"
                  dateTime={ev.occurred_at}
                  title={new Date(ev.occurred_at).toLocaleString()}
                >
                  {timeAgo(ev.occurred_at)}
                </time>
              )}
            </li>
          ))}
        </ol>
      )}
    </SectionCard>
  );
}

function byOccurredDesc(a: { occurred_at?: string }, b: { occurred_at?: string }): number {
  const ta = a.occurred_at ? new Date(a.occurred_at).getTime() : 0;
  const tb = b.occurred_at ? new Date(b.occurred_at).getTime() : 0;
  return tb - ta;
}
