"use client";

// Artifacts list — descriptor-driven DataTable + create modal. A thin shell over
// the console substrate (mirrors the items list page's org-resolution pattern).
// Artifacts are versioned typed content; create seeds the first revision's
// content, and subsequent edits append revisions (handled on the detail page).
import { useEffect, useMemo, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { api, type Project } from "@/lib/api";
import { useOrg } from "@/context/org";
import { DataTable } from "@/components/console/DataTable";
import { artifactsDescriptor, ARTIFACT_KIND_OPTIONS } from "@/lib/console/descriptors/artifacts";
import { Btn, Input, Select, Textarea, Dialog, FieldLabel } from "@/components/ui";

export default function ArtifactsPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg, loading: orgLoading } = useOrg();
  const router = useRouter();
  const orgId = currentOrg?.id || params.orgId;

  const [projects, setProjects] = useState<Project[]>([]);
  const [showCreate, setShowCreate] = useState(false);
  // Bump to refetch <DataTable> in place after a create (it owns its own fetch).
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    if (!orgId) return;
    let live = true;
    api
      .listProjects(orgId)
      .then((res) => live && setProjects(res.projects ?? []))
      .catch(() => live && setProjects([]));
    return () => {
      live = false;
    };
  }, [orgId]);

  const ctx = useMemo(() => ({ orgId: orgId ?? "" }), [orgId]);

  return (
    <div className="app-content">
      <header className="flex flex-wrap items-baseline gap-3">
        <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">artifacts</h1>
        <span className="text-[11px] text-faint">
          {currentOrg?.name || "organization"} · versioned typed content
        </span>
        <Btn variant="primary" className="ml-auto" onClick={() => setShowCreate(true)}>
          + new artifact
        </Btn>
      </header>

      {orgLoading || !orgId ? (
        <p className="text-[12px] text-faint">
          {orgLoading ? "loading…" : "select an organization."}
        </p>
      ) : (
        <DataTable
          descriptor={artifactsDescriptor}
          ctx={ctx}
          refreshKey={reloadKey}
          onOpenRow={(a) => router.push(`/app/${orgId}/artifacts/${a.id}`)}
        />
      )}

      {showCreate && orgId && (
        <CreateArtifactDialog
          orgId={orgId}
          projects={projects}
          onClose={() => setShowCreate(false)}
          onSaved={() => {
            setShowCreate(false);
            setReloadKey((k) => k + 1);
          }}
        />
      )}
    </div>
  );
}

function CreateArtifactDialog({
  orgId,
  projects,
  onClose,
  onSaved,
}: {
  orgId: string;
  projects: Project[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const [title, setTitle] = useState("");
  const [kind, setKind] = useState("document");
  const [mimeType, setMimeType] = useState("");
  const [content, setContent] = useState("");
  const [projectId, setProjectId] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) return;
    setSaving(true);
    setError(null);
    try {
      await api.createArtifact(orgId, {
        title: title.trim(),
        kind,
        mime_type: mimeType.trim() || undefined,
        content: content || undefined,
        project_id: projectId || undefined,
      });
      toast.success("artifact created");
      onSaved();
    } catch (err) {
      setError(err instanceof Error ? err.message : "request failed");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Dialog
      open
      onClose={onClose}
      title="create artifact"
      footer={
        <>
          <Btn variant="default" onClick={onClose}>
            cancel
          </Btn>
          <Btn variant="primary" type="submit" form="create-artifact-form" disabled={saving || !title.trim()}>
            {saving ? "creating…" : "create"}
          </Btn>
        </>
      }
    >
      <form id="create-artifact-form" onSubmit={submit} className="flex flex-col gap-3">
        <FieldLabel label="title" htmlFor="art-title">
          <Input
            id="art-title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="artifact title"
            className="rounded-card border-line2 bg-ground"
            autoFocus
          />
        </FieldLabel>
        <div className="grid gap-3 sm:grid-cols-2">
          <FieldLabel label="kind" htmlFor="art-kind">
            <Select
              id="art-kind"
              value={kind}
              onChange={(e) => setKind(e.target.value)}
              className="rounded-card border-line2 bg-ground"
            >
              {ARTIFACT_KIND_OPTIONS.map((k) => (
                <option key={k.value} value={k.value}>
                  {k.label}
                </option>
              ))}
            </Select>
          </FieldLabel>
          <FieldLabel label="mime type" htmlFor="art-mime">
            <Input
              id="art-mime"
              value={mimeType}
              onChange={(e) => setMimeType(e.target.value)}
              placeholder="text/plain (optional)"
              className="rounded-card border-line2 bg-ground"
            />
          </FieldLabel>
        </div>
        <FieldLabel label="project" htmlFor="art-project">
          <Select
            id="art-project"
            value={projectId}
            onChange={(e) => setProjectId(e.target.value)}
            className="rounded-card border-line2 bg-ground"
          >
            <option value="">no project</option>
            {projects.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </Select>
        </FieldLabel>
        <FieldLabel label="initial content" htmlFor="art-content">
          <Textarea
            id="art-content"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder="optional seed content for the first revision"
            className="rounded-card border-line2 bg-ground"
            rows={5}
          />
        </FieldLabel>
        {error && <p className="text-[12px] text-err">[ERR] {error}</p>}
      </form>
    </Dialog>
  );
}
