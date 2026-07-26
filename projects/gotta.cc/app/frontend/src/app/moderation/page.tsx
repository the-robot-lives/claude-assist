"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { NavBar } from "../navbar";
import { Footer } from "@/components/footer";
import {
  api,
  type DirectoryCategory,
  type DirectorySubmission,
  type SubmissionScores,
} from "@/lib/api";
import { isAuthed } from "@/lib/session";

// Rubric weights — single source of truth mirrors app/docs/scoring-rubric.md.
const DIMENSIONS: { key: keyof SubmissionScores; label: string; weight: number }[] = [
  { key: "originality", label: "Originality", weight: 30 },
  { key: "human_authorship", label: "Human Authorship", weight: 25 },
  { key: "depth", label: "Depth", weight: 20 },
  { key: "freshness", label: "Freshness", weight: 15 },
  { key: "design_quality", label: "Design Quality", weight: 10 },
];

const inputClass =
  "w-full rounded-xl border-2 border-rule bg-surface px-4 py-3 font-ui text-base text-ink placeholder:text-ink-tertiary transition-all duration-200 focus:border-coral focus:shadow-[0_0_0_4px_rgba(232,112,74,0.1)] focus:outline-none disabled:opacity-50";
const labelClass =
  "font-ui text-xs font-bold uppercase tracking-[0.06em] text-ink-tertiary";

function clampScore(n: number): number {
  if (Number.isNaN(n)) return 0;
  return Math.max(0, Math.min(100, Math.round(n)));
}

function ModerationCard({
  submission,
  categories,
  onResolved,
}: {
  submission: DirectorySubmission;
  categories: DirectoryCategory[];
  onResolved: (id: string) => void;
}) {
  const [scores, setScores] = useState<SubmissionScores>({
    originality: 70,
    human_authorship: 70,
    depth: 70,
    freshness: 70,
    design_quality: 70,
  });
  const [categorySlug, setCategorySlug] = useState(submission.proposed_category_slug || "");
  const [summary, setSummary] = useState(submission.summary || "");
  const [featured, setFeatured] = useState(false);
  const [reason, setReason] = useState("");
  const [showReject, setShowReject] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  const overall = Math.round(
    DIMENSIONS.reduce((sum, d) => sum + scores[d.key] * (d.weight / 100), 0),
  );

  async function approve() {
    if (!categorySlug) {
      setError("Pick a category before approving.");
      return;
    }
    setError("");
    setBusy(true);
    try {
      await api.approveSubmission(submission.id, {
        scores,
        category_slug: categorySlug,
        summary: summary.trim(),
        featured,
      });
      onResolved(submission.id);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Approve failed. Try again.");
      setBusy(false);
    }
  }

  async function reject() {
    if (!reason.trim()) {
      setError("Add a reason for the rejection.");
      return;
    }
    setError("");
    setBusy(true);
    try {
      await api.rejectSubmission(submission.id, reason.trim());
      onResolved(submission.id);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Reject failed. Try again.");
      setBusy(false);
    }
  }

  return (
    <li className="rounded-2xl bg-surface p-6 shadow-[0_2px_8px_rgba(0,0,0,0.06)]">
      {/* Header */}
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="font-mono text-sm text-ink-tertiary">{submission.domain}</p>
          <h2
            className="mt-1 font-display text-xl font-medium text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            {submission.name}
          </h2>
          {submission.submitter_email ? (
            <p className="mt-1 font-ui text-xs text-ink-tertiary">
              from {submission.submitter_email}
            </p>
          ) : (
            <p className="mt-1 font-ui text-xs text-ink-tertiary">
              anonymous
              {submission.contact_email ? ` · ${submission.contact_email}` : ""}
            </p>
          )}
        </div>
        <a
          href={submission.url}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex shrink-0 items-center gap-1.5 rounded-xl bg-coral px-4 py-2 font-ui text-sm font-semibold text-white transition-all duration-150 hover:-translate-y-0.5 hover:bg-coral-hover"
        >
          Visit
          <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth={2} aria-hidden="true">
            <path d="M7 17 17 7M9 7h8v8" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </a>
      </div>

      {submission.tags.length > 0 && (
        <div className="mt-4 flex flex-wrap gap-2">
          {submission.tags.map((tag) => (
            <span
              key={tag}
              className="rounded-lg border border-rule px-3 py-1 font-ui text-xs text-ink-secondary"
            >
              {tag}
            </span>
          ))}
        </div>
      )}

      {/* Scores */}
      <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {DIMENSIONS.map((d) => (
          <div key={d.key} className="flex flex-col gap-1.5">
            <label htmlFor={`${submission.id}-${d.key}`} className={labelClass}>
              {d.label}{" "}
              <span className="font-normal normal-case text-ink-tertiary">· {d.weight}%</span>
            </label>
            <input
              id={`${submission.id}-${d.key}`}
              type="number"
              min={0}
              max={100}
              value={scores[d.key]}
              onChange={(e) =>
                setScores((s) => ({ ...s, [d.key]: clampScore(Number(e.target.value)) }))
              }
              disabled={busy}
              className={inputClass}
            />
          </div>
        ))}
        <div className="flex flex-col justify-end gap-1.5">
          <span className={labelClass}>Overall (computed)</span>
          <div className="rounded-xl bg-sunken px-4 py-3 font-mono text-base font-bold text-ink">
            {overall}
          </div>
        </div>
      </div>

      {/* Category + summary + featured */}
      <div className="mt-5 grid gap-5 sm:grid-cols-2">
        <div className="flex flex-col gap-1.5">
          <label htmlFor={`${submission.id}-cat`} className={labelClass}>
            Category
          </label>
          <select
            id={`${submission.id}-cat`}
            value={categorySlug}
            onChange={(e) => setCategorySlug(e.target.value)}
            disabled={busy}
            className={inputClass}
          >
            <option value="" disabled>
              Choose a category…
            </option>
            {categories.map((cat) => (
              <option key={cat.slug} value={cat.slug}>
                {cat.name}
              </option>
            ))}
          </select>
        </div>
        <label className="flex items-end gap-2 pb-3 font-ui text-sm text-ink-secondary">
          <input
            type="checkbox"
            checked={featured}
            onChange={(e) => setFeatured(e.target.checked)}
            disabled={busy}
            className="h-4 w-4 accent-coral"
          />
          Feature this site (Editor&apos;s Pick)
        </label>
      </div>

      <div className="mt-5 flex flex-col gap-1.5">
        <label htmlFor={`${submission.id}-summary`} className={labelClass}>
          Summary (as listed)
        </label>
        <textarea
          id={`${submission.id}-summary`}
          value={summary}
          onChange={(e) => setSummary(e.target.value)}
          rows={3}
          disabled={busy}
          className={`${inputClass} resize-y`}
        />
      </div>

      {error && (
        <p className="mt-4 font-ui text-sm text-error" role="alert">
          {error}
        </p>
      )}

      {/* Actions */}
      <div className="mt-5 flex flex-wrap items-center gap-4 border-t border-rule pt-5">
        <button
          type="button"
          onClick={approve}
          disabled={busy}
          className="rounded-xl bg-olive px-5 py-2.5 font-ui text-sm font-semibold text-white transition-all duration-150 hover:-translate-y-0.5 hover:bg-olive-hover disabled:opacity-50"
        >
          {busy ? "Working…" : "Approve & publish"}
        </button>
        <button
          type="button"
          onClick={() => setShowReject((v) => !v)}
          disabled={busy}
          className="font-ui text-sm font-semibold text-ink-secondary hover:text-error"
        >
          Reject…
        </button>
      </div>

      {showReject && (
        <div className="mt-4 flex flex-col gap-2">
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="Reason for rejection (shown to the submitter)"
            rows={2}
            disabled={busy}
            className={`${inputClass} resize-y`}
          />
          <button
            type="button"
            onClick={reject}
            disabled={busy}
            className="self-start rounded-xl border-2 border-rule bg-surface px-5 py-2 font-ui text-sm font-semibold text-error transition-colors duration-150 hover:border-error disabled:opacity-50"
          >
            Confirm rejection
          </button>
        </div>
      )}
    </li>
  );
}

export default function ModerationPage() {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [submissions, setSubmissions] = useState<DirectorySubmission[] | null>(null);
  const [categories, setCategories] = useState<DirectoryCategory[]>([]);
  const [loadError, setLoadError] = useState<"forbidden" | "generic" | null>(null);

  useEffect(() => {
    if (!isAuthed()) {
      router.replace("/login?next=/moderation");
      return;
    }
    setReady(true);

    api
      .directoryCategories()
      .then((r) => setCategories(r.categories))
      .catch(() => setCategories([]));

    api
      .modSubmissions("pending")
      .then((r) => setSubmissions(r.submissions))
      .catch((err) => {
        // RequireAdmin returns 403 {"error":"Admin access required"} for a
        // non-admin; request<T> throws that string as the Error message. Match
        // on it; treat anything else (network, 500, etc.) as a generic failure.
        const msg = err instanceof Error ? err.message.toLowerCase() : "";
        setLoadError(msg.includes("admin access required") ? "forbidden" : "generic");
      });
  }, [router]);

  function handleResolved(id: string) {
    setSubmissions((prev) => (prev ? prev.filter((s) => s.id !== id) : prev));
  }

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-cream">
        <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
          Loading…
        </p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-cream">
      <NavBar />

      <section className="px-6 py-12">
        <div className="mx-auto max-w-3xl">
          <p className="mb-6 font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
            Moderation
          </p>
          <h1
            className="font-display text-3xl font-semibold tracking-tight text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            Submission review queue
          </h1>
          <p className="mt-3 max-w-[60ch] font-body text-base leading-relaxed text-ink-secondary">
            Score each site 0–100 on the five rubric dimensions — Originality (30%),
            Human Authorship (25%), Depth (20%), Freshness (15%), Design (10%). The
            overall is the weighted sum. See{" "}
            <span className="font-mono text-sm text-ink-tertiary">app/docs/scoring-rubric.md</span>{" "}
            for the banding guide.
          </p>

          <div className="mt-8">
            {loadError === "forbidden" ? (
              <div className="rounded-2xl bg-surface p-8 text-center shadow-[0_2px_8px_rgba(0,0,0,0.06)]">
                <p
                  className="font-display text-xl font-semibold text-ink"
                  style={{ fontVariationSettings: "'WONK' 1" }}
                >
                  Not authorized
                </p>
                <p className="mt-2 font-body text-sm text-ink-secondary">
                  The moderation queue is admin-only. Your account doesn&apos;t have
                  moderator access.
                </p>
                <Link
                  href="/"
                  className="mt-4 inline-block font-ui text-sm font-semibold text-olive hover:text-olive-hover"
                >
                  &larr; Back to the directory
                </Link>
              </div>
            ) : loadError === "generic" ? (
              <p className="font-body text-sm text-ink-secondary">
                Couldn&apos;t load the moderation queue right now. Try again shortly.
              </p>
            ) : submissions === null ? (
              <div className="flex flex-col gap-4">
                {Array.from({ length: 2 }).map((_, i) => (
                  <div
                    key={i}
                    className="h-64 animate-pulse rounded-2xl bg-surface shadow-[0_2px_8px_rgba(0,0,0,0.04)]"
                  />
                ))}
              </div>
            ) : submissions.length === 0 ? (
              <div className="rounded-2xl bg-surface p-8 text-center shadow-[0_2px_8px_rgba(0,0,0,0.06)]">
                <p className="font-body text-base text-ink-secondary">
                  The queue is empty — nothing pending review.
                </p>
              </div>
            ) : (
              <ul className="flex flex-col gap-6">
                {submissions.map((sub) => (
                  <ModerationCard
                    key={sub.id}
                    submission={sub}
                    categories={categories}
                    onResolved={handleResolved}
                  />
                ))}
              </ul>
            )}
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}
