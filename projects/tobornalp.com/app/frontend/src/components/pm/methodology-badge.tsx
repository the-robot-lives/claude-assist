// Small labeled pill for a project's delivery methodology. Used in the project
// list and detail. Token-styled, dark-mode aware (tokens carry both themes).

const META: Record<string, { label: string }> = {
  kanban: { label: "Kanban" },
  scrum: { label: "Scrum" },
  waterfall: { label: "Waterfall" },
  spiral: { label: "Spiral" },
  custom: { label: "Custom" },
};

export function MethodologyBadge({
  methodology,
  className = "",
}: {
  methodology?: string | null;
  className?: string;
}) {
  const key = (methodology || "").toLowerCase();
  const meta = META[key];
  if (!meta) return null;

  return (
    <span
      className={`inline-flex items-center rounded border border-border bg-surface-alt px-1.5 py-0.5 text-[11px] font-medium text-text-secondary ${className}`}
    >
      {meta.label}
    </span>
  );
}
