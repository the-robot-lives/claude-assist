"use client";

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { NavBar } from "../navbar";
import { Footer } from "@/components/footer";
import { SearchBar } from "@/components/search-bar";
import { SiteRow } from "@/components/site-row";
import { api, type DirectorySite } from "@/lib/api";

function SearchResults() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const initialQ = searchParams.get("q") ?? "";

  const [q, setQ] = useState(initialQ);
  const [results, setResults] = useState<DirectorySite[] | null>(null);
  const [featured, setFeatured] = useState<DirectorySite[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(false);

  // Keep field + URL in sync if the ?q= changes externally (back/forward).
  useEffect(() => {
    setQ(initialQ);
  }, [initialQ]);

  // Load featured fallback once.
  useEffect(() => {
    api
      .directorySites({ sort: "featured", limit: 6 })
      .then((r) => setFeatured(r.sites))
      .catch(() => setFeatured([]));
  }, []);

  // Debounced search.
  useEffect(() => {
    const trimmed = q.trim();
    if (!trimmed) {
      setResults(null);
      setLoading(false);
      return;
    }
    setLoading(true);
    const handle = setTimeout(() => {
      api
        .directorySearch(trimmed)
        .then((r) => {
          setResults(r.sites);
          setError(false);
        })
        .catch(() => setError(true))
        .finally(() => setLoading(false));
    }, 200);
    return () => clearTimeout(handle);
  }, [q]);

  function commit(next: string) {
    setQ(next);
    const trimmed = next.trim();
    const target = trimmed
      ? `/search?q=${encodeURIComponent(trimmed)}`
      : "/search";
    router.replace(target);
  }

  const trimmed = q.trim();
  const showFeatured = !trimmed;

  return (
    <div className="min-h-screen bg-cream">
      <NavBar />

      <section className="px-6 py-12">
        <div className="mx-auto max-w-[960px]">
          <p className="mb-6 font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
            Search
          </p>
          <h1
            className="font-display text-3xl font-semibold tracking-tight text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            {trimmed ? `Results for “${trimmed}”` : "Find a site worth reading"}
          </h1>

          <div className="mt-6">
            <SearchBar
              value={q}
              onChange={(v) => commit(v)}
              onDebouncedChange={(v) => commit(v)}
              onSubmit={(v) => commit(v)}
              placeholder="Search sites worth your time…"
              autoFocus
            />
          </div>

          {showFeatured && (
            <p className="mt-4 font-body text-sm text-ink-tertiary">
              Try searching for &ldquo;interviews&rdquo;, &ldquo;essays&rdquo;,
              &ldquo;tilde&rdquo;…
            </p>
          )}

          <div className="mt-10">
            {error ? (
              <p className="font-body text-sm text-ink-secondary">
                Search couldn&apos;t complete right now. Try again.
              </p>
            ) : loading ? (
              <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
                Searching…
              </p>
            ) : showFeatured ? (
              <div>
                <p className="mb-6 font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
                  Editor&apos;s Picks
                </p>
                <div>
                  {featured === null
                    ? Array.from({ length: 4 }).map((_, i) => (
                        <div
                          key={i}
                          className="gc-skeleton"
                          style={{ height: 96, marginBottom: 12 }}
                        />
                      ))
                    : featured.map((s) => <SiteRow key={s.id} site={s} />)}
                </div>
              </div>
            ) : results && results.length === 0 ? (
              <p className="font-body text-sm text-ink-secondary">
                No sites matched. Try a different term.
              </p>
            ) : (
              <div>
                {results?.map((s) => <SiteRow key={s.id} site={s} />)}
              </div>
            )}
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}

export default function SearchPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-cream flex items-center justify-center">
          <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
            Loading…
          </p>
        </div>
      }
    >
      <SearchResults />
    </Suspense>
  );
}
