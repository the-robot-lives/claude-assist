"use client";

import type { Methodology } from "@/lib/api";

// Client-side mirror of the backend `Queues.default_stages/1` (+ the scrum
// "Sprint 1" iteration seeded by Projects.create_with_methodology/4). This is a
// preview only — the server is the source of truth on provisioning. Keep in sync
// with lib/therobotplans/domains/items/queues.ex @default_stages.

export interface StagePreview {
  slug: string;
  name: string;
  kind: string;
}

export interface MethodologyTemplate {
  key: Methodology;
  label: string;
  blurb: string;
  stages: StagePreview[];
  iteration?: string;
}

const KANBAN_STAGES: StagePreview[] = [
  { slug: "todo", name: "To Do", kind: "todo" },
  { slug: "in_progress", name: "In Progress", kind: "in_progress" },
  { slug: "done", name: "Done", kind: "done" },
];

// The four methodologies the create wizard offers (spiral is engine-supported
// but not surfaced here — see US-021 OQ-3).
export const METHODOLOGY_TEMPLATES: MethodologyTemplate[] = [
  {
    key: "kanban",
    label: "Kanban",
    blurb: "Continuous flow. Three columns, no sprints.",
    stages: KANBAN_STAGES,
  },
  {
    key: "scrum",
    label: "Scrum",
    blurb: "Sprints with a review gate. Seeds an active “Sprint 1.”",
    stages: [
      { slug: "todo", name: "To Do", kind: "todo" },
      { slug: "in_progress", name: "In Progress", kind: "in_progress" },
      { slug: "in_review", name: "In Review", kind: "in_review" },
      { slug: "done", name: "Done", kind: "done" },
    ],
    iteration: "Sprint 1",
  },
  {
    key: "waterfall",
    label: "Waterfall",
    blurb: "Sequential phases, requirements through maintenance.",
    stages: [
      { slug: "requirements", name: "Requirements", kind: "phase" },
      { slug: "design", name: "Design", kind: "phase" },
      { slug: "implementation", name: "Implementation", kind: "phase" },
      { slug: "verification", name: "Verification", kind: "phase" },
      { slug: "maintenance", name: "Maintenance", kind: "phase" },
    ],
  },
  {
    key: "custom",
    label: "Custom",
    blurb: "Start from the Kanban set and edit stages later.",
    stages: KANBAN_STAGES,
  },
];

export function templateFor(methodology?: string | null): MethodologyTemplate {
  const key = (methodology || "").toLowerCase();
  return METHODOLOGY_TEMPLATES.find((t) => t.key === key) ?? METHODOLOGY_TEMPLATES[0];
}

// A horizontal preview of the columns/phases a methodology provisions.
export function BoardPreview({ template }: { template: MethodologyTemplate }) {
  return (
    <div className="rounded-lg border border-border bg-surface p-3">
      <div className="mb-2 flex items-center gap-2">
        <span className="text-xs font-medium text-text-secondary">Board preview</span>
        {template.iteration && (
          <span className="rounded border border-border px-1.5 py-0.5 text-[11px] text-text-muted">
            + {template.iteration} (active)
          </span>
        )}
      </div>
      <div className="flex gap-2 overflow-x-auto pb-1">
        {template.stages.map((s) => (
          <div
            key={s.slug}
            className="min-w-[7rem] shrink-0 rounded border border-border bg-surface-alt px-2 py-1.5"
          >
            <div className="text-xs font-medium text-text">{s.name}</div>
            <div className="text-[10px] uppercase tracking-wide text-text-muted">{s.kind}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// Card selector + live board preview. Controlled: parent owns `value`.
export function MethodologyPicker({
  value,
  onChange,
}: {
  value: Methodology;
  onChange: (m: Methodology) => void;
}) {
  const selected = templateFor(value);

  return (
    <div className="space-y-4">
      <div className="grid gap-2 sm:grid-cols-2">
        {METHODOLOGY_TEMPLATES.map((t) => {
          const active = t.key === value;
          return (
            <button
              key={t.key}
              type="button"
              onClick={() => onChange(t.key)}
              aria-pressed={active}
              className={`rounded-lg border p-3 text-left transition-colors ${
                active
                  ? "border-text bg-surface-alt"
                  : "border-border bg-surface hover:bg-surface-alt"
              }`}
            >
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-text">{t.label}</span>
                {active && <span className="text-xs text-text-muted">selected</span>}
              </div>
              <p className="mt-1 text-xs text-text-secondary">{t.blurb}</p>
            </button>
          );
        })}
      </div>
      <BoardPreview template={selected} />
    </div>
  );
}
