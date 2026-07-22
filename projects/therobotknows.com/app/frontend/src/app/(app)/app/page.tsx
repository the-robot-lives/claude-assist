"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Plus, AlertTriangle, CheckCircle2, Loader2 } from "lucide-react";
import { universesApi } from "@/lib/api";
import { toUiUniverse } from "@/lib/api/mappers";
import type { Universe } from "@/types/universe";

function formatRelativeTime(isoString: string): string {
  const date = new Date(isoString);
  const now = new Date();
  const diffMs = Math.max(0, now.getTime() - date.getTime());
  const diffMinutes = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMinutes / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffMinutes < 1) return "just now";
  if (diffMinutes < 60) return `${diffMinutes}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays === 1) return "yesterday";
  return `${diffDays}d ago`;
}

export default function UniversesDashboardPage() {
  const [universes, setUniverses] = useState<Universe[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await universesApi.list();
        if (cancelled) return;
        setUniverses(res.universes.map(toUiUniverse));
        setError(null);
      } catch (e) {
        if (cancelled) return;
        setError(e instanceof Error ? e.message : "Failed to load universes");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div>
      <div className="mb-8 flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-serif text-[32px] font-bold leading-tight tracking-[-0.01em] text-ink">
            Your universes
          </h1>
          <p className="mt-1 font-sans text-[15px] text-ink-secondary">
            {loading
              ? "Loading…"
              : universes.length === 0
                ? "Create a universe to begin your canon."
                : `${universes.length} universe${universes.length === 1 ? "" : "s"}`}
          </p>
        </div>
        <Link
          href="/app/new"
          className="inline-flex items-center gap-2 rounded-lg bg-accent px-4 py-2.5 font-sans text-[14px] font-medium text-white hover:bg-accent-hover"
        >
          <Plus size={16} /> New universe
        </Link>
      </div>

      {error && (
        <div className="mb-6 rounded-lg border border-flag-warn bg-flag-warn-muted px-4 py-3 font-sans text-[14px] text-ink">
          {error}
        </div>
      )}

      {loading ? (
        <div className="mb-12 flex items-center gap-2 font-sans text-[14px] text-ink-secondary">
          <Loader2 size={16} className="animate-spin" />
          Loading universes…
        </div>
      ) : universes.length === 0 ? (
        <div className="mb-12 rounded-xl border border-dashed border-rule p-12 text-center">
          <h2 className="mb-2 font-serif text-[22px] font-semibold text-ink">
            No universes yet
          </h2>
          <p className="mx-auto mb-6 max-w-md font-sans text-[14px] text-ink-secondary">
            A universe is one creative world — novel, campaign, or game. Seed
            canon entries, then generate and keep everything consistent.
          </p>
          <Link
            href="/app/new"
            className="inline-flex items-center gap-2 rounded-lg bg-accent px-5 py-2.5 font-sans text-[14px] font-medium text-white"
          >
            <Plus size={16} /> Create your first universe
          </Link>
        </div>
      ) : (
        <div className="mb-12 grid grid-cols-1 gap-5 sm:grid-cols-2">
          {universes.map((universe) => (
            <Link
              key={universe.id}
              href={`/${universe.id}`}
              className="group block rounded-xl border border-rule bg-surface p-7 transition-all duration-200 hover:-translate-y-0.5 hover:border-rule-heavy hover:shadow-[0_4px_16px_rgba(0,0,0,0.06)]"
            >
              <div className="mb-3 flex items-start justify-between gap-3">
                <h3 className="font-serif text-[20px] font-semibold leading-snug text-ink transition-colors group-hover:text-accent">
                  {universe.name}
                </h3>
                {universe.flagCount > 0 ? (
                  <span className="mt-0.5 flex shrink-0 items-center gap-1 rounded-full bg-flag-warn-muted px-2 py-0.5 font-mono text-[11px] text-flag-warn">
                    <AlertTriangle size={10} strokeWidth={2} />
                    {universe.flagCount}
                  </span>
                ) : (
                  <span className="mt-0.5 flex shrink-0 items-center gap-1 rounded-full bg-success-muted px-2 py-0.5 font-mono text-[11px] text-success">
                    <CheckCircle2 size={10} strokeWidth={2} />
                    clear
                  </span>
                )}
              </div>
              {universe.genre && (
                <p className="mb-3 font-mono text-[11px] uppercase tracking-[0.04em] text-ink-tertiary">
                  {universe.genre}
                </p>
              )}
              <p className="mb-5 line-clamp-2 font-sans text-[13px] leading-relaxed text-ink-secondary">
                {universe.description || "No description yet."}
              </p>
              <div className="flex items-center gap-4 font-mono text-[11px] tracking-[0.02em] text-ink-tertiary">
                <span>{universe.entryCount} entries</span>
                <span className="text-rule">·</span>
                <span>{universe.connectionCount} links</span>
                <span className="text-rule">·</span>
                <span>Updated {formatRelativeTime(universe.updatedAt)}</span>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
