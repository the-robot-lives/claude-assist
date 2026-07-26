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
import { Btn, Input, Textarea, Panel, PanelHeader, Chip } from "@/components/ui";

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
      setError(err instanceof Error ? err.message : "failed to load artifact");
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
      toast.error(err instanceof Error ? err.message : "failed to load revisions");
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
      toast.error(err instanceof Error ? err.message : "failed to load revision");
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
      toast.success("revision created");
      await loadRevisions();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "failed to create revision");
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <p className="px-4 py-6 text-[12px] text-faint" role="status">
        loading artifact…
      </p>
    );
  }
  if (error || !artifact) {
    return (
      <div className="flex items-center gap-3 px-4 py-6 text-[12px] text-err" role="alert">
        <span>[ERR] {error ?? "artifact not found."}</span>
        <Btn variant="default" onClick={loadLatest}>
          retry
        </Btn>
      </div>
    );
  }

  const viewingHistorical = viewRevisionId !== null && viewRevisionId !== artifact.revision_id;

  return (
    <div className="app-content">
      <button
        type="button"
        className="w-fit text-[11px] text-faint hover:text-ink hover:underline"
        onClick={() => router.push(`/app/${orgId}/artifacts`)}
      >
        ← back to artifacts
      </button>

      <header>
        <h1 className="text-[19px] font-bold leading-snug text-ink">{artifact.title}</h1>
        <div className="mt-2 flex flex-wrap items-center gap-1.5">
          <Chip variant="scope">{artifact.kind}</Chip>
          {artifact.mime_type && <Chip variant="scope">{artifact.mime_type}</Chip>}
          {artifact.project_id && <Chip variant="scope">project {artifact.project_id}</Chip>}
          <Chip>
            rev {artifact.revision_number != null ? `#${artifact.revision_number}` : artifact.revision_id ?? "—"}
          </Chip>
        </div>
      </header>

      <div className="grid gap-3.5 md:grid-cols-[1fr_16rem] md:items-start">
        {/* Content */}
        <Panel>
          <PanelHeader
            title={viewingHistorical ? "historical revision" : "current content"}
            right={
              viewingHistorical && (
                <Btn variant="default" onClick={() => viewRevision(null)}>
                  back to latest
                </Btn>
              )
            }
          />
          {showForm ? (
            <form className="flex flex-col gap-3 p-4" onSubmit={createRevision}>
              <Textarea
                value={draftContent}
                onChange={(e) => setDraftContent(e.target.value)}
                rows={14}
                aria-label="new revision content"
                className="rounded-card border-line2 bg-ground font-mono"
              />
              <Input
                value={draftNote}
                onChange={(e) => setDraftNote(e.target.value)}
                placeholder="revision note (optional)"
                className="rounded-card border-line2 bg-ground"
              />
              <div className="flex justify-end gap-2">
                <Btn
                  variant="default"
                  type="button"
                  onClick={() => {
                    setShowForm(false);
                    setDraftContent(artifact.content ?? "");
                    setDraftNote("");
                  }}
                >
                  cancel
                </Btn>
                <Btn variant="primary" type="submit" disabled={saving || !draftContent.trim()}>
                  {saving ? "saving…" : "save revision"}
                </Btn>
              </div>
            </form>
          ) : (
            <pre className="max-h-[32rem] overflow-auto whitespace-pre-wrap break-words p-4 text-[12.5px] text-ink">
              {artifact.content ?? "(no content)"}
            </pre>
          )}
        </Panel>

        {/* Revision history */}
        <Panel>
          <PanelHeader
            title="revisions"
            right={
              !showForm && (
                <Btn
                  variant="default"
                  onClick={() => {
                    setDraftContent(artifact.content ?? "");
                    setDraftNote("");
                    setShowForm(true);
                  }}
                >
                  + new
                </Btn>
              )
            }
          />
          <ul className="divide-y divide-line">
            {revisions.length === 0 && (
              <li className="px-4 py-3 text-[12px] text-faint">no revisions recorded.</li>
            )}
            {revisions.map((rev) => {
              const active = artifact.revision_id === rev.id;
              return (
                <li key={rev.id}>
                  <button
                    type="button"
                    className={`flex w-full flex-col gap-0.5 px-4 py-2 text-left text-[12px] hover:bg-sel ${
                      viewRevisionId === rev.id ? "bg-sel" : ""
                    }`}
                    onClick={() => viewRevision(rev.id)}
                  >
                    <span className="font-bold text-ink">
                      #{rev.revision_number}
                      {active && <span className="ml-2 text-[10.5px] font-normal text-faint">(current)</span>}
                    </span>
                    {rev.note && <span className="text-[11px] text-mut">{rev.note}</span>}
                    {rev.created_at && (
                      <span className="text-[10.5px] text-faint">
                        {new Date(rev.created_at).toLocaleString()}
                      </span>
                    )}
                  </button>
                </li>
              );
            })}
          </ul>
        </Panel>
      </div>
    </div>
  );
}
