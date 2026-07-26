"use client";

import { SectionCard, Empty } from "@/components/ui";
import { PersonalItemRow } from "./personal-item-row";
import type { PersonalItem, PersonalBucket, RecurrenceInput } from "@/lib/api";

const ORDER: Array<{ key: PersonalBucket; label: string; accent?: boolean }> = [
  { key: "overdue", label: "Overdue", accent: true },
  { key: "today", label: "Today" },
  { key: "upcoming", label: "Upcoming" },
  { key: "someday", label: "Someday" },
];

// Renders the four due buckets, each a SectionCard. Empty buckets collapse
// (except we always show Today so the list never looks broken). Overdue carries a
// red accent header.
export function PersonalItemList({
  groups,
  onComplete,
  onSetRecurrence,
}: {
  groups: Record<PersonalBucket, PersonalItem[]>;
  onComplete: (item: PersonalItem) => void;
  onSetRecurrence: (item: PersonalItem, rule: RecurrenceInput | null) => void;
}) {
  return (
    <div className="space-y-4">
      {ORDER.map(({ key, label, accent }) => {
        const items = groups[key] || [];
        if (items.length === 0 && key !== "today") return null;

        return (
          <SectionCard
            key={key}
            title={label}
            count={items.length}
            action={accent && items.length > 0 ? <span className="text-[11px] font-bold text-err">needs attention</span> : undefined}
          >
            {items.length === 0 ? (
              <Empty>Nothing here.</Empty>
            ) : (
              <ul className="space-y-1">
                {items.map((it) => (
                  <PersonalItemRow key={it.id} item={it} onComplete={onComplete} onSetRecurrence={onSetRecurrence} />
                ))}
              </ul>
            )}
          </SectionCard>
        );
      })}
    </div>
  );
}
