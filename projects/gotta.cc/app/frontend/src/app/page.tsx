"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { NavBar } from "./navbar";
import { Footer } from "@/components/footer";
import { SearchBar } from "@/components/search-bar";
import { SiteCard } from "@/components/site-card";
import { api, type DirectoryCategory, type DirectorySite } from "@/lib/api";

// Fixed 6 category slugs mapped to their jewel tokens.
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
  // Live backend slugs use the full names; map them to the short token classes.
  "making-crafts": {
    bg: "bg-cat-making-bg",
    text: "text-cat-making-text",
    dot: "bg-cat-making",
  },
  "weird-wonderful": {
    bg: "bg-cat-weird-bg",
    text: "text-cat-weird-text",
    dot: "bg-cat-weird",
  },
};

export default function Home() {
  const router = useRouter();
  const [categories, setCategories] = useState<DirectoryCategory[] | null>(null);
  const [featured, setFeatured] = useState<DirectorySite[] | null>(null);
  const [categoriesError, setCategoriesError] = useState(false);
  const [featuredError, setFeaturedError] = useState(false);
  const [surprising, setSurprising] = useState(false);

  useEffect(() => {
    api
      .directoryCategories()
      .then((r) => setCategories(r.categories))
      .catch(() => setCategoriesError(true));
    api
      .directorySites({ sort: "featured", limit: 6 })
      .then((r) => setFeatured(r.sites))
      .catch(() => setFeaturedError(true));
  }, []);

  function handleSearch(q: string) {
    const trimmed = q.trim();
    if (trimmed) router.push(`/search?q=${encodeURIComponent(trimmed)}`);
  }

  async function handleSurprise() {
    setSurprising(true);
    try {
      const { sites } = await api.directorySites({ sort: "random", limit: 1 });
      if (sites[0]) router.push(`/site/${sites[0].slug}`);
    } catch {
      /* ignore — button resets below */
    } finally {
      setSurprising(false);
    }
  }

  return (
    <div className="min-h-screen bg-cream">
      <NavBar />

      {/* Hero */}
      <section className="px-6 py-16 lg:py-20">
        <div className="mx-auto max-w-[960px]">
          <p className="mb-6 font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
            Browse the directory
          </p>
          <h1
            className="font-display text-[clamp(36px,5vw+1rem,56px)] font-semibold leading-[1.15] tracking-tight text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            Discover sites worth reading.
          </h1>
          <p className="mt-6 max-w-2xl font-body text-lg leading-relaxed text-ink-secondary">
            A curated directory of the post-slop web — personal sites, niche
            blogs, and indie tools, scored by AI for originality, depth, and
            human authorship.
          </p>

          <div className="mt-8 max-w-2xl">
            <SearchBar
              value=""
              onChange={() => {}}
              onSubmit={handleSearch}
              placeholder="Search sites…"
            />
          </div>

          <div className="mt-5 flex items-center gap-4">
            <button
              onClick={handleSurprise}
              disabled={surprising}
              className="rounded-xl bg-coral px-5 py-2 font-ui text-sm font-semibold text-white transition-all duration-150 hover:-translate-y-0.5 hover:bg-coral-hover disabled:opacity-50"
            >
              {surprising ? "Finding…" : "🎲 Surprise me"}
            </button>
            <Link
              href="/about"
              className="font-ui text-sm font-semibold text-olive hover:text-olive-hover transition-colors duration-200"
            >
              About gotta.cc &rarr;
            </Link>
          </div>
        </div>
      </section>

      {/* Categories */}
      <section id="categories" className="px-6 py-12">
        <div className="mx-auto max-w-[960px]">
          <p className="font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
            Browse
          </p>
          <h2
            className="mt-3 font-display text-2xl font-semibold tracking-tight text-ink sm:text-3xl"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            Navigate the web by topic
          </h2>

          <div className="mt-8 grid grid-cols-1 gap-5 sm:grid-cols-2 md:grid-cols-3">
            {categories === null && !categoriesError ? (
              Array.from({ length: 6 }).map((_, i) => (
                <div
                  key={i}
                  className="min-h-[150px] animate-pulse rounded-2xl bg-surface shadow-[0_2px_8px_rgba(0,0,0,0.04)]"
                />
              ))
            ) : categoriesError ? (
              <p className="col-span-full font-body text-sm text-ink-secondary">
                Couldn&apos;t load categories right now.
              </p>
            ) : (
              categories!.map((cat, i) => {
                const tokens = CATEGORY_TOKENS[cat.slug] ?? {
                  bg: "bg-surface",
                  text: "text-ink",
                  dot: "bg-coral",
                };
                const span =
                  i === 0 || i === 4 || i === 5 ? "md:col-span-2" : "";
                return (
                  <Link
                    key={cat.slug}
                    href={`/category/${cat.slug}`}
                    className={`flex min-h-[150px] flex-col justify-between rounded-2xl p-7 transition-all duration-200 hover:scale-[1.02] hover:shadow-[0_8px_24px_rgba(0,0,0,0.08)] ${tokens.bg} ${tokens.text} ${span}`}
                  >
                    <div>
                      <h3
                        className="font-display text-2xl font-semibold"
                        style={{ fontVariationSettings: "'WONK' 1" }}
                      >
                        {cat.name}
                      </h3>
                      <p className="mt-1 font-ui text-sm font-medium opacity-70">
                        {cat.site_count} sites
                      </p>
                    </div>
                    <div className="mt-4 flex items-center gap-2 border-t border-black/10 pt-4">
                      <span
                        className={`h-2 w-2 flex-shrink-0 rounded-full ${tokens.dot}`}
                      />
                      <span className="font-ui text-[13px] font-medium">
                        Explore &rarr;
                      </span>
                    </div>
                  </Link>
                );
              })
            )}
          </div>
        </div>
      </section>

      {/* Featured */}
      <section className="px-6 py-12">
        <div className="mx-auto max-w-[960px]">
          <p className="font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
            Editor&apos;s Picks
          </p>
          <h2
            className="mt-3 font-display text-2xl font-semibold tracking-tight text-ink sm:text-3xl"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            The best of the directory
          </h2>

          <div className="mt-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {featured === null && !featuredError ? (
              Array.from({ length: 6 }).map((_, i) => (
                <div
                  key={i}
                  className="h-48 animate-pulse rounded-2xl bg-surface shadow-[0_2px_8px_rgba(0,0,0,0.04)]"
                />
              ))
            ) : featuredError ? (
              <p className="col-span-full font-body text-sm text-ink-secondary">
                Couldn&apos;t load featured sites right now.
              </p>
            ) : featured!.length === 0 ? (
              <p className="col-span-full font-body text-sm text-ink-secondary">
                No featured sites yet — check back soon.
              </p>
            ) : (
              featured!.map((site) => <SiteCard key={site.id} site={site} />)
            )}
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}
