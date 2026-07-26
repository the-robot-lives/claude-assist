import { cn } from "@/lib/cn";

// PriorityDot — an 8px signal, no text. `hi` carries a subtle bloom so it reads
// first in a dense row; `cr` (critical) adds a ring on top of that.
export type PriorityLevel = "cr" | "hi" | "md" | "lo";

const LEVEL: Record<PriorityLevel, string> = {
  cr: "bg-err outline-2 outline-[var(--err-bg)]",
  hi: "bg-err shadow-[0_0_6px_var(--err-bg)]",
  md: "bg-warn",
  lo: "bg-line2",
};

const LABEL: Record<PriorityLevel, string> = {
  cr: "critical priority",
  hi: "high priority",
  md: "medium priority",
  lo: "low priority",
};

export interface PriorityDotProps {
  level: PriorityLevel;
  className?: string;
}

export function PriorityDot({ level, className }: PriorityDotProps) {
  return (
    <span
      role="img"
      aria-label={LABEL[level]}
      title={LABEL[level]}
      className={cn("inline-block h-2 w-2 flex-none rounded-full", LEVEL[level], className)}
    />
  );
}

/** Maps the API's priority strings onto the four dot levels. */
export function toPriorityLevel(priority?: string | null): PriorityLevel | null {
  switch (priority) {
    case "critical":
      return "cr";
    case "high":
      return "hi";
    case "medium":
      return "md";
    case "low":
      return "lo";
    default:
      return null;
  }
}
