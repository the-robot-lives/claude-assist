"use client";

// Reviews list — descriptor-driven DataTable + a create modal that opens a review
// over an artifact + its latest revision. A review targets a specific revision,
// so create resolves the artifact's current revision_id before calling createReview.
// Thin shell over the substrate (mirrors the items list org-resolution pattern).
import { useEffect, useMemo, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { api, type Artifact } from "@/lib/api";
import { useOrg } from "@/context/org";
import { DataTable } from "@/components/console/DataTable";
import { reviewsDescriptor } from "@/lib/console/descriptors/reviews";
import { Button, Input, Select, Dialog } from "@/components/ui";

export default function ReviewsPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg, loading: orgLoading } = useOrg();
  const router = useRouter();
  const orgId = currentOrg?.id || params.orgId;

  // Artifacts power the create-review picker (a review targets an artifact).
  const [artifacts, setArtifacts] = useState<Artifact[]>([]);
  const [showCreate, setShowCreate] = useState(false);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    if (!orgId) return;
    let live = true;
    api
      .listArtifacts(orgId)
      .then((res) => live && setArtifacts(res.artifacts ?? []))
      .catch(() => live && setArtifacts([]));
    return () => {
      live = false;
    };
  }, [orgId]);

  const ctx = useMemo(() => ({ orgId: orgId ?? "" }), [orgId]);

  return (
    <div className="mx-auto max-w-6xl px-4 py-6">
      <header className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text">Reviews</h1>
          <p className="text-sm text-text-secondary">
            {currentOrg?.name || "Organization"} · code & content reviews
          </p>
        </div>
        {/* A review targets an artifact — only offer create when one exists. */}
        {artifacts.length > 0 && <Button onClick={() => setShowCreate(true)}>+ New review</Button>}
      </header>

      {orgLoading || !orgId ? (
        <p className="text-sm text-text-muted">
          {orgLoading ? "Loading…" : "Select an organization."}
        </p>
      ) : (
        <DataTable
          descriptor={reviewsDescriptor}
          ctx={ctx}
          refreshKey={reloadKey}
          onOpenRow={(r) => router.push(`/app/${orgId}/reviews/${r.id}`)}
        />
      )}

      {showCreate && orgId && (
        <CreateReviewDialog
          orgId={orgId}
          artifacts={artifacts}
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

function CreateReviewDialog({
  orgId,
  artifacts,
  onClose,
  onSaved,
}: {
  orgId: string;
  artifacts: Artifact[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const [artifactId, setArtifactId] = useState("");
  const [persona, setPersona] = useState("");
  const [title, setTitle] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!artifactId || !persona.trim()) return;
    setSaving(true);
    setError(null);
    try {
      // Resolve the artifact's latest revision — a review pins a specific revision.
      const { artifact } = await api.getArtifact(orgId, artifactId);
      if (!artifact.revision_id) {
        throw new Error("Selected artifact has no revision to review");
      }
      await api.createReview(orgId, {
        artifact_id: artifactId,
        revision_id: artifact.revision_id,
        reviewer_persona: persona.trim(),
        title: title.trim() || undefined,
        project_id: artifact.project_id ?? undefined,
      });
      toast.success("Review started");
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
      title="Start review"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button
            type="submit"
            form="create-review-form"
            disabled={saving || !artifactId || !persona.trim()}
          >
            {saving ? "Starting…" : "Start"}
          </Button>
        </>
      }
    >
      <form id="create-review-form" onSubmit={submit} className="space-y-3">
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Artifact</span>
          <Select value={artifactId} onChange={(e) => setArtifactId(e.target.value)}>
            <option value="">Select an artifact…</option>
            {artifacts.map((a) => (
              <option key={a.id} value={a.id}>
                {a.title} ({a.kind})
              </option>
            ))}
          </Select>
          <span className="text-xs text-text-muted">
            The latest revision of this artifact will be reviewed.
          </span>
        </label>
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Reviewer persona</span>
          <Input
            value={persona}
            onChange={(e) => setPersona(e.target.value)}
            placeholder="senior-engineer"
            autoFocus
          />
        </label>
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Title</span>
          <Input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Optional review title"
          />
        </label>
        {error && <p className="text-sm text-error">{error}</p>}
      </form>
    </Dialog>
  );
}
