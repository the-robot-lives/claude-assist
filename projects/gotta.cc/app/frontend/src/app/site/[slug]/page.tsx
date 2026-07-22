"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { NavBar } from "../../navbar";
import { Footer } from "@/components/footer";
import { SiteCard, scoreBadgeClass } from "@/components/site-card";
import { api, type DirectorySite } from "@/lib/api";

interface ScoreDim {
  key: keyof DirectorySite["scores"];
  label: string;
}

const SCORE_DIMENSIONS: ScoreDim[] = [
  { key: "originality", label: "Originality" },
  { key: "human_authorship", label: "Human Authorship" },
  { key: "depth", label: "Depth" },
  { key: "freshness", label: "Freshness" },
  { key: "design_quality", label: "Design Quality" },
];

function barColor(score: number) {
  return score >= 90
    ? "var(--score-high)"
    : score >= 70
      ? "var(--score-medium)"
      : "var(--score-low)";
}

export default function SitePage() {
  const params = useParams<{ slug: string }>();
  const slug = params.slug;

  const [site, setSite] = useState<DirectorySite | null>(null);
  const [status, setStatus] = useState<"loading" | "ok" | "notfound">("loading");
  const [more, setMore] = useState<DirectorySite[]>([]);
  const [moreLoading, setMoreLoading] = useState(true);

  useEffect(() => {
    setStatus("loading");
    api
      .directorySite(slug)
      .then((r) => {
        setSite(r.site);
        setStatus("ok");
      })
      .catch(() => setStatus("notfound"));
  }, [slug]);

  // Load "more in category" after the site resolves.
  useEffect(() => {
    if (!site) return;
    setMoreLoading(true);
    api
      .directorySites({ category: site.category.slug, sort: "top", limit: 6 })
      .then((r) => setMore(r.sites.filter((s) => s.id !== site.id).slice(0, 3)))
      .catch(() => setMore([]))
      .finally(() => setMoreLoading(false));
  }, [site]);

  if (status === "loading") {
    return (
      <div className="min-h-screen bg-cream flex items-center justify-center">
        <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
          Loading…
        </p>
      </div>
    );
  }

  if (status === "notfound" || !site) {
    return (
      <div className="min-h-screen bg-cream">
        <NavBar />
        <section className="px-6 py-20">
          <div className="mx-auto max-w-[960px] text-center">
            <h1
              className="font-display text-3xl font-semibold tracking-tight text-ink"
              style={{ fontVariationSettings: "'WONK' 1" }}
            >
              Site not found.
            </h1>
            <p className="mt-4 font-body text-base text-ink-secondary">
              This listing may have been removed or never existed.
            </p>
            <Link
              href="/"
              className="mt-6 inline-block font-ui text-sm font-semibold text-olive hover:text-olive-hover"
            >
              &larr; Back to the directory
            </Link>
          </div>
        </section>
        <Footer />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-cream">
      <NavBar />

      <article className="px-6 py-12">
        <div className="mx-auto max-w-[960px]">
          {/* Breadcrumb */}
          <Link
            href={`/category/${site.category.slug}`}
            className="font-ui text-xs font-semibold text-olive hover:text-olive-hover transition-colors duration-150"
          >
            &larr; {site.category.name}
          </Link>

          <div className="mt-6 grid items-start gap-10 lg:grid-cols-[1fr_220px]">
            {/* Main */}
            <div className="min-w-0">
              <p className="font-mono text-sm text-ink-tertiary">{site.domain}</p>
              <h1
                className="mt-2 font-display text-4xl font-semibold tracking-tight text-ink"
                style={{ fontVariationSettings: "'WONK' 1" }}
              >
                {site.name}
              </h1>

              <a
                href={site.url}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-4 inline-flex items-center gap-2 rounded-xl bg-coral px-5 py-2 font-ui text-sm font-semibold text-white transition-all duration-150 hover:-translate-y-0.5 hover:bg-coral-hover"
              >
                Visit site
                <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth={2} aria-hidden="true">
                  <path d="M7 17 17 7M9 7h8v8" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </a>

              <p className="mt-6 max-w-[65ch] font-body text-lg leading-relaxed text-ink-secondary">
                {site.summary}
              </p>

              {site.tags.length > 0 && (
                <div className="mt-6 flex flex-wrap gap-2">
                  {site.tags.map((tag) => (
                    <span
                      key={tag}
                      className="rounded-lg border border-rule px-3 py-1 font-ui text-xs text-ink-secondary"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              )}
            </div>

            {/* Score aside */}
            <aside className="flex flex-col items-center gap-4">
              <div className="flex h-24 w-24 flex-col items-center justify-center rounded-full bg-score-high text-white">
                <span
                  className="font-display text-4xl font-bold leading-none"
                  style={{ fontVariationSettings: "'WONK' 1" }}
                >
                  {site.scores.overall}
                </span>
                <span className="font-ui text-[10px] font-medium opacity-85">
                  /100
                </span>
              </div>
              {site.featured && (
                <span className="font-ui text-xs font-bold uppercase tracking-wider text-coral">
                  Editor&apos;s Pick
                </span>
              )}

              <div className="w-full rounded-2xl bg-surface p-5 shadow-[0_2px_8px_rgba(0,0,0,0.06)]">
                <p className="mb-3 font-ui text-xs font-bold uppercase tracking-[0.06em] text-ink-tertiary">
                  Score breakdown
                </p>
                <div className="flex flex-col gap-3">
                  {SCORE_DIMENSIONS.map((d) => {
                    const score = site.scores[d.key];
                    return (
                      <div key={d.key}>
                        <div className="mb-1 flex items-baseline justify-between">
                          <span className="font-ui text-xs text-ink-secondary">
                            {d.label}
                          </span>
                          <span className="font-ui text-xs font-semibold text-ink">
                            {score}
                          </span>
                        </div>
                        <div className="h-1.5 overflow-hidden rounded-full bg-sunken">
                          <div
                            className="h-full rounded-full"
                            style={{ width: `${score}%`, background: barColor(score) }}
                          />
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </aside>
          </div>
        </div>
      </article>

      {/* More in category */}
      {!moreLoading && more.length > 0 && (
        <section className="px-6 py-12">
          <div className="mx-auto max-w-[960px]">
            <p className="font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
              More in {site.category.name}
            </p>
            <div className="mt-6 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {more.map((s) => (
                <SiteCard key={s.id} site={s} />
              ))}
            </div>
          </div>
        </section>
      )}

      <Footer />
    </div>
  );
}
