import { cn } from "@/lib/cn";

// Panel — the primary surface of the console world. Rounded 14px, hairline
// border, hidden overflow so header strips and row dividers meet the edge.
// Body content is NOT padded: rows/tables run edge-to-edge by design, and
// prose blocks bring their own padding.
export interface PanelProps extends React.HTMLAttributes<HTMLElement> {
  children: React.ReactNode;
}

export function Panel({ children, className, ...props }: PanelProps) {
  return (
    <section
      className={cn("overflow-hidden rounded-panel border border-line bg-panel shadow-card", className)}
      {...props}
    >
      {children}
    </section>
  );
}

// Header strip for a Panel: uppercase letterspaced mono title, an optional
// faint subtitle beside it, and an optional right-aligned meta/action slot.
export interface PanelHeaderProps {
  title: React.ReactNode;
  sub?: React.ReactNode;
  right?: React.ReactNode;
  className?: string;
}

export function PanelHeader({ title, sub, right, className }: PanelHeaderProps) {
  return (
    <header className={cn("flex items-baseline gap-2.5 border-b border-line px-4 py-2.5", className)}>
      <h2 className="text-[12px] font-bold uppercase tracking-[0.1em] text-ink">{title}</h2>
      {sub != null && <span className="text-[11px] text-faint">{sub}</span>}
      {right != null && <span className="ml-auto text-[11px] text-mut">{right}</span>}
    </header>
  );
}
