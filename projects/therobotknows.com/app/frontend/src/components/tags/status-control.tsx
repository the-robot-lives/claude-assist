"use client";

import { cn } from "@/lib/cn";
import type { EntryStatus } from "@/lib/constants";

const STATUSES: { value: EntryStatus; label: string }[] = [
  { value: "draft", label: "Draft" },
  { value: "generated", label: "Generated" },
  { value: "canon", label: "Canon" },
];

export function StatusBadge({ status }: { status: EntryStatus | string }) {
  const isCanon = status === "canon";
  const isGenerated = status === "generated";
  return (
    <span
      className={cn(
        "font-mono text-[11px] uppercase tracking-[0.06em] px-2 py-0.5 rounded-full border",
        isCanon && "border-ink text-ink bg-surface",
        isGenerated && "border-generated border-dashed text-generated",
        !isCanon && !isGenerated && "border-rule text-ink-secondary bg-elevated",
      )}
    >
      {status}
    </span>
  );
}

export function StatusControl({
  value,
  onChange,
  disabled,
}: {
  value: EntryStatus | string;
  onChange: (status: EntryStatus) => void;
  disabled?: boolean;
}) {
  return (
    <div className="flex flex-wrap gap-2">
      {STATUSES.map((s) => (
        <button
          key={s.value}
          type="button"
          disabled={disabled}
          onClick={() => onChange(s.value)}
          className={cn(
            "font-mono text-[11px] uppercase tracking-[0.06em] px-3 py-1.5 rounded-full border transition-colors",
            value === s.value
              ? s.value === "canon"
                ? "border-ink bg-ink text-page"
                : s.value === "generated"
                  ? "border-generated border-dashed bg-flag-warn-muted text-ink"
                  : "border-accent bg-accent-muted text-accent"
              : "border-rule text-ink-tertiary hover:border-rule-heavy",
            disabled && "opacity-50 cursor-not-allowed",
          )}
        >
          {s.label}
        </button>
      ))}
    </div>
  );
}
