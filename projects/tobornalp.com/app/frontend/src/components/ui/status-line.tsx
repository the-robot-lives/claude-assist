import { cn } from "@/lib/cn";

// StatusLine — the terse strip under the topbar. Each segment leads with a
// bracketed status token, which is how this product says "fine / careful /
// broken / fyi" everywhere.
export type StatusTone = "ok" | "warn" | "err" | "info";

const TONE: Record<StatusTone, { label: string; className: string }> = {
  ok: { label: "[OK]", className: "text-acc" },
  warn: { label: "[WARN]", className: "text-warn" },
  err: { label: "[ERR]", className: "text-err" },
  info: { label: "[INFO]", className: "text-info" },
};

export interface StatusLineProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
}

export function StatusLine({ children, className, ...props }: StatusLineProps) {
  return (
    <div
      className={cn(
        "flex flex-wrap gap-4 border-b border-line bg-ground px-[18px] py-1.5 text-[11.5px] text-mut",
        className,
      )}
      {...props}
    >
      {children}
    </div>
  );
}

export interface StatusSegProps {
  tone: StatusTone;
  children: React.ReactNode;
  className?: string;
}

export function StatusSeg({ tone, children, className }: StatusSegProps) {
  const t = TONE[tone];
  return (
    <span className={cn("inline-flex items-baseline gap-1.5", className)}>
      <span className={cn("font-bold", t.className)}>{t.label}</span>
      {children}
    </span>
  );
}

/** The bracketed token on its own — for inline use inside feeds and log lines. */
export function StatusTag({ tone, className }: { tone: StatusTone; className?: string }) {
  const t = TONE[tone];
  return <span className={cn("font-bold", t.className, className)}>{t.label}</span>;
}
