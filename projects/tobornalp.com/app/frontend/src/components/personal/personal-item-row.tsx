"use client";

import { PriorityBadge } from "@/components/ui";
import { RecurrencePicker } from "./recurrence-picker";
import type { PersonalItem, RecurrenceInput } from "@/lib/api";

// One personal todo. Checkbox completes (optimistic at the list level); shows due
// badge (red when overdue), tag chips, a recurrence glyph, and an inline
// recurrence editor. There is no ItemCard primitive yet, so this is the
// personal-lane row equivalent.
export function PersonalItemRow({
  item,
  onComplete,
  onSetRecurrence,
}: {
  item: PersonalItem;
  onComplete: (item: PersonalItem) => void;
  onSetRecurrence: (item: PersonalItem, rule: RecurrenceInput | null) => void;
}) {
  const done = item.status === "done";

  return (
    <li className="flex items-center gap-2 rounded border border-transparent px-2 py-1.5 text-sm hover:border-border hover:bg-surface-alt">
      <button
        type="button"
        aria-label={done ? "completed" : "complete"}
        onClick={() => !done && onComplete(item)}
        disabled={done}
        className={
          "flex h-4 w-4 shrink-0 items-center justify-center rounded border " +
          (done ? "border-success bg-success text-white" : "border-border hover:border-brand-blue")
        }
      >
        {done && <span className="text-[10px] leading-none">✓</span>}
      </button>

      <span className={"flex-1 truncate text-text " + (done ? "line-through text-text-muted" : "")}>
        {item.title}
      </span>

      {item.recurrence && <span title="repeats" className="text-text-muted">↻</span>}

      {item.tags.slice(0, 3).map((t) => (
        <span key={t} className="rounded bg-brand-blue/10 px-1.5 py-0.5 text-[11px] text-brand-blue">#{t}</span>
      ))}

      {item.due_date && (
        <span className={"whitespace-nowrap text-xs " + (item.overdue ? "font-medium text-brand-red" : "text-text-muted")}>
          {formatDue(item.due_date)}
        </span>
      )}

      <PriorityBadge priority={item.priority} />

      <div className="w-44 shrink-0">
        <RecurrencePicker
          value={recurrenceToInput(item)}
          onChange={(rule) => onSetRecurrence(item, rule)}
        />
      </div>
    </li>
  );
}

function recurrenceToInput(item: PersonalItem): RecurrenceInput | null {
  if (!item.recurrence) return null;
  const r = item.recurrence;
  return { freq: r.freq as RecurrenceInput["freq"], interval: r.interval, by_day: r.by_day };
}

function formatDue(iso: string): string {
  const d = new Date(iso + "T00:00:00");
  return d.toLocaleDateString(undefined, { month: "short", day: "numeric" });
}
