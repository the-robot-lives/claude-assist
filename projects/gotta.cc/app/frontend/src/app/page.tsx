"use client";

import { Fragment, Suspense, useEffect, useMemo, useState } from "react";
import type { CSSProperties } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { NavBar } from "./navbar";
import { Footer } from "@/components/footer";
import {
  SiteRow,
  categoryVar,
  RUBRIC_DIMENSIONS,
  type RubricKey,
} from "@/components/site-row";
import { AdSlot, AD_SLOTS } from "@/components/ad-slot";
import { api, type DirectoryCategory, type DirectorySite } from "@/lib/api";

const PAGE_SIZE = 24;

/** The in-feed unit sits after this many listing rows. */
const AD_AFTER_ROW = 6;

const SORTS = [
  { key: "top", label: "Top scored" },
  { key: "fresh", label: "Freshest" },
  { key: "newest", label: "Newly listed" },
  { key: "featured", label: "Editor's picks" },
] as const;

type SortKey = (typeof SORTS)[number]["key"];

const ZERO_MINIMUMS = Object.fromEntries(
  RUBRIC_DIMENSIONS.map((d) => [d.key, 0]),
) as Record<RubricKey, number>;

function browseHref(category: string, sort: SortKey) {
  const params = new URLSearchParams();
  if (category) params.set("category", category);
  if (sort !== "top") params.set("sort", sort);
  const qs = params.toString();
  return qs ? `/?${qs}` : "/";
}

function Browse() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const activeCategory = searchParams.get("category") ?? "";
  const sortParam = searchParams.get("sort") ?? "top";
  const sort: SortKey =
    (SORTS.find((s) => s.key === sortParam)?.key as SortKey) ?? "top";
  // "fresh" has no backend equivalent — fetch by score, then re-rank locally.
  const backendSort = sort === "fresh" ? "top" : sort;

  const [categories, setCategories] = useState<DirectoryCategory[] | null>(null);
  const [categoriesError, setCategoriesError] = useState(false);
  const [sites, setSites] = useState<DirectorySite[] | null>(null);
  const [sitesError, setSitesError] = useState(false);
  const [exhausted, setExhausted] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [minimums, setMinimums] = useState<Record<RubricKey, number>>(ZERO_MINIMUMS);
  const [surprising, setSurprising] = useState(false);

  useEffect(() => {
    api
      .directoryCategories()
      .then((r) => setCategories(r.categories))
      .catch(() => setCategoriesError(true));
  }, []);

  useEffect(() => {
    let cancelled = false;
    setSites(null);
    setSitesError(false);
    setExhausted(false);
    api
      .directorySites({
        category: activeCategory || undefined,
        sort: backendSort,
        limit: PAGE_SIZE,
      })
      .then((r) => {
        if (cancelled) return;
        setSites(r.sites);
        setExhausted(r.sites.length < PAGE_SIZE);
      })
      .catch(() => {
        if (!cancelled) setSitesError(true);
      });
    return () => {
      cancelled = true;
    };
  }, [activeCategory, backendSort]);

  async function loadMore() {
    if (!sites) return;
    setLoadingMore(true);
    try {
      const { sites: next } = await api.directorySites({
        category: activeCategory || undefined,
        sort: backendSort,
        limit: PAGE_SIZE,
        offset: sites.length,
      });
      setSites((prev) => [...(prev ?? []), ...next]);
      if (next.length < PAGE_SIZE) setExhausted(true);
    } catch {
      setExhausted(true);
    } finally {
      setLoadingMore(false);
    }
  }

  async function handleSurprise() {
    setSurprising(true);
    try {
      const { sites: picked } = await api.directorySites({
        sort: "random",
        limit: 1,
      });
      if (picked[0]) router.push(`/site/${picked[0].slug}`);
    } catch {
      /* ignore — button resets below */
    } finally {
      setSurprising(false);
    }
  }

  const totalSites = useMemo(
    () => (categories ?? []).reduce((sum, c) => sum + c.site_count, 0),
    [categories],
  );

  const activeCategoryRecord = categories?.find((c) => c.slug === activeCategory);

  const filtersActive = RUBRIC_DIMENSIONS.some((d) => minimums[d.key] > 0);

  const visible = useMemo(() => {
    if (!sites) return null;
    const kept = sites.filter((s) =>
      RUBRIC_DIMENSIONS.every((d) => s.scores[d.key] >= minimums[d.key]),
    );
    return sort === "fresh"
      ? [...kept].sort((a, b) => b.scores.freshness - a.scores.freshness)
      : kept;
  }, [sites, minimums, sort]);

  const listingCount = activeCategoryRecord?.site_count ?? totalSites;
  const sortLabel = SORTS.find((s) => s.key === sort)?.label.toLowerCase();

  return (
    <div className="gc-page">
      <NavBar siteCount={totalSites || undefined} />

      <section className="gc-intro">
        <div className="gc-wrap">
          <h1>
            Discover sites <em>worth reading.</em>
          </h1>
          <p className="gc-dek">
            Personal sites, niche blogs, and indie tools — scored for quality,
            depth, and usefulness. No SEO farms. No slop.
          </p>
          <div className="gc-counts">
            <span>
              <b>{totalSites ? totalSites.toLocaleString() : "—"}</b> sites listed
            </span>
            <span>
              <b>{categories ? categories.length : "—"}</b> categories
            </span>
            <span>
              <b>{RUBRIC_DIMENSIONS.length}</b> scoring dimensions
            </span>
          </div>
        </div>
      </section>

      <div className="gc-wrap">
        <nav className="gc-cat-rail" aria-label="Categories">
          {categories === null && !categoriesError
            ? Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="gc-cat-skeleton gc-skeleton" />
              ))
            : categoriesError
              ? null
              : categories!.map((cat) => {
                  const active = cat.slug === activeCategory;
                  return (
                    <Link
                      key={cat.slug}
                      href={browseHref(active ? "" : cat.slug, sort)}
                      aria-current={active ? "page" : undefined}
                      className={`gc-cat ${active ? "gc-active" : ""}`}
                      style={{ "--c": categoryVar(cat.slug) } as CSSProperties}
                    >
                      <span className="gc-cat-name">{cat.name}</span>
                      <span className="gc-cat-n">
                        {cat.site_count.toLocaleString()} sites
                      </span>
                    </Link>
                  );
                })}
        </nav>

        <div className="gc-main">
          <section>
            <div className="gc-listing-head">
              <h2>{activeCategoryRecord?.name ?? "All sites"}</h2>
              <span className="gc-listing-meta">
                {listingCount ? `${listingCount.toLocaleString()} sites · ` : ""}
                sorted by {sortLabel}
              </span>
              <nav className="gc-sort" aria-label="Sort">
                {SORTS.map((s) => (
                  <Link
                    key={s.key}
                    href={browseHref(activeCategory, s.key)}
                    className={s.key === sort ? "gc-on" : ""}
                  >
                    {s.label}
                  </Link>
                ))}
              </nav>
            </div>

            {sitesError ? (
              <p className="gc-note">
                Couldn&apos;t load the directory right now. Try again in a moment.
              </p>
            ) : visible === null ? (
              Array.from({ length: 5 }).map((_, i) => (
                <div
                  key={i}
                  className="gc-skeleton"
                  style={{ height: 96, marginBottom: 12 }}
                />
              ))
            ) : visible.length === 0 ? (
              <p className="gc-note">
                {filtersActive
                  ? "No sites clear those rubric minimums yet — try loosening a filter."
                  : "No sites listed here yet — check back soon."}
              </p>
            ) : (
              visible.map((site, i) => (
                <Fragment key={site.id}>
                  <SiteRow site={site} />
                  {i === AD_AFTER_ROW - 1 && (
                    <AdSlot slot={AD_SLOTS.browseInFeed} format="feed" />
                  )}
                </Fragment>
              ))
            )}

            {visible !== null && visible.length > 0 && !exhausted && (
              <button
                className="gc-more"
                onClick={loadMore}
                disabled={loadingMore}
              >
                {loadingMore ? "Loading…" : "Show more sites"}
              </button>
            )}
          </section>

          <aside>
            <div className="gc-box">
              <h3>Refine by rubric</h3>
              {RUBRIC_DIMENSIONS.map((dim) => {
                const value = minimums[dim.key];
                return (
                  <div key={dim.key}>
                    <label className="gc-filter-row" htmlFor={`min-${dim.key}`}>
                      <span>{dim.label}</span>
                      <span className="gc-filter-range">{value}–100</span>
                    </label>
                    <input
                      id={`min-${dim.key}`}
                      className="gc-slider"
                      type="range"
                      min={0}
                      max={100}
                      step={5}
                      value={value}
                      onChange={(e) =>
                        setMinimums((prev) => ({
                          ...prev,
                          [dim.key]: Number(e.target.value),
                        }))
                      }
                      style={{ "--p": `${value}%` } as CSSProperties}
                    />
                  </div>
                );
              })}
              {filtersActive && (
                <button
                  className="gc-go"
                  onClick={() => setMinimums(ZERO_MINIMUMS)}
                >
                  Reset filters
                </button>
              )}
            </div>

            <div className="gc-box">
              <h3>How scores read</h3>
              <div className="gc-legend">
                <div className="gc-legend-row">
                  <span
                    className="gc-legend-dot"
                    style={{ background: "var(--score-high)" }}
                  />
                  Exceptional <span className="gc-legend-val">85–100</span>
                </div>
                <div className="gc-legend-row">
                  <span
                    className="gc-legend-dot"
                    style={{ background: "var(--score-medium)" }}
                  />
                  Solid <span className="gc-legend-val">65–84</span>
                </div>
                <div className="gc-legend-row">
                  <span
                    className="gc-legend-dot"
                    style={{ background: "var(--score-low)" }}
                  />
                  Fading <span className="gc-legend-val">0–64</span>
                </div>
              </div>
            </div>

            <div className="gc-box">
              <h3>No particular plan?</h3>
              <button
                className="gc-go"
                onClick={handleSurprise}
                disabled={surprising}
                style={{ marginTop: 0 }}
              >
                {surprising ? "Finding…" : "Send me somewhere good →"}
              </button>
            </div>

            <div className="gc-box gc-promo">
              <h3>Know a good site?</h3>
              <p>
                The best corners of the web are the ones nobody indexed. Send us
                yours — a human will read it.
              </p>
              <Link className="gc-go" href="/submit">
                Submit a site →
              </Link>
            </div>

            <AdSlot slot={AD_SLOTS.browseRail} format="rail" />
          </aside>
        </div>
      </div>

      <Footer />
    </div>
  );
}

export default function Home() {
  return (
    <Suspense
      fallback={
        <div className="gc-page">
          <NavBar />
          <div className="gc-wrap">
            <p className="gc-note">Loading the directory…</p>
          </div>
          <Footer />
        </div>
      }
    >
      <Browse />
    </Suspense>
  );
}
