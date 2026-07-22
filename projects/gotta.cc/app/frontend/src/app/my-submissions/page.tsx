"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { NavBar } from "../navbar";
import { Footer } from "@/components/footer";
import { api, type DirectorySubmission } from "@/lib/api";
import { isAuthed } from "@/lib/session";

const STATUS_BADGE: Record<
  DirectorySubmission["status"],
  { className: string; label: string }
> = {
  pending: { className: "bg-sunken text-ink-secondary", label: "Pending" },
  in_review: { className: "bg-olive-light text-olive", label: "In review" },
  approved: { className: "bg-olive-light text-olive", label: "Approved" },
  published: { className: "bg-coral text-white", label: "Published" },
  rejected: { className: "bg-sunken text-ink-tertiary", label: "Rejected" },
};

function StatusBadge({ status }: { status: DirectorySubmission["status"] }) {
  const badge = STATUS_BADGE[status];
  return (
    <span
      className={`shrink-0 rounded-lg px-3 py-1 font-ui text-xs font-semibold ${badge.className}`}
    >
      {badge.label}
    </span>
  );
}

export default function MySubmissionsPage() {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [submissions, setSubmissions] = useState<DirectorySubmission[] | null>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    if (!isAuthed()) {
      router.replace("/login?next=/my-submissions");
      return;
    }
    setReady(true);
    api
      .mySubmissions()
      .then((r) => setSubmissions(r.submissions))
      .catch(() => setError(true));
  }, [router]);

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
        <div className="mx-auto max-w-2xl">
          <div className="flex items-end justify-between gap-4">
            <div>
              <p className="mb-6 font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
                My submissions
              </p>
              <h1
                className="font-display text-3xl font-semibold tracking-tight text-ink"
                style={{ fontVariationSettings: "'WONK' 1" }}
              >
                Your submitted sites
              </h1>
            </div>
            <Link
              href="/submit"
              className="shrink-0 rounded-xl bg-coral px-5 py-2 font-ui text-sm font-semibold text-white transition-all duration-150 hover:-translate-y-0.5 hover:bg-coral-hover"
            >
              Submit a site
            </Link>
          </div>

          <div className="mt-8">
            {error ? (
              <p className="font-body text-sm text-ink-secondary">
                Couldn&apos;t load your submissions right now. Try again shortly.
              </p>
            ) : submissions === null ? (
              <div className="flex flex-col gap-4">
                {Array.from({ length: 3 }).map((_, i) => (
                  <div
                    key={i}
                    className="h-24 animate-pulse rounded-2xl bg-surface shadow-[0_2px_8px_rgba(0,0,0,0.04)]"
                  />
                ))}
              </div>
            ) : submissions.length === 0 ? (
              <div className="rounded-2xl bg-surface p-8 text-center shadow-[0_2px_8px_rgba(0,0,0,0.06)]">
                <p className="font-body text-base text-ink-secondary">
                  You haven&apos;t submitted any sites yet.
                </p>
                <Link
                  href="/submit"
                  className="mt-4 inline-block font-ui text-sm font-semibold text-olive hover:text-olive-hover"
                >
                  Submit your first site &rarr;
                </Link>
              </div>
            ) : (
              <ul className="flex flex-col gap-4">
                {submissions.map((sub) => (
                  <li
                    key={sub.id}
                    className="rounded-2xl bg-surface p-6 shadow-[0_2px_8px_rgba(0,0,0,0.06)]"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <p className="font-mono text-sm text-ink-tertiary">{sub.domain}</p>
                        <h2
                          className="mt-1 font-display text-xl font-medium text-ink"
                          style={{ fontVariationSettings: "'WONK' 1" }}
                        >
                          {sub.published_site_slug ? (
                            <Link
                              href={`/site/${sub.published_site_slug}`}
                              className="hover:text-coral"
                            >
                              {sub.name}
                            </Link>
                          ) : (
                            sub.name
                          )}
                        </h2>
                      </div>
                      <StatusBadge status={sub.status} />
                    </div>

                    <p className="mt-3 line-clamp-2 font-body text-sm leading-relaxed text-ink-secondary">
                      {sub.summary}
                    </p>

                    {sub.reviewer_notes && (
                      <p className="mt-3 rounded-lg bg-sunken px-3 py-2 font-body text-sm text-ink-secondary">
                        <span className="font-ui text-xs font-bold uppercase tracking-[0.06em] text-ink-tertiary">
                          Editor&apos;s note:{" "}
                        </span>
                        {sub.reviewer_notes}
                      </p>
                    )}

                    <div className="mt-4 flex flex-wrap items-center gap-x-4 gap-y-1 font-ui text-xs text-ink-tertiary">
                      <span>{sub.proposed_category_slug}</span>
                      {sub.tags.length > 0 && <span>{sub.tags.join(", ")}</span>}
                      <span>
                        Submitted {new Date(sub.inserted_at).toLocaleDateString()}
                      </span>
                    </div>
                  </li>
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
