// Card container with a titled header, optional count + action slot; plus the small
// `Empty` placeholder for empty card bodies. Moved here from components/pm/priority-badge.tsx.
//
// This is the padded-body sibling of `Panel`: same 14px rounded surface and header
// strip, but the body keeps its own padding so existing callers can drop arbitrary
// content in. Reach for `Panel` + `PanelHeader` when rows or tables need to run
// edge-to-edge.

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
    <section className="overflow-hidden rounded-panel border border-line bg-panel shadow-card">
      <header className="flex items-baseline gap-2.5 border-b border-line px-4 py-2.5">
        <h2 className="text-[12px] font-bold uppercase tracking-[0.1em] text-ink">{title}</h2>
        {count != null && <span className="text-[11px] text-faint">{count}</span>}
        {action && <span className="ml-auto text-[11px] text-mut">{action}</span>}
      </header>
      <div className="p-4">{children}</div>
    </section>
  );
}

export function Empty({ children }: { children: React.ReactNode }) {
  return <p className="py-6 text-center text-[12px] text-faint">{children}</p>;
}
