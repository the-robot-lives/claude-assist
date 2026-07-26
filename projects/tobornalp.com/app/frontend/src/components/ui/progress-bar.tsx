import { cn } from "@/lib/cn";

// Thin progress meter — accepts a 0..1 fraction, a 0..100 percentage, or a Decimal string.
// 7px pill track on the elevated surface; mint fill, amber when the tone says the
// work is behind pace.
export type ProgressTone = "ok" | "warned";

export function ProgressBar({
  value,
  tone = "ok",
  className,
}: {
  value?: string | number | null;
  tone?: ProgressTone;
  className?: string;
}) {
  const pct = clampPct(value);
  return (
    <div
      className={cn(
        "relative h-[7px] w-full overflow-hidden rounded-pill border border-line bg-panel2",
        className,
      )}
      role="progressbar"
      aria-valuenow={Math.round(pct)}
      aria-valuemin={0}
      aria-valuemax={100}
    >
      <div
        className={cn(
          "absolute inset-y-0 left-0 rounded-pill transition-all",
          tone === "warned" ? "bg-warn" : "bg-acc",
        )}
        style={{ width: `${pct}%` }}
      />
    </div>
  );
}

function clampPct(v?: string | number | null): number {
  if (v == null) return 0;
  // value may be a fraction (0..1) or already a percentage, or a Decimal string.
  let n = typeof v === "number" ? v : parseFloat(String(v));
  if (Number.isNaN(n)) return 0;
  if (n <= 1) n *= 100; // treat 0..1 as a fraction
  return Math.max(0, Math.min(100, n));
}
