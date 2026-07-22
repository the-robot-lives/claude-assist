// Thin progress meter — accepts a 0..1 fraction, a 0..100 percentage, or a Decimal string.
// Moved here from components/pm/priority-badge.tsx.

export function ProgressBar({ value }: { value?: string | number }) {
  const pct = clampPct(value);
  return (
    <div
      className="h-1.5 w-full overflow-hidden rounded-full bg-border"
      role="progressbar"
      aria-valuenow={Math.round(pct)}
      aria-valuemin={0}
      aria-valuemax={100}
    >
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
