"use client";

import { Chip, PriorityDot, toPriorityLevel } from "@/components/ui";
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

  const level = toPriorityLevel(item.priority);

  return (
    <li className="flex items-center gap-2.5 rounded-card border border-transparent px-2 py-1.5 text-[12px] hover:border-line hover:bg-sel">
      <button
        type="button"
        aria-label={done ? "completed" : "complete"}
        onClick={() => !done && onComplete(item)}
        disabled={done}
        className={
          "flex h-3.5 w-3.5 shrink-0 items-center justify-center rounded-[5px] border-[1.5px] " +
          // A solid mint field always carries black — never white — ink.
          (done ? "border-acc bg-acc text-black" : "border-line2 bg-panel hover:border-acc")
        }
      >
        {done && <span className="text-[9px] font-bold leading-none">✓</span>}
      </button>

      <span className={"flex-1 truncate " + (done ? "text-faint line-through" : "text-ink")}>
        {item.title}
      </span>

      {item.recurrence && <span title="repeats" className="text-[11px] text-faint">↻</span>}

      {item.tags.slice(0, 3).map((t) => (
        <Chip key={t} variant="scope">#{t}</Chip>
      ))}

      {item.due_date && (
        <span className={"whitespace-nowrap text-[11px] " + (item.overdue ? "font-bold text-err" : "text-faint")}>
          {formatDue(item.due_date)}
        </span>
      )}

      {level && <PriorityDot level={level} />}

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
