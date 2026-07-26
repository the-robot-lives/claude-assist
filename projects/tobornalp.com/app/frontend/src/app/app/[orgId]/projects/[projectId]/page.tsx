"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { toast } from "sonner";
import { useOrg } from "@/context/org";
import { api } from "@/lib/api";
import { useApi } from "@/lib/use-api";
import { Btn, Spinner, Chip, StatusTag, Panel, PanelHeader } from "@/components/ui";
import { MethodologyBadge } from "@/components/pm/methodology-badge";

// Local destructive pill — coral outline on its own tint, filling solid on hover.
// Mirrors the treatment components/okr/* uses for its own delete actions; kept
// local rather than in components/ui since a shared Btn danger variant may land
// from foundation later.
const DANGER_PILL =
  "inline-flex items-center justify-center rounded-pill border border-err bg-err-bg px-3.5 py-[5px] text-[12px] font-bold text-err transition-colors hover:bg-err hover:text-black disabled:cursor-not-allowed disabled:opacity-60";

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
      <div className="app-content max-w-3xl">
        <Link href={`/app/${orgId}/projects`} className="text-xs text-faint hover:text-ink">
          ← projects
        </Link>
        <p className="text-sm text-err">
          <StatusTag tone="err" /> {error?.message || "project not found"}
        </p>
      </div>
    );
  }

  const board = project.default_queue;
  const archived = project.status === "archived";

  return (
    <div className="app-content max-w-3xl">
      <Link href={`/app/${orgId}/projects`} className="text-xs text-faint hover:text-ink">
        ← projects
      </Link>

      <header className="flex items-start justify-between gap-4">
        <div className="min-w-0">
          <div className="flex items-center gap-2">
            <h1 className="truncate text-2xl font-bold text-ink">{project.name}</h1>
            <MethodologyBadge methodology={project.default_methodology} />
            {archived && <Chip variant="scope">archived</Chip>}
          </div>
          <p className="mt-1 text-sm text-mut">
            {project.slug}
            {project.key_prefix ? ` · ${project.key_prefix}` : ""}
          </p>
        </div>
        {archived ? (
          <Btn onClick={() => setArchived(false)}>unarchive</Btn>
        ) : (
          <button type="button" onClick={() => setArchived(true)} className={DANGER_PILL}>
            archive
          </button>
        )}
      </header>

      {project.description && <p className="text-sm text-ink">{project.description}</p>}

      <Panel>
        <PanelHeader title="board" />
        <div className="p-4">
          {board ? (
            <div className="flex items-center justify-between gap-3">
              <p className="text-sm text-mut">
                {board.stage_count} stage{board.stage_count === 1 ? "" : "s"} ·{" "}
                <span className="capitalize">{board.methodology}</span>
              </p>
              <Link href={`/app/${orgId}/items/boards/${board.id}`}>
                <Btn variant="primary">open board →</Btn>
              </Link>
            </div>
          ) : (
            <p className="text-sm text-faint">no board provisioned.</p>
          )}
        </div>
      </Panel>
    </div>
  );
}
