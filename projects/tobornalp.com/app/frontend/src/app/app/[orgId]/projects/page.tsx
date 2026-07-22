"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Button, EmptyState, Spinner } from "@/components/ui";
import { MethodologyBadge } from "@/components/pm/methodology-badge";

export default function ProjectsPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;

  const { data, error, loading } = useApi(() => api.listProjects(orgId), [orgId]);
  const projects = data?.projects ?? [];

  return (
    <div className="mx-auto max-w-4xl px-4 py-6">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text">Projects</h1>
          <p className="text-sm text-text-secondary">
            {currentOrg?.name || "Organization"} · delivery projects
          </p>
        </div>
        <Link href={`/app/${orgId}/projects/new`}>
          <Button size="sm">+ New project</Button>
        </Link>
      </header>

      {loading ? (
        <div className="flex justify-center py-12">
          <Spinner />
        </div>
      ) : error ? (
        <p className="text-sm text-brand-red">{error.message}</p>
      ) : projects.length === 0 ? (
        <EmptyState
          title="No projects yet"
          action={
            <Link href={`/app/${orgId}/projects/new`}>
              <Button size="sm">Create project</Button>
            </Link>
          }
        >
          Create a project to declare how your team works and get a ready-to-use board.
        </EmptyState>
      ) : (
        <ul className="space-y-2">
          {projects.map((p) => (
            <li key={p.id} className="rounded-lg border border-border bg-surface">
              <Link
                href={`/app/${orgId}/projects/${p.id}`}
                className="flex items-center gap-3 px-4 py-3"
              >
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="truncate text-sm font-medium text-text">{p.name}</span>
                    <MethodologyBadge methodology={p.default_methodology} />
                    {p.key_prefix && (
                      <span className="rounded border border-border px-1.5 py-0.5 text-[11px] text-text-muted">
                        {p.key_prefix}
                      </span>
                    )}
                  </div>
                  {p.description && (
                    <p className="mt-1 truncate text-xs text-text-secondary">{p.description}</p>
                  )}
                </div>
                <span className="shrink-0 text-xs text-text-muted">Open →</span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
