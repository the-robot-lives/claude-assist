"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { toast } from "sonner";
import { useOrg } from "@/context/org";
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Button, Spinner } from "@/components/ui";
import { MethodologyBadge } from "@/components/pm/methodology-badge";

export default function ProjectDetailPage() {
  const params = useParams<{ orgId: string; projectId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;
  const projectId = params.projectId;

  const { data, error, loading, mutate } = useApi(
    () => api.getProject(orgId, projectId),
    [orgId, projectId],
  );
  const project = data?.project;

  const setArchived = async (archived: boolean) => {
    try {
      if (archived) {
        await api.archiveProject(orgId, projectId);
        toast.success("Project archived");
      } else {
        await api.unarchiveProject(orgId, projectId);
        toast.success("Project unarchived");
      }
      mutate();
    } catch (e) {
      toast.error((e as Error).message);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center py-12">
        <Spinner />
      </div>
    );
  }

  if (error || !project) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-6">
        <Link href={`/app/${orgId}/projects`} className="text-xs text-text-muted hover:text-text">
          ← Projects
        </Link>
        <p className="mt-4 text-sm text-brand-red">{error?.message || "Project not found"}</p>
      </div>
    );
  }

  const board = project.default_queue;
  const archived = project.status === "archived";

  return (
    <div className="mx-auto max-w-3xl px-4 py-6">
      <Link href={`/app/${orgId}/projects`} className="text-xs text-text-muted hover:text-text">
        ← Projects
      </Link>

      <header className="mt-2 flex items-start justify-between gap-4">
        <div className="min-w-0">
          <div className="flex items-center gap-2">
            <h1 className="truncate text-2xl font-bold text-text">{project.name}</h1>
            <MethodologyBadge methodology={project.default_methodology} />
            {archived && (
              <span className="rounded border border-border px-1.5 py-0.5 text-[11px] text-text-muted">
                archived
              </span>
            )}
          </div>
          <p className="mt-1 text-sm text-text-secondary">
            {project.slug}
            {project.key_prefix ? ` · ${project.key_prefix}` : ""}
          </p>
        </div>
        <Button size="sm" variant={archived ? "outline" : "danger"} onClick={() => setArchived(!archived)}>
          {archived ? "Unarchive" : "Archive"}
        </Button>
      </header>

      {project.description && (
        <p className="mt-4 text-sm text-text">{project.description}</p>
      )}

      <div className="mt-6 rounded-lg border border-border bg-surface p-4">
        <h2 className="text-sm font-semibold text-text">Board</h2>
        {board ? (
          <div className="mt-2 flex items-center justify-between gap-3">
            <p className="text-sm text-text-secondary">
              {board.stage_count} stage{board.stage_count === 1 ? "" : "s"} ·{" "}
              <span className="capitalize">{board.methodology}</span>
            </p>
            <Link href={`/app/${orgId}/items/boards/${board.id}`}>
              <Button size="sm">Open board →</Button>
            </Link>
          </div>
        ) : (
          <p className="mt-2 text-sm text-text-muted">No board provisioned.</p>
        )}
      </div>
    </div>
  );
}
