"use client";

import { useEffect, useMemo, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { NavBar } from "../../navbar";
import { Footer } from "@/components/footer";
import { SiteCard } from "@/components/site-card";
import { api, type DirectoryCategory, type DirectorySite } from "@/lib/api";

const CATEGORY_TOKENS: Record<
  string,
  { bg: string; text: string; dot: string }
> = {
  technology: {
    bg: "bg-cat-technology-bg",
    text: "text-cat-technology-text",
    dot: "bg-cat-technology",
  },
  culture: {
    bg: "bg-cat-culture-bg",
    text: "text-cat-culture-text",
    dot: "bg-cat-culture",
  },
  science: {
    bg: "bg-cat-science-bg",
    text: "text-cat-science-text",
    dot: "bg-cat-science",
  },
  making: {
    bg: "bg-cat-making-bg",
    text: "text-cat-making-text",
    dot: "bg-cat-making",
  },
  games: {
    bg: "bg-cat-games-bg",
    text: "text-cat-games-text",
    dot: "bg-cat-games",
  },
  weird: {
    bg: "bg-cat-weird-bg",
    text: "text-cat-weird-text",
    dot: "bg-cat-weird",
  },
};

export default function CategoryPage() {
  const params = useParams<{ slug: string }>();
  const slug = params.slug;

  const [categories, setCategories] = useState<DirectoryCategory[]>([]);
  const [sites, setSites] = useState<DirectorySite[] | null>(null);
  const [error, setError] = useState(false);
  const [activeTag, setActiveTag] = useState<string | null>(null);

  // Load categories for header metadata.
  useEffect(() => {
    api.directoryCategories().then((r) => setCategories(r.categories)).catch(() => {});
  }, []);

  // Load sites for the category.
  useEffect(() => {
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
  const tokens = CATEGORY_TOKENS[slug];

  const tags = useMemo(() => {
    if (!sites) return [];
    const set = new Set<string>();
    for (const s of sites) for (const t of s.tags) set.add(t);
    return Array.from(set).sort();
  }, [sites]);

  return (
    <div className="min-h-screen bg-cream">
      <NavBar />

      <section className={`px-6 py-12 ${tokens ? tokens.bg : ""}`}>
        <div className="mx-auto max-w-[960px]">
          <Link
            href="/"
            className={`font-ui text-xs font-semibold transition-colors duration-150 ${tokens ? tokens.text : "text-ink-secondary"} opacity-80 hover:opacity-100`}
          >
            &larr; All categories
          </Link>
          <h1
            className={`mt-4 font-display text-4xl font-semibold tracking-tight ${tokens ? tokens.text : "text-ink"}`}
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            {category?.name ?? slug}
          </h1>
          <p className={`mt-2 font-ui text-sm font-medium ${tokens ? tokens.text : "text-ink-secondary"} opacity-80`}>
            {sites?.length ?? category?.site_count ?? 0} sites
          </p>
        </div>
      </section>

      <section className="px-6 py-10">
        <div className="mx-auto max-w-[960px]">
          {/* Tag filter */}
          {tags.length > 0 && (
            <div className="mb-8 flex flex-wrap gap-2">
              <button
                onClick={() => setActiveTag(null)}
                className={`rounded-lg border px-3 py-1 font-ui text-xs transition-colors ${
                  activeTag === null
                    ? "border-olive bg-olive-light text-olive"
                    : "border-rule text-ink-secondary hover:text-ink"
                }`}
              >
                All
              </button>
              {tags.map((tag) => (
                <button
                  key={tag}
                  onClick={() => setActiveTag(tag)}
                  className={`rounded-lg border px-3 py-1 font-ui text-xs transition-colors ${
                    activeTag === tag
                      ? "border-olive bg-olive-light text-olive"
                      : "border-rule text-ink-secondary hover:text-ink"
                  }`}
                >
                  {tag}
                </button>
              ))}
            </div>
          )}

          {error ? (
            <p className="font-body text-sm text-ink-secondary">
              Couldn&apos;t load sites for this category right now.
            </p>
          ) : sites === null ? (
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {Array.from({ length: 6 }).map((_, i) => (
                <div
                  key={i}
                  className="h-48 animate-pulse rounded-2xl bg-surface"
                />
              ))}
            </div>
          ) : sites.length === 0 ? (
            <div className="rounded-2xl bg-surface p-10 text-center">
              <p className="font-display text-xl font-medium text-ink">
                No sites here yet.
              </p>
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
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {sites.map((s) => (
                <SiteCard key={s.id} site={s} />
              ))}
            </div>
          )}
        </div>
      </section>

      <Footer />
    </div>
  );
}
