"use client";

// Artifact detail — custom (not ConsoleDetailPage) because the revision history
// + create-revision flow is specific to this domain. Shows the artifact's current
// pinned revision (content + revision pointer), the full revision list, lets the
// user view any prior revision's content, and append a new revision.
//
// Content is rendered in a <pre> (no Markdown component in tobornalp); this is a
// stub — polish comes later.
import { useCallback, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { api, type ArtifactDetail, type ArtifactRevision } from "@/lib/api";
import { useOrg } from "@/context/org";
import { Button, Input, Textarea } from "@/components/ui";

export default function ArtifactDetailPage() {
  const params = useParams<{ orgId: string; id: string }>();
  const { currentOrg } = useOrg();
  const router = useRouter();
  const orgId = currentOrg?.id || params.orgId;
  const artifactId = params.id;

  // `view` is the currently-displayed revision (latest by default). `null` means
  // "show the current/latest pinned revision".
  const [artifact, setArtifact] = useState<ArtifactDetail | null>(null);
  const [revisions, setRevisions] = useState<ArtifactRevision[]>([]);
  const [viewRevisionId, setViewRevisionId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // New-revision form state.
  const [showForm, setShowForm] = useState(false);
  const [draftContent, setDraftContent] = useState("");
  const [draftNote, setDraftNote] = useState("");
  const [saving, setSaving] = useState(false);

  const loadLatest = useCallback(async () => {
    if (!orgId || !artifactId) return;
    setLoading(true);
    setError(null);
    try {
      const res = await api.getArtifact(orgId, artifactId);
      setArtifact(res.artifact);
      setDraftContent(res.artifact.content ?? "");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load artifact");
    } finally {
      setLoading(false);
    }
  }, [orgId, artifactId]);

  const loadRevisions = useCallback(async () => {
    if (!orgId || !artifactId) return;
    try {
      const res = await api.listArtifactRevisions(orgId, artifactId);
      setRevisions(res.revisions ?? []);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to load revisions");
    }
  }, [orgId, artifactId]);

  useEffect(() => {
    loadLatest();
    loadRevisions();
  }, [loadLatest, loadRevisions]);

  // View a specific revision by id (fetches that revision's content); null = latest.
  async function viewRevision(revisionId: string | null) {
    if (!orgId || !artifactId) return;
    setViewRevisionId(revisionId);
    try {
      const res = await api.getArtifact(orgId, artifactId, revisionId ?? undefined);
      setArtifact(res.artifact);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to load revision");
    }
  }

  async function createRevision(e: React.FormEvent) {
    e.preventDefault();
    if (!orgId || !artifactId || !draftContent.trim()) return;
    setSaving(true);
    try {
      const res = await api.createArtifactRevision(orgId, artifactId, {
        content: draftContent,
        note: draftNote.trim() || undefined,
      });
      setArtifact(res.artifact);
      setViewRevisionId(null);
      setShowForm(false);
      setDraftNote("");
      toast.success("Revision created");
      await loadRevisions();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to create revision");
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <p className="px-4 py-6 text-sm text-text-muted" role="status">
        Loading artifact…
      </p>
    );
  }
  if (error || !artifact) {
    return (
      <div className="flex items-center gap-3 px-4 py-6 text-sm text-error" role="alert">
        <span>{error ?? "Artifact not found."}</span>
        <Button variant="outline" size="sm" onClick={loadLatest}>
          Retry
        </Button>
      </div>
    );
  }

  const viewingHistorical = viewRevisionId !== null && viewRevisionId !== artifact.revision_id;

  return (
    <div className="mx-auto max-w-4xl px-4 py-6">
      <button
        type="button"
        className="mb-3 text-xs text-text-muted hover:text-text hover:underline"
        onClick={() => router.push(`/app/${orgId}/artifacts`)}
      >
        ← Back to artifacts
      </button>

      <header className="mb-4">
        <h1 className="text-2xl font-bold text-text">{artifact.title}</h1>
        <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-sm text-text-secondary">
          <span>Kind: {artifact.kind}</span>
          {artifact.mime_type && <span>Type: {artifact.mime_type}</span>}
          {artifact.project_id && <span>Project: {artifact.project_id}</span>}
          <span>
            Revision:{" "}
            {artifact.revision_number != null ? `#${artifact.revision_number}` : artifact.revision_id ?? "—"}
          </span>
        </div>
      </header>

      <div className="grid gap-6 md:grid-cols-[1fr_16rem]">
        {/* Content */}
        <section className="overflow-hidden rounded-lg border border-border bg-surface">
          <div className="flex items-center justify-between border-b border-border bg-surface-alt px-3 py-2">
            <span className="text-sm font-medium text-text">
              {viewingHistorical ? "Historical revision" : "Current content"}
            </span>
            {viewingHistorical && (
              <Button variant="outline" size="sm" onClick={() => viewRevision(null)}>
                Back to latest
              </Button>
            )}
          </div>
          {showForm ? (
            <form className="space-y-3 p-3" onSubmit={createRevision}>
              <Textarea
                value={draftContent}
                onChange={(e) => setDraftContent(e.target.value)}
                rows={14}
                aria-label="New revision content"
              />
              <Input
                value={draftNote}
                onChange={(e) => setDraftNote(e.target.value)}
                placeholder="Revision note (optional)"
              />
              <div className="flex justify-end gap-2">
                <Button
                  variant="outline"
                  type="button"
                  onClick={() => {
                    setShowForm(false);
                    setDraftContent(artifact.content ?? "");
                    setDraftNote("");
                  }}
                >
                  Cancel
                </Button>
                <Button type="submit" disabled={saving || !draftContent.trim()}>
                  {saving ? "Saving…" : "Save revision"}
                </Button>
              </div>
            </form>
          ) : (
            <pre className="max-h-[32rem] overflow-auto whitespace-pre-wrap break-words p-3 text-sm text-text">
              {artifact.content ?? "(no content)"}
            </pre>
          )}
        </section>

        {/* Revision history */}
        <aside className="overflow-hidden rounded-lg border border-border bg-surface">
          <div className="flex items-center justify-between border-b border-border bg-surface-alt px-3 py-2">
            <span className="text-sm font-medium text-text">Revisions</span>
            {!showForm && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  setDraftContent(artifact.content ?? "");
                  setDraftNote("");
                  setShowForm(true);
                }}
              >
                + New
              </Button>
            )}
          </div>
          <ul className="divide-y divide-border">
            {revisions.length === 0 && (
              <li className="px-3 py-3 text-sm text-text-muted">No revisions recorded.</li>
            )}
            {revisions.map((rev) => {
              const active = artifact.revision_id === rev.id;
              return (
                <li key={rev.id}>
                  <button
                    type="button"
                    className={`flex w-full flex-col gap-0.5 px-3 py-2 text-left text-sm hover:bg-surface-alt ${
                      viewRevisionId === rev.id ? "bg-surface-alt" : ""
                    }`}
                    onClick={() => viewRevision(rev.id)}
                  >
                    <span className="font-medium text-text">
                      #{rev.revision_number}
                      {active && <span className="ml-2 text-xs text-text-muted">(current)</span>}
                    </span>
                    {rev.note && <span className="text-xs text-text-secondary">{rev.note}</span>}
                    {rev.created_at && (
                      <span className="text-xs text-text-muted">
                        {new Date(rev.created_at).toLocaleString()}
                      </span>
                    )}
                  </button>
                </li>
              );
            })}
          </ul>
        </aside>
      </div>
    </div>
  );
}
