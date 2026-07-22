// Card container with a titled header, optional count + action slot; plus the small
// `Empty` placeholder for empty card bodies. Moved here from components/pm/priority-badge.tsx.

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
