"use client";

// Review detail — custom (not ConsoleDetailPage) because the complete flow
// (verdict + summary entry, freezes the review) is domain-specific. Shows the
// review's status/verdict/summary/reviewer/target, its overlay comments, and a
// Complete action (offered while the review is not yet completed).
//
// Note: getReview returns `comments: unknown[]` (untyped in api.ts) — rendered
// best-effort. overlays are typed (ReviewOverlay).
import { useCallback, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { api, type Review, type ReviewOverlay } from "@/lib/api";
import { useOrg } from "@/context/org";
import { Button, Input, Select, Textarea, Dialog } from "@/components/ui";
import { REVIEW_VERDICT_OPTIONS } from "@/lib/console/descriptors/reviews";

// Best-effort shape for the untyped comments[] payload from getReview.
type ReviewComment = {
  id?: string;
  author?: string;
  content?: string;
  body?: string;
  inserted_at?: string;
};

function commentText(c: ReviewComment): string {
  return c.content ?? c.body ?? "";
}

export default function ReviewDetailPage() {
  const params = useParams<{ orgId: string; id: string }>();
  const { currentOrg } = useOrg();
  const router = useRouter();
  const orgId = currentOrg?.id || params.orgId;
  const reviewId = params.id;

  const [review, setReview] = useState<Review | null>(null);
  const [comments, setComments] = useState<ReviewComment[]>([]);
  const [overlays, setOverlays] = useState<ReviewOverlay[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showComplete, setShowComplete] = useState(false);

  const load = useCallback(async () => {
    if (!orgId || !reviewId) return;
    setLoading(true);
    setError(null);
    try {
      const res = await api.getReview(orgId, reviewId);
      setReview(res.review);
      setComments((res.comments as ReviewComment[] | undefined) ?? []);
      setOverlays(res.overlays ?? []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load review");
    } finally {
      setLoading(false);
    }
  }, [orgId, reviewId]);

  useEffect(() => {
    load();
  }, [load]);

  if (loading) {
    return (
      <p className="px-4 py-6 text-sm text-text-muted" role="status">
        Loading review…
      </p>
    );
  }
  if (error || !review) {
    return (
      <div className="flex items-center gap-3 px-4 py-6 text-sm text-error" role="alert">
        <span>{error ?? "Review not found."}</span>
        <Button variant="outline" size="sm" onClick={load}>
          Retry
        </Button>
      </div>
    );
  }

  const isCompleted = review.status === "completed";

  return (
    <div className="mx-auto max-w-3xl px-4 py-6">
      <button
        type="button"
        className="mb-3 text-xs text-text-muted hover:text-text hover:underline"
        onClick={() => router.push(`/app/${orgId}/reviews`)}
      >
        ← Back to reviews
      </button>

      <header className="mb-4 flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">{review.title || "Untitled review"}</h1>
          <p className="mt-1 text-sm text-text-secondary">
            Reviewer: {review.reviewer_persona || "—"}
          </p>
        </div>
        {!isCompleted && (
          <Button onClick={() => setShowComplete(true)}>Complete review</Button>
        )}
      </header>

      <dl className="mb-6 grid gap-4 rounded-lg border border-border bg-surface p-4 sm:grid-cols-2">
        <Field label="Status" value={<span data-status={review.status}>{review.status}</span>} />
        <Field label="Verdict" value={review.verdict ?? "—"} />
        <Field label="Artifact" value={review.artifact_id ?? "—"} />
        <Field label="Revision" value={review.revision_id ?? "—"} />
        {review.inserted_at && (
          <Field label="Created" value={new Date(review.inserted_at).toLocaleString()} />
        )}
        {review.updated_at && (
          <Field label="Updated" value={new Date(review.updated_at).toLocaleString()} />
        )}
      </dl>

      <section className="mb-6 rounded-lg border border-border bg-surface p-4">
        <h2 className="mb-2 text-sm font-semibold text-text">Summary</h2>
        <p className="whitespace-pre-wrap text-sm text-text">
          {review.summary || "(no summary)"}
        </p>
      </section>

      {/* Overlay comments (positioned notes on the artifact under review). */}
      <section className="mb-6 rounded-lg border border-border bg-surface p-4">
        <h2 className="mb-2 text-sm font-semibold text-text">
          Overlay comments ({overlays.length})
        </h2>
        {overlays.length === 0 ? (
          <p className="text-sm text-text-muted">No overlay comments.</p>
        ) : (
          <ul className="space-y-2">
            {overlays.map((o) => (
              <li key={o.id} className="rounded border border-border bg-surface-alt p-2 text-sm">
                <div className="mb-0.5 text-xs text-text-muted">
                  {o.persona ?? "unknown"}
                  {o.x != null && o.y != null ? ` · @ (${o.x}, ${o.y})` : ""}
                </div>
                <div className="text-text">{o.comment || "(no comment)"}</div>
              </li>
            ))}
          </ul>
        )}
      </section>

      {/* Thread comments (best-effort — api.ts types these as unknown[]). */}
      <section className="rounded-lg border border-border bg-surface p-4">
        <h2 className="mb-2 text-sm font-semibold text-text">Comments ({comments.length})</h2>
        {comments.length === 0 ? (
          <p className="text-sm text-text-muted">No comments.</p>
        ) : (
          <ul className="space-y-2">
            {comments.map((c, i) => (
              <li key={c.id ?? i} className="rounded border border-border bg-surface-alt p-2 text-sm">
                <div className="mb-0.5 text-xs text-text-muted">{c.author ?? "unknown"}</div>
                <div className="whitespace-pre-wrap text-text">{commentText(c) || "(empty)"}</div>
              </li>
            ))}
          </ul>
        )}
      </section>

      {showComplete && orgId && review && (
        <CompleteReviewDialog
          orgId={orgId}
          review={review}
          onClose={() => setShowComplete(false)}
          onSaved={() => {
            setShowComplete(false);
            load();
          }}
        />
      )}
    </div>
  );
}

function Field({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div>
      <dt className="text-xs uppercase tracking-wide text-text-muted">{label}</dt>
      <dd className="mt-0.5 text-sm text-text">{value}</dd>
    </div>
  );
}

function CompleteReviewDialog({
  orgId,
  review,
  onClose,
  onSaved,
}: {
  orgId: string;
  review: Review;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [verdict, setVerdict] = useState(review.verdict || "approved");
  const [summary, setSummary] = useState(review.summary || "");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      await api.completeReview(orgId, review.id, {
        verdict,
        summary: summary.trim() || undefined,
      });
      toast.success("Review completed");
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
      title="Complete review"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" form="complete-review-form" disabled={saving}>
            {saving ? "Completing…" : "Complete review"}
          </Button>
        </>
      }
    >
      <form id="complete-review-form" onSubmit={submit} className="space-y-3">
        <p className="text-sm text-text-secondary">
              Recording the final verdict freezes this review (status → completed).
        </p>
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Verdict</span>
          <Select value={verdict} onChange={(e) => setVerdict(e.target.value)} autoFocus>
            {REVIEW_VERDICT_OPTIONS.map((v) => (
              <option key={v.value} value={v.value}>
                {v.label}
              </option>
            ))}
          </Select>
        </label>
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Summary</span>
          <Textarea
            value={summary}
            onChange={(e) => setSummary(e.target.value)}
            placeholder="Optional closing summary"
            rows={4}
          />
        </label>
        {error && <p className="text-sm text-error">{error}</p>}
      </form>
    </Dialog>
  );
}
