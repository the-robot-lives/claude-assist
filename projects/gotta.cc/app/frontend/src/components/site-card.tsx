"use client";

import Link from "next/link";
import type { DirectorySite } from "@/lib/api";

export function scoreBadgeClass(overall: number) {
  return overall >= 90
    ? "bg-score-high"
    : overall >= 70
      ? "bg-score-medium"
      : "bg-score-low";
}

export function SiteCard({ site }: { site: DirectorySite }) {
  const score = site.scores.overall;
  return (
    <Link
      href={`/site/${site.slug}`}
      className="group relative flex flex-col rounded-2xl border border-rule bg-surface p-5 transition-all duration-200 hover:-translate-y-1 hover:shadow-[0_14px_34px_rgba(0,0,0,0.10)]"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          {site.featured && (
            <p className="mb-1 font-ui text-[10px] font-bold uppercase tracking-wider text-coral">
              &#9733; Editor&rsquo;s Pick
            </p>
          )}
          <p className="truncate font-mono text-xs text-ink-tertiary">
            {site.domain}
          </p>
          <h3
            className="mt-1 font-display text-xl font-semibold leading-tight text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            {site.name}
          </h3>
        </div>
        <span
          className={`grid h-12 w-12 shrink-0 place-items-center rounded-full text-white ${scoreBadgeClass(
            score,
          )}`}
          title={`Score: ${score}/100`}
          aria-label={`Score ${score} out of 100`}
        >
          <span
            className="font-display text-lg font-semibold leading-none"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            {score}
          </span>
        </span>
      </div>

      <p className="mt-2 line-clamp-3 font-body text-sm leading-relaxed text-ink-secondary">
        {site.summary}
      </p>

      <div className="mt-auto flex flex-wrap gap-1.5 pt-4">
        {site.tags.slice(0, 3).map((tag) => (
          <span
            key={tag}
            className="rounded-md border border-rule px-2 py-0.5 font-ui text-xs text-ink-tertiary"
          >
            {tag}
          </span>
        ))}
      </div>
    </Link>
  );
}
