"use client";

import { useEffect, useState } from "react";
import type { CSSProperties } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { NavBar } from "../../navbar";
import { Footer } from "@/components/footer";
import {
  SiteRow,
  categoryVar,
  scoreVar,
  RUBRIC_DIMENSIONS,
} from "@/components/site-row";
import { AdSlot, AD_SLOTS } from "@/components/ad-slot";
import { api, type DirectorySite } from "@/lib/api";

/** Matches the legend on the browse page. */
function scoreBand(score: number) {
  if (score >= 85) return "Exceptional";
  if (score >= 65) return "Solid";
  return "Fading";
}

function barClass(score: number) {
  if (score >= 85) return "gc-hi";
  if (score >= 65) return "";
  return "gc-lo";
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
      <div className="gc-page">
        <NavBar />
        <div className="gc-wrap">
          <p className="gc-note">Loading…</p>
        </div>
        <Footer />
      </div>
    );
  }

  if (status === "notfound" || !site) {
    return (
      <div className="gc-page">
        <NavBar />
        <div className="gc-wrap">
          <div className="gc-detail">
            <h1 className="gc-detail-title">Site not found.</h1>
            <p className="gc-detail-prose" style={{ marginTop: 14 }}>
              This listing may have been removed, or it never existed.
            </p>
            <Link className="gc-link" href="/" style={{ display: "inline-block", marginTop: 20 }}>
              &larr; Back to the directory
            </Link>
          </div>
        </div>
        <Footer />
      </div>
    );
  }

  const overall = site.scores.overall;
  const catColor = categoryVar(site.category?.slug);
  const scColor = scoreVar(overall);
  const monogram = site.name.trim().charAt(0).toUpperCase() || "?";

  return (
    <div className="gc-page">
      <NavBar />

      <div className="gc-wrap">
        <article className="gc-detail">
          <nav className="gc-crumb" aria-label="Breadcrumb">
            <Link href="/">Directory</Link>
            <span aria-hidden="true">/</span>
            <Link
              href={`/category/${site.category.slug}`}
              className="gc-crumb-cat"
              style={{ "--c": catColor } as CSSProperties}
            >
              {site.category.name}
            </Link>
          </nav>

          <header className="gc-detail-head">
            <div
              className="gc-mono-mark gc-mono-mark-lg"
              style={{ "--c": catColor } as CSSProperties}
              aria-hidden="true"
            >
              {monogram}
            </div>

            <div className="gc-detail-headline">
              <h1 className="gc-detail-title">{site.name}</h1>
              <a
                className="gc-detail-url"
                href={site.url}
                target="_blank"
                rel="noopener noreferrer"
              >
                {site.domain}
              </a>
              <div className="gc-detail-tags">
                <span className="gc-pill" style={{ "--c": catColor } as CSSProperties}>
                  {site.category.name}
                </span>
                {site.tags.map((tag) => (
                  <span
                    key={tag}
                    className="gc-pill"
                    style={{ "--c": "var(--ink-tertiary)" } as CSSProperties}
                  >
                    {tag}
                  </span>
                ))}
                {site.featured && (
                  <span className="gc-flag gc-flag-editor">
                    &#10022; Editor&rsquo;s pick
                  </span>
                )}
              </div>
            </div>

            <a
              className="gc-cta"
              href={site.url}
              target="_blank"
              rel="noopener noreferrer"
            >
              Visit site &rarr;
            </a>
          </header>

          <section
            className="gc-detail-score"
            style={{ "--sc": scColor } as CSSProperties}
            aria-label="Score breakdown"
          >
            <div className="gc-detail-overall">
              <div className="gc-detail-overall-num">{overall}</div>
              <div className="gc-detail-overall-lbl">Overall / 100</div>
              <div className="gc-detail-band">{scoreBand(overall)}</div>
            </div>

            <div className="gc-detail-dims">
              {RUBRIC_DIMENSIONS.map((dim) => {
                const value = site.scores[dim.key];
                return (
                  <div key={dim.key}>
                    <div className="gc-detail-dim-head">
                      <span>{dim.label}</span>
                      <span className="gc-detail-dim-val">{value}</span>
                    </div>
                    <div className="gc-detail-dim-bar">
                      <i
                        className={barClass(value)}
                        style={{ "--v": `${value}%` } as CSSProperties}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </section>

          {site.summary && (
            <section className="gc-detail-section">
              <h2 className="gc-detail-h2">What it is</h2>
              <p className="gc-detail-prose">{site.summary}</p>
            </section>
          )}

          {!moreLoading && more.length > 0 && (
            <section className="gc-detail-section">
              <h2 className="gc-detail-h2">More in {site.category.name}</h2>
              <div className="gc-detail-rows">
                {more.map((s) => (
                  <SiteRow key={s.id} site={s} />
                ))}
              </div>
              <Link
                className="gc-link"
                href={`/category/${site.category.slug}`}
                style={{ display: "inline-block", marginTop: 18 }}
              >
                Browse all of {site.category.name} &rarr;
              </Link>
            </section>
          )}

          <AdSlot slot={AD_SLOTS.siteDetail} format="detail" />
        </article>
      </div>

      <Footer />
    </div>
  );
}
