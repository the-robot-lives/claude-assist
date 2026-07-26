"use client";

import Link from "next/link";
import type { CSSProperties } from "react";
import type { DirectorySite } from "@/lib/api";

/**
 * Jewel tone per category. Backend slugs use the long form
 * ("making-crafts"); the short forms are kept for seed/fixture data.
 */
const CATEGORY_VARS: Record<string, string> = {
  technology: "var(--cat-technology)",
  culture: "var(--cat-culture)",
  science: "var(--cat-science)",
  making: "var(--cat-making)",
  "making-crafts": "var(--cat-making)",
  games: "var(--cat-games)",
  weird: "var(--cat-weird)",
  "weird-wonderful": "var(--cat-weird)",
};

export function categoryVar(slug: string | undefined) {
  return (slug && CATEGORY_VARS[slug]) || "var(--olive)";
}

/** Exceptional 85–100 · Solid 65–84 · Fading 0–64. */
export function scoreVar(score: number) {
  if (score >= 85) return "var(--score-high)";
  if (score >= 65) return "var(--score-medium)";
  return "var(--score-low)";
}

function barClass(score: number) {
  if (score >= 85) return "gc-hi";
  if (score >= 65) return "";
  return "gc-lo";
}

export const RUBRIC_DIMENSIONS = [
  { key: "originality", abbr: "OR", label: "Originality" },
  { key: "depth", abbr: "DE", label: "Depth" },
  { key: "freshness", abbr: "FR", label: "Freshness" },
  { key: "human_authorship", abbr: "HU", label: "Human Authorship" },
  { key: "design_quality", abbr: "DQ", label: "Design Quality" },
] as const;

export type RubricKey = (typeof RUBRIC_DIMENSIONS)[number]["key"];

export function SiteRow({ site }: { site: DirectorySite }) {
  const overall = site.scores.overall;
  const catColor = categoryVar(site.category?.slug);
  const monogram = site.name.trim().charAt(0).toUpperCase() || "?";

  return (
    <article className="gc-card">
      <div className="gc-mono-mark" style={{ "--c": catColor } as CSSProperties}>
        {monogram}
      </div>

      <div className="gc-card-body">
        <div className="gc-card-toprow">
          <Link href={`/site/${site.slug}`} className="gc-card-title">
            {site.name}
          </Link>
          <span className="gc-card-url">{site.domain}</span>
        </div>
        <p className="gc-card-desc">{site.summary}</p>
        <div className="gc-card-tags">
          {site.category?.name && (
            <span className="gc-pill" style={{ "--c": catColor } as CSSProperties}>
              {site.category.name}
            </span>
          )}
          {site.tags.slice(0, 2).map((tag) => (
            <span
              key={tag}
              className="gc-pill"
              style={{ "--c": "var(--ink-tertiary)" } as CSSProperties}
            >
              {tag}
            </span>
          ))}
          {site.featured && (
            <span className="gc-flag gc-flag-editor">&#10022; Editor&rsquo;s pick</span>
          )}
          {!site.featured && site.scores.freshness >= 85 && (
            <span className="gc-flag gc-flag-fresh">&#9679; Recently updated</span>
          )}
        </div>
      </div>

      <div
        className="gc-scorecard"
        style={{ "--sc": scoreVar(overall) } as CSSProperties}
      >
        <div className="gc-overall">
          <div className="gc-overall-num" title={`Overall score ${overall}/100`}>
            {overall}
          </div>
          <div className="gc-overall-lbl">Score</div>
        </div>
        <div className="gc-dims">
          {RUBRIC_DIMENSIONS.map((dim) => {
            const value = site.scores[dim.key];
            return (
              <div key={dim.key} className="gc-dim" title={`${dim.label}: ${value}/100`}>
                <span className="gc-dim-k">{dim.abbr}</span>
                <span className="gc-dim-bar">
                  <i
                    className={barClass(value)}
                    style={{ "--v": `${value}%` } as CSSProperties}
                  />
                </span>
              </div>
            );
          })}
        </div>
      </div>
    </article>
  );
}
