"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Btn, EmptyState, Spinner, Chip, StatusTag, Panel } from "@/components/ui";
import { MethodologyBadge } from "@/components/pm/methodology-badge";

export default function ProjectsPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;

  const { data, error, loading } = useApi(() => api.listProjects(orgId), [orgId]);
  const projects = data?.projects ?? [];

  return (
    <div className="app-content max-w-4xl">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">projects</h1>
          <p className="mt-1 text-[11px] text-mut">
            {currentOrg?.name || "organization"} · delivery projects
          </p>
        </div>
        <Link href={`/app/${orgId}/projects/new`}>
          <Btn variant="primary">+ new project</Btn>
        </Link>
      </header>

      {loading ? (
        <div className="flex justify-center py-12">
          <Spinner />
        </div>
      ) : error ? (
        <p className="text-sm text-err">
          <StatusTag tone="err" /> {error.message}
        </p>
      ) : projects.length === 0 ? (
        <EmptyState
          title="no projects yet"
          action={
            <Link href={`/app/${orgId}/projects/new`}>
              <Btn variant="primary">create project</Btn>
            </Link>
          }
        >
          create a project to declare how your team works and get a ready-to-use board.
        </EmptyState>
      ) : (
        <Panel>
          {projects.map((p) => (
            <Link
              key={p.id}
              href={`/app/${orgId}/projects/${p.id}`}
              className="flex items-center gap-3 border-b border-line px-4 py-3 last:border-b-0 hover:bg-sel"
            >
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="truncate text-[13px] font-bold text-ink">{p.name}</span>
                  <MethodologyBadge methodology={p.default_methodology} />
                  {p.key_prefix && <Chip variant="scope">{p.key_prefix}</Chip>}
                </div>
                {p.description && (
                  <p className="mt-1 truncate text-xs text-mut">{p.description}</p>
                )}
              </div>
              <span className="shrink-0 text-xs text-faint">open →</span>
            </Link>
          ))}
        </Panel>
      )}
    </div>
  );
}
