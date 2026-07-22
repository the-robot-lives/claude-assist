"use client";

// DetailView — config-driven console detail primitive. Ported from npl-mcp and
// retuned to tobornalp tokens. Renders a descriptor's detail.sections (field grid)
// + detail.related as embedded read-only mini DataTables, with a back affordance
// and an Edit entry. a11y: a labelled <article>, section headings, a real back button.
import type { ReactNode } from "react";
import type { ConsoleDescriptor, ConsoleContext, DetailFieldDef } from "@/lib/console/types";
import { renderField } from "@/lib/console/render-hints";
import { getDescriptor } from "@/lib/console/registry";
import { DataTable } from "./DataTable";
import { Button } from "@/components/ui";

export interface DetailViewProps<T, TInput> {
  descriptor: ConsoleDescriptor<T, TInput>;
  row: T;
  ctx: ConsoleContext;
  /** Back-with-state: the page owns history/scroll restoration. */
  onBack?: () => void;
  /** Open the edit form for this row (omit when not editable). */
  onEdit?: (row: T) => void;
}

export function DetailView<T, TInput>({ descriptor, row, ctx, onBack, onEdit }: DetailViewProps<T, TInput>) {
  const { detail, labels, columns, idKey = "id" } = descriptor;
  const r = row as Record<string, unknown>;

  // Title = the primary column's value (name/title), falling back to the id.
  const primaryKey = columns.find((c) => c.primary)?.key ?? "name";
  const title = String(r[primaryKey] ?? r[idKey] ?? labels.singular);

  function field(f: DetailFieldDef<T>): ReactNode {
    return renderField(f.render, f.key, row);
  }

  return (
    <article className="mx-auto max-w-3xl px-4 py-6" aria-label={`${labels.singular} detail`}>
      <header className="mb-6">
        {onBack && (
          <button
            type="button"
            className="mb-2 text-xs text-text-muted hover:text-text hover:underline"
            onClick={onBack}
          >
            ← {labels.plural}
          </button>
        )}
        <div className="flex items-center justify-between gap-3">
          <h1 className="text-2xl font-bold text-text">{title}</h1>
          {descriptor.api.update && onEdit && (
            <Button variant="outline" size="sm" onClick={() => onEdit(row)}>
              Edit
            </Button>
          )}
        </div>
      </header>

      <div className="space-y-6">
        {detail.sections.map((section) => (
          <section key={section.title} className="rounded-lg border border-border bg-surface p-4">
            <h2 className="mb-3 text-sm font-semibold text-text-secondary">{section.title}</h2>
            <dl className="grid grid-cols-1 gap-x-6 gap-y-2 sm:grid-cols-2">
              {section.fields.map((f) => (
                <div
                  key={f.key}
                  className={f.span ? "sm:col-span-2" : undefined}
                >
                  <dt className="text-xs text-text-muted">{f.label}</dt>
                  <dd className="text-sm text-text">{field(f)}</dd>
                </div>
              ))}
            </dl>
          </section>
        ))}

        {detail.related?.map((rel) => {
          const relDescriptor = getDescriptor(rel.domain);
          return (
            <section key={rel.title} className="rounded-lg border border-border bg-surface p-4">
              <h2 className="mb-3 text-sm font-semibold text-text-secondary">{rel.title}</h2>
              {relDescriptor ? (
                <DataTable descriptor={relDescriptor} ctx={ctx} embedded scope={rel.query(r)} density="compact" />
              ) : (
                <p className="text-sm text-text-muted">No “{rel.domain}” view registered yet.</p>
              )}
            </section>
          );
        })}
      </div>
    </article>
  );
}
