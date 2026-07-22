"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { EntryCard } from "@/components/entries/entry-card";
import { entriesApi } from "@/lib/api";
import { toUiEntry } from "@/lib/api/mappers";
import type { Entry } from "@/types/entry";
import type { EntryStatus, EntryType } from "@/lib/constants";
import { ENTRY_TYPES, ENTRY_TYPE_LABELS } from "@/lib/constants";
import { Loader2 } from "lucide-react";

export default function EntriesPage() {
  const params = useParams();
  const universeId = String(params.universeId ?? "");
  const [entries, setEntries] = useState<Entry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [typeFilter, setTypeFilter] = useState<EntryType | "">("");
  const [statusFilter, setStatusFilter] = useState<EntryStatus | "">("");
  const [q, setQ] = useState("");

  useEffect(() => {
    if (!universeId) return;
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const res = await entriesApi.list(universeId, {
          type: typeFilter || undefined,
          status: statusFilter || undefined,
          q: q || undefined,
          per_page: 100,
        });
        if (cancelled) return;
        setEntries(
          res.entries.map((e) => ({
            ...toUiEntry(e),
            apiId: e.id,
          })),
        );
        setError(null);
      } catch (e) {
        if (!cancelled)
          setError(e instanceof Error ? e.message : "Failed to load entries");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [universeId, typeFilter, statusFilter, q]);

  const counts = useMemo(() => {
    return {
      canon: entries.filter((e) => e.status === "canon").length,
      generated: entries.filter((e) => e.status === "generated").length,
      draft: entries.filter((e) => e.status === "draft").length,
      connections: entries.reduce((s, e) => s + e.connectionIds.length, 0),
    };
  }, [entries]);

  return (
    <div className="min-h-screen bg-page">
      <div className="max-w-[1100px] mx-auto px-6 py-10 sm:px-10">
        <div className="flex items-baseline justify-between mb-8 gap-4 flex-wrap">
          <div>
            <h1 className="font-serif text-[32px] font-bold leading-tight text-ink">
              Entries
            </h1>
            <p className="font-mono text-[12px] text-ink-tertiary mt-1 tracking-[0.02em]">
              {loading
                ? "Loading…"
                : `${entries.length} ${entries.length === 1 ? "entry" : "entries"}`}
            </p>
          </div>

          <Link
            href={`/${universeId}/entries/new`}
            className="inline-flex items-center gap-1.5 font-sans text-[14px] font-semibold text-white bg-accent hover:bg-accent-hover transition-colors duration-200 px-4 py-2 rounded-sm"
          >
            <span className="text-[16px] leading-none">+</span>
            New Entry
          </Link>
        </div>

        <div className="mb-8 flex flex-wrap gap-3 items-center">
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search title or excerpt…"
            className="rounded-lg border border-rule bg-surface px-3 py-2 font-sans text-[14px] min-w-[200px] focus:outline-none focus:border-accent"
          />
          <select
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value as EntryType | "")}
            className="rounded-lg border border-rule bg-surface px-3 py-2 font-mono text-[12px]"
          >
            <option value="">All types</option>
            {ENTRY_TYPES.map((t) => (
              <option key={t} value={t}>
                {ENTRY_TYPE_LABELS[t]}
              </option>
            ))}
          </select>
          <select
            value={statusFilter}
            onChange={(e) =>
              setStatusFilter(e.target.value as EntryStatus | "")
            }
            className="rounded-lg border border-rule bg-surface px-3 py-2 font-mono text-[12px]"
          >
            <option value="">All statuses</option>
            <option value="canon">Canon</option>
            <option value="draft">Draft</option>
            <option value="generated">Generated</option>
          </select>
        </div>

        {error && (
          <div className="mb-6 rounded-lg border border-flag-warn bg-flag-warn-muted px-4 py-3 text-[14px]">
            {error}
          </div>
        )}

        {loading ? (
          <div className="flex items-center gap-2 text-ink-secondary py-16">
            <Loader2 className="animate-spin" size={16} /> Loading entries…
          </div>
        ) : entries.length > 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {entries.map((entry) => (
              <EntryCard
                key={entry.apiId || entry.id}
                entry={entry}
                universeId={universeId}
              />
            ))}
          </div>
        ) : (
          <div className="text-center py-24 border border-dashed border-rule rounded-xl">
            <p className="font-serif text-[20px] text-ink-secondary mb-2">
              No entries yet.
            </p>
            <p className="font-sans text-[14px] text-ink-tertiary mb-6">
              Create your first entry to begin building this universe.
            </p>
            <Link
              href={`/${universeId}/entries/new`}
              className="font-sans text-[14px] text-accent hover:underline"
            >
              Create first entry
            </Link>
          </div>
        )}

        <div className="mt-12 pt-6 border-t border-rule-subtle">
          <div className="flex flex-wrap gap-4 font-mono text-[11px] text-ink-tertiary">
            <span>{counts.canon} canon</span>
            <span className="opacity-40">·</span>
            <span>{counts.draft} draft</span>
            <span className="opacity-40">·</span>
            <span>{counts.generated} generated</span>
            <span className="opacity-40">·</span>
            <span>{counts.connections} connections</span>
          </div>
        </div>
      </div>
    </div>
  );
}
