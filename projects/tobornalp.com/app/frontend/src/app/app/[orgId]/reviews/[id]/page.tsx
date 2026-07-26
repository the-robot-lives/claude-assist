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
import {
  Btn,
  Input,
  Select,
  Textarea,
  Dialog,
  FieldLabel,
  Panel,
  PanelHeader,
  Key,
  StatusSeg,
  type StatusTone,
} from "@/components/ui";
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

// review status (open | in_progress | completed) and verdict (approved |
// changes_requested | rejected) both speak through the [OK]/[WARN]/[ERR]/[INFO]
// vocabulary rather than a bespoke colour scale.
function statusTone(status?: string): StatusTone {
  if (status === "completed") return "ok";
  if (status === "in_progress") return "warn";
  return "info";
}

function verdictTone(verdict?: string | null): StatusTone | null {
  if (verdict === "approved") return "ok";
  if (verdict === "changes_requested") return "warn";
  if (verdict === "rejected") return "err";
  return null;
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
      <p className="px-[18px] py-6 text-[12px] text-faint" role="status">
        loading review…
      </p>
    );
  }
  if (error || !review) {
    return (
      <div className="flex items-center gap-3 px-[18px] py-6 text-[12px] text-err" role="alert">
        <span>[ERR] {error ?? "Review not found."}</span>
        <Btn onClick={load}>retry</Btn>
      </div>
    );
  }

  const isCompleted = review.status === "completed";
  const vTone = verdictTone(review.verdict);

  return (
    <div className="app-content max-w-3xl">
      <button
        type="button"
        className="justify-self-start text-[11px] text-faint hover:text-acc"
        onClick={() => router.push(`/app/${orgId}/reviews`)}
      >
        ← back to reviews
      </button>

      <header className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-[15px] font-bold text-ink">{review.title || "untitled review"}</h1>
          <p className="mt-1 text-[11.5px] text-mut">
            reviewer: <span className="text-ink">{review.reviewer_persona || "—"}</span>
          </p>
        </div>
        {!isCompleted && (
          <Btn variant="primary" onClick={() => setShowComplete(true)}>
            complete review
          </Btn>
        )}
      </header>

      <Panel>
        <PanelHeader title="review" />
        <dl className="grid gap-x-6 gap-y-3 p-4 sm:grid-cols-2">
          <Field label="status" value={<StatusSeg tone={statusTone(review.status)}>{review.status?.replace(/_/g, " ")}</StatusSeg>} />
          <Field
            label="verdict"
            value={
              vTone ? (
                <StatusSeg tone={vTone}>{review.verdict?.replace(/_/g, " ")}</StatusSeg>
              ) : (
                <span className="text-faint">—</span>
              )
            }
          />
          <Field label="artifact" value={<Key>{review.artifact_id ?? "—"}</Key>} />
          <Field label="revision" value={<Key>{review.revision_id ?? "—"}</Key>} />
          {review.inserted_at && (
            <Field label="created" value={new Date(review.inserted_at).toLocaleString()} />
          )}
          {review.updated_at && (
            <Field label="updated" value={new Date(review.updated_at).toLocaleString()} />
          )}
        </dl>
      </Panel>

      <Panel>
        <PanelHeader title="summary" />
        <p className="whitespace-pre-wrap p-4 font-prose text-[13px] leading-relaxed text-ink">
          {review.summary || "(no summary)"}
        </p>
      </Panel>

      {/* Overlay comments (positioned notes on the artifact under review). */}
      <Panel>
        <PanelHeader title="overlay comments" sub={overlays.length} />
        {overlays.length === 0 ? (
          <p className="p-4 text-[12px] text-faint">no overlay comments.</p>
        ) : (
          <div className="divide-y divide-line">
            {overlays.map((o) => (
              <div key={o.id} className="px-4 py-2.5 text-[11.5px] hover:bg-sel">
                <div className="mb-0.5 text-faint">
                  <span className="text-info">{o.persona ?? "unknown"}</span>
                  {o.x != null && o.y != null ? ` · @ (${o.x}, ${o.y})` : ""}
                </div>
                <div className="text-ink">{o.comment || "(no comment)"}</div>
              </div>
            ))}
          </div>
        )}
      </Panel>

      {/* Thread comments (best-effort — api.ts types these as unknown[]). */}
      <Panel>
        <PanelHeader title="comments" sub={comments.length} />
        {comments.length === 0 ? (
          <p className="p-4 text-[12px] text-faint">no comments.</p>
        ) : (
          <div className="divide-y divide-line">
            {comments.map((c, i) => (
              <div key={c.id ?? i} className="px-4 py-2.5 text-[11.5px] hover:bg-sel">
                <div className="mb-0.5 flex items-center gap-2 text-faint">
                  <span className="text-info">{c.author ?? "unknown"}</span>
                  {c.inserted_at && <span>{new Date(c.inserted_at).toLocaleString()}</span>}
                </div>
                <div className="whitespace-pre-wrap text-ink">{commentText(c) || "(empty)"}</div>
              </div>
            ))}
          </div>
        )}
      </Panel>

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
      <dt className="text-[10px] uppercase tracking-[0.08em] text-faint">{label}</dt>
      <dd className="mt-0.5 text-[12.5px] text-ink">{value}</dd>
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
      title="complete review"
      footer={
        <>
          <Btn onClick={onClose}>cancel</Btn>
          <Btn variant="primary" type="submit" form="complete-review-form" disabled={saving}>
            {saving ? "completing…" : "complete review"}
          </Btn>
        </>
      }
    >
      <form id="complete-review-form" onSubmit={submit} className="space-y-3">
        <p className="text-[12px] text-mut">
          recording the final verdict freezes this review (status → completed).
        </p>
        <FieldLabel label="verdict">
          <Select value={verdict} onChange={(e) => setVerdict(e.target.value)} autoFocus>
            {REVIEW_VERDICT_OPTIONS.map((v) => (
              <option key={v.value} value={v.value}>
                {v.label}
              </option>
            ))}
          </Select>
        </FieldLabel>
        <FieldLabel label="summary">
          <Textarea
            value={summary}
            onChange={(e) => setSummary(e.target.value)}
            placeholder="optional closing summary"
            rows={4}
          />
        </FieldLabel>
        {error && <p className="text-[12px] text-err">[ERR] {error}</p>}
      </form>
    </Dialog>
  );
}
