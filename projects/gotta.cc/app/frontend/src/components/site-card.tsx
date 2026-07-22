"use client";

import Link from "next/link";
import type { DirectorySite } from "@/lib/api";

export function scoreBadgeClass(overall: number) {
  return overall >= 90
    ? "bg-score-high text-white"
    : overall >= 70
      ? "bg-score-medium text-white"
      : "bg-score-low text-white";
}

export function SiteCard({ site }: { site: DirectorySite }) {
  return (
    <Link
      href={`/site/${site.slug}`}
      className="group flex flex-col rounded-2xl bg-surface p-6 shadow-[0_2px_8px_rgba(0,0,0,0.06)] transition-all duration-200 hover:-translate-y-0.5 hover:shadow-[0_8px_24px_rgba(0,0,0,0.08)]"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="font-mono text-sm text-ink-tertiary">{site.domain}</p>
          <h3
            className="mt-1 font-display text-xl font-medium text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            {site.name}
          </h3>
        </div>
        {site.featured && (
          <span
            title="Editor's Pick"
            aria-label="Editor's Pick"
            className="shrink-0 text-coral"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor" aria-hidden="true">
              <path d="M12 2l2.9 6.3 6.9.7-5.1 4.7 1.4 6.8L12 17.8 5.9 20.5l1.4-6.8L2.2 9l6.9-.7z" />
            </svg>
          </span>
        )}
      </div>

      <p className="mt-3 line-clamp-3 font-body text-sm leading-relaxed text-ink-secondary">
        {site.summary}
      </p>

      <div className="mt-5 flex items-center justify-between gap-3">
        <div className="flex flex-wrap gap-2">
          {site.tags.slice(0, 3).map((tag) => (
            <span
              key={tag}
              className="rounded-lg border border-rule px-3 py-1 font-ui text-xs text-ink-secondary"
            >
              {tag}
            </span>
          ))}
        </div>
        <span
          className={`shrink-0 rounded-xl px-3 py-1 font-mono text-sm font-bold ${scoreBadgeClass(site.scores.overall)}`}
        >
          {site.scores.overall}
        </span>
      </div>
    </Link>
  );
}
