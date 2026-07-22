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
import { Button, Input, Select, Textarea, Dialog } from "@/components/ui";

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
    <div className="mx-auto max-w-6xl px-4 py-6">
      <header className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text">Artifacts</h1>
          <p className="text-sm text-text-secondary">
            {currentOrg?.name || "Organization"} · versioned typed content
          </p>
        </div>
        <Button onClick={() => setShowCreate(true)}>+ New artifact</Button>
      </header>

      {orgLoading || !orgId ? (
        <p className="text-sm text-text-muted">
          {orgLoading ? "Loading…" : "Select an organization."}
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
      toast.success("Artifact created");
      onSaved();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Request failed");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Dialog
      open
      onClose={onClose}
      title="Create artifact"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" form="create-artifact-form" disabled={saving || !title.trim()}>
            {saving ? "Creating…" : "Create"}
          </Button>
        </>
      }
    >
      <form id="create-artifact-form" onSubmit={submit} className="space-y-3">
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Title</span>
          <Input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Artifact title"
            autoFocus
          />
        </label>
        <div className="grid gap-3 sm:grid-cols-2">
          <label className="flex flex-col gap-1.5 text-sm">
            <span className="font-medium text-text">Kind</span>
            <Select value={kind} onChange={(e) => setKind(e.target.value)}>
              {ARTIFACT_KIND_OPTIONS.map((k) => (
                <option key={k.value} value={k.value}>
                  {k.label}
                </option>
              ))}
            </Select>
          </label>
          <label className="flex flex-col gap-1.5 text-sm">
            <span className="font-medium text-text">MIME type</span>
            <Input
              value={mimeType}
              onChange={(e) => setMimeType(e.target.value)}
              placeholder="text/plain (optional)"
            />
          </label>
        </div>
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Project</span>
          <Select value={projectId} onChange={(e) => setProjectId(e.target.value)}>
            <option value="">No project</option>
            {projects.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </Select>
        </label>
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Initial content</span>
          <Textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder="Optional seed content for the first revision"
            rows={5}
          />
        </label>
        {error && <p className="text-sm text-error">{error}</p>}
      </form>
    </Dialog>
  );
}
