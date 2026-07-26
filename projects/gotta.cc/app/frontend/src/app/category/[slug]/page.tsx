"use client";

import { useEffect, useMemo, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { NavBar } from "../../navbar";
import { Footer } from "@/components/footer";
import { SiteRow } from "@/components/site-row";
import { api, type DirectoryCategory, type DirectorySite } from "@/lib/api";

const CATEGORY_TOKENS: Record<
  string,
  { bg: string; text: string; dot: string }
> = {
  technology: { bg: "bg-cat-technology-bg", text: "text-cat-technology-text", dot: "bg-cat-technology" },
  culture: { bg: "bg-cat-culture-bg", text: "text-cat-culture-text", dot: "bg-cat-culture" },
  science: { bg: "bg-cat-science-bg", text: "text-cat-science-text", dot: "bg-cat-science" },
  making: { bg: "bg-cat-making-bg", text: "text-cat-making-text", dot: "bg-cat-making" },
  "making-crafts": { bg: "bg-cat-making-bg", text: "text-cat-making-text", dot: "bg-cat-making" },
  games: { bg: "bg-cat-games-bg", text: "text-cat-games-text", dot: "bg-cat-games" },
  weird: { bg: "bg-cat-weird-bg", text: "text-cat-weird-text", dot: "bg-cat-weird" },
  "weird-wonderful": { bg: "bg-cat-weird-bg", text: "text-cat-weird-text", dot: "bg-cat-weird" },
};

const FALLBACK_TOKENS = { bg: "bg-surface", text: "text-ink", dot: "bg-coral" };
const TAG_PREVIEW = 12;

export default function CategoryPage() {
  const params = useParams<{ slug: string }>();
  const slug = params.slug;

  const [categories, setCategories] = useState<DirectoryCategory[]>([]);
  const [sites, setSites] = useState<DirectorySite[] | null>(null);
  const [error, setError] = useState(false);
  const [activeTag, setActiveTag] = useState<string | null>(null);
  const [showAllTags, setShowAllTags] = useState(false);

  // Load categories for header metadata.
  useEffect(() => {
    api.directoryCategories().then((r) => setCategories(r.categories)).catch(() => {});
  }, []);

  // Load sites for the category (reset tag filter on category change).
  useEffect(() => {
    setActiveTag(null);
    setShowAllTags(false);
    setSites(null);
    setError(false);
    api
      .directorySites({ category: slug, sort: "top", limit: 48 })
      .then((r) => setSites(r.sites))
      .catch(() => setError(true));
  }, [slug]);

  // Re-filter when a tag is selected.
  useEffect(() => {
    if (!activeTag) return;
    setSites(null);
    api
      .directorySites({ category: slug, tag: activeTag, sort: "top", limit: 48 })
      .then((r) => setSites(r.sites))
      .catch(() => setError(true));
  }, [activeTag, slug]);

  const category = categories.find((c) => c.slug === slug);
  const tokens = CATEGORY_TOKENS[slug] ?? FALLBACK_TOKENS;

  // Tags by frequency (most-used first) so the preview shows the useful ones.
  const orderedTags = useMemo(() => {
    const counts = new Map<string, number>();
    if (sites) {
      for (const s of sites) for (const t of s.tags) counts.set(t, (counts.get(t) ?? 0) + 1);
    }
    return Array.from(counts.entries())
      .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
      .map(([t]) => t);
  }, [sites]);

  const visibleTags = showAllTags ? orderedTags : orderedTags.slice(0, TAG_PREVIEW);

  const avgScore = useMemo(() => {
    if (!sites || sites.length === 0) return null;
    return Math.round(
      sites.reduce((sum, s) => sum + (s.scores?.overall ?? 0), 0) / sites.length,
    );
  }, [sites]);

  const siteCount = activeTag ? sites?.length ?? 0 : category?.site_count ?? sites?.length ?? 0;

  return (
    <div className="min-h-screen bg-cream">
      <NavBar />

      {/* Category header */}
      <section className={`px-6 py-12 ${tokens.bg}`}>
        <div className="mx-auto max-w-[960px]">
          <Link
            href="/"
            className={`font-ui text-xs font-semibold transition-colors ${tokens.text} opacity-80 hover:opacity-100`}
          >
            &larr; All categories
          </Link>
          <div className={`mt-4 flex items-center gap-2 ${tokens.text}`}>
            <span className={`h-2.5 w-2.5 rounded-full ${tokens.dot}`} />
            <span className="font-ui text-xs font-bold uppercase tracking-wider opacity-80">
              Category
            </span>
          </div>
          <h1
            className={`mt-2 font-display text-4xl font-semibold tracking-tight sm:text-5xl ${tokens.text}`}
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            {category?.name ?? slug}
          </h1>
          <p className={`mt-3 font-ui text-sm font-medium ${tokens.text} opacity-80`}>
            {sites === null
              ? "Loading…"
              : `${siteCount} site${siteCount === 1 ? "" : "s"}${avgScore !== null ? ` · ${avgScore} avg score` : ""}`}
          </p>
        </div>
      </section>

      <section className="px-6 py-8">
        <div className="mx-auto max-w-[960px]">
          {/* Tag filter — tamed: top tags + expand */}
          {orderedTags.length > 0 && (
            <div className="mb-8 flex flex-wrap items-center gap-2">
              <button
                onClick={() => setActiveTag(null)}
                className={`rounded-full border px-3 py-1.5 font-ui text-xs font-medium transition-colors ${
                  activeTag === null
                    ? "border-coral bg-coral text-white"
                    : "border-rule text-ink-secondary hover:text-ink"
                }`}
              >
                All
              </button>
              {visibleTags.map((tag) => (
                <button
                  key={tag}
                  onClick={() => setActiveTag(tag)}
                  className={`rounded-full border px-3 py-1.5 font-ui text-xs font-medium transition-colors ${
                    activeTag === tag
                      ? "border-coral bg-coral text-white"
                      : "border-rule text-ink-secondary hover:text-ink"
                  }`}
                >
                  {tag}
                </button>
              ))}
              {orderedTags.length > TAG_PREVIEW && (
                <button
                  onClick={() => setShowAllTags((v) => !v)}
                  className="rounded-full border border-dashed border-coral px-3 py-1.5 font-ui text-xs font-medium text-coral transition-opacity hover:opacity-80"
                >
                  {showAllTags
                    ? "Show fewer"
                    : `+ ${orderedTags.length - TAG_PREVIEW} more`}
                </button>
              )}
            </div>
          )}

          {error ? (
            <p className="font-body text-sm text-ink-secondary">
              Couldn&apos;t load sites for this category right now.
            </p>
          ) : sites === null ? (
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="h-48 animate-pulse rounded-2xl bg-surface" />
              ))}
            </div>
          ) : sites.length === 0 ? (
            <div className="rounded-2xl bg-surface p-10 text-center">
              <p className="font-display text-xl font-medium text-ink">No sites here yet.</p>
              <p className="mt-2 font-body text-sm text-ink-secondary">
                We&apos;re still curating this category. Check back soon.
              </p>
              <Link
                href="/"
                className="mt-6 inline-block font-ui text-sm font-semibold text-olive hover:text-olive-hover"
              >
                Browse other categories &rarr;
              </Link>
            </div>
          ) : (
            <div>
              {sites.map((s) => (
                <SiteRow key={s.id} site={s} />
              ))}
            </div>
          )}
        </div>
      </section>

      <Footer />
    </div>
  );
}
