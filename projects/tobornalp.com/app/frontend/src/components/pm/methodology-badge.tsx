// Small labeled pill for a project's delivery methodology. Used in the project
// list and detail. Wears the shared `Chip` recipe in the `scope` variant — a
// methodology is context, not a signal, so it must not compete with mint.

import { Chip } from "@/components/ui";

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
    <Chip variant="scope" className={className}>
      {meta.label}
    </Chip>
  );
}
