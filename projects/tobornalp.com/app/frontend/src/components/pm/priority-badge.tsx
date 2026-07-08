// Small shared PM UI primitives — theme-token driven (Tailwind vars) + dark-mode aware.
// No design-system dependency beyond the globals.css token utilities.

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

export function ProgressBar({ value }: { value?: string | number }) {
  const pct = clampPct(value);
  return (
    <div className="h-1.5 w-full overflow-hidden rounded-full bg-border">
      <div className="h-full rounded-full bg-brand-blue transition-all" style={{ width: `${pct}%` }} />
    </div>
  );
}

function clampPct(v?: string | number): number {
  if (v == null) return 0;
  // value may be a fraction (0..1) or already a percentage, or a Decimal string.
  let n = typeof v === "number" ? v : parseFloat(String(v));
  if (Number.isNaN(n)) return 0;
  if (n <= 1) n *= 100; // treat 0..1 as a fraction
  return Math.max(0, Math.min(100, n));
}

export function SectionCard({
  title,
  count,
  children,
  action,
}: {
  title: string;
  count?: number;
  children: React.ReactNode;
  action?: React.ReactNode;
}) {
  return (
    <section className="rounded-lg border border-border bg-surface p-4 shadow-sm">
      <header className="mb-3 flex items-center justify-between">
        <h2 className="flex items-center gap-2 text-sm font-semibold text-text">
          {title}
          {count != null && <span className="text-text-muted">({count})</span>}
        </h2>
        {action}
      </header>
        {children}
    </section>
  );
}

export function Empty({ children }: { children: React.ReactNode }) {
  return <p className="py-6 text-center text-sm text-text-muted">{children}</p>;
}
