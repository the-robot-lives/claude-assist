// Priority / status pills — theme-token driven (Tailwind vars) + dark-mode aware.
// Moved here from components/pm/priority-badge.tsx; that path now re-exports from the ui lib.

export function PriorityBadge({ priority }: { priority?: string }) {
  if (!priority) return null;
  const cls: Record<string, string> = {
    critical: "bg-brand-red/15 text-brand-red border-brand-red/30",
    high: "bg-warning/15 text-warning border-warning/30",
    medium: "bg-brand-blue/15 text-brand-blue border-brand-blue/30",
    low: "bg-text-muted/15 text-text-secondary border-border",
  };
  const c = cls[priority] || cls.low;
  return (
    <span className={`inline-flex items-center rounded border px-1.5 py-0.5 text-[11px] font-medium ${c}`}>
      {priority}
    </span>
  );
}

export function StatusBadge({ status }: { status?: string }) {
  if (!status) return null;
  const tone =
    status === "done" || status === "closed" || status === "completed"
      ? "bg-success/15 text-success border-success/30"
      : status === "in_progress" || status === "active"
        ? "bg-brand-blue/15 text-brand-blue border-brand-blue/30"
        : "bg-text-muted/15 text-text-secondary border-border";
  return (
    <span className={`inline-flex items-center rounded border px-1.5 py-0.5 text-[11px] font-medium ${tone}`}>
      {status.replace(/_/g, " ")}
    </span>
  );
}
