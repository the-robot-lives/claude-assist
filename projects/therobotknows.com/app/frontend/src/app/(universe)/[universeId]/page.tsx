"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import {
  User,
  MapPin,
  Swords,
  Landmark,
  Gem,
  Lightbulb,
  ScrollText,
  AlertTriangle,
  Network,
  BookOpen,
  Settings,
  Loader2,
} from "lucide-react";
import { universesApi, entriesApi } from "@/lib/api";
import { toUiEntry, toUiUniverse } from "@/lib/api/mappers";
import type { Universe } from "@/types/universe";
import type { Entry } from "@/types/entry";
import type { EntryType } from "@/lib/constants";
import { ENTRY_TYPE_LABELS, ENTRY_TYPES } from "@/lib/constants";

const typeIconMap: Record<
  EntryType,
  React.ComponentType<{ size?: number; strokeWidth?: number; className?: string }>
> = {
  character: User,
  location: MapPin,
  event: Swords,
  faction: Landmark,
  object: Gem,
  concept: Lightbulb,
  rule: ScrollText,
};

export default function UniverseOverviewPage() {
  const { universeId } = useParams() as { universeId: string };
  const [universe, setUniverse] = useState<Universe | null>(null);
  const [stats, setStats] = useState<{
    entry_counts_by_type?: Record<string, number>;
    entry_count: number;
    flag_count: number;
    connection_count: number;
  } | null>(null);
  const [recent, setRecent] = useState<Entry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const [{ universe: u }, statsRes, entriesRes] = await Promise.all([
          universesApi.get(universeId),
          universesApi.stats(universeId).catch(() => null),
          entriesApi.list(universeId, { per_page: 5 }),
        ]);
        if (cancelled) return;
        setUniverse(toUiUniverse(u));
        if (statsRes) setStats(statsRes.stats);
        setRecent(entriesRes.entries.map(toUiEntry));
        setError(null);
      } catch (e) {
        if (!cancelled)
          setError(e instanceof Error ? e.message : "Failed to load universe");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [universeId]);

  if (loading) {
    return (
      <div className="flex items-center gap-2 px-8 py-10 text-ink-secondary">
        <Loader2 className="animate-spin" size={16} /> Loading universe…
      </div>
    );
  }

  if (error || !universe) {
    return (
      <div className="px-8 py-10">
        <p className="text-flag-warn mb-4">{error || "Universe not found"}</p>
        <Link href="/app" className="text-accent">
          ← Universes
        </Link>
      </div>
    );
  }

  const byType = stats?.entry_counts_by_type ?? {};

  return (
    <div className="px-8 py-8 max-w-4xl">
      <div className="mb-8 flex items-start justify-between gap-4">
        <div>
          <h1 className="font-serif text-[32px] font-bold text-ink leading-tight tracking-[-0.01em] mb-1">
            {universe.name}
          </h1>
          <p className="font-mono text-[12px] text-ink-tertiary uppercase tracking-[0.04em] mb-3">
            {universe.genre || "Universe"}
          </p>
          <p className="font-sans text-[15px] text-ink-secondary leading-relaxed max-w-2xl">
            {universe.description}
          </p>
        </div>
        <Link
          href={`/${universeId}/settings`}
          className="inline-flex items-center gap-1.5 font-mono text-[11px] uppercase tracking-wide border border-rule rounded-lg px-3 py-2 hover:border-accent shrink-0"
        >
          <Settings size={14} /> Settings
        </Link>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-10">
        <StatTile
          label="Entries"
          value={stats?.entry_count ?? universe.entryCount}
          href={`/${universeId}/entries`}
          icon={BookOpen}
        />
        <StatTile
          label="Connections"
          value={stats?.connection_count ?? universe.connectionCount}
          href={`/${universeId}/graph`}
          icon={Network}
        />
        <StatTile
          label="Open flags"
          value={stats?.flag_count ?? universe.flagCount}
          href={`/${universeId}/consistency`}
          icon={AlertTriangle}
        />
        <StatTile
          label="Generate"
          value="→"
          href={`/${universeId}/generate`}
          icon={Lightbulb}
        />
      </div>

      <section className="mb-10">
        <h2 className="font-mono text-[11px] font-semibold uppercase tracking-[0.06em] text-ink-tertiary mb-4">
          By type
        </h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {ENTRY_TYPES.map((t) => {
            const Icon = typeIconMap[t];
            const count = byType[t] ?? recent.filter((e) => e.type === t).length;
            return (
              <Link
                key={t}
                href={`/${universeId}/entries?type=${t}`}
                className="border border-rule rounded-lg p-4 bg-surface hover:border-rule-heavy transition-colors"
              >
                <div className="flex items-center gap-2 mb-2">
                  <Icon size={14} strokeWidth={1.5} className="text-ink-tertiary" />
                  <span className="font-mono text-[11px] uppercase text-ink-tertiary">
                    {ENTRY_TYPE_LABELS[t]}
                  </span>
                </div>
                <div className="font-serif text-[22px] font-semibold text-ink">
                  {count}
                </div>
              </Link>
            );
          })}
        </div>
      </section>

      <section>
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-mono text-[11px] font-semibold uppercase tracking-[0.06em] text-ink-tertiary">
            Recent entries
          </h2>
          <Link
            href={`/${universeId}/entries/new`}
            className="font-sans text-[13px] text-accent hover:underline"
          >
            + New entry
          </Link>
        </div>
        {recent.length === 0 ? (
          <div className="border border-dashed border-rule rounded-xl p-10 text-center">
            <p className="font-serif text-[18px] text-ink-secondary mb-2">
              No entries yet
            </p>
            <p className="font-sans text-[14px] text-ink-tertiary mb-4">
              Seed the canon with characters, places, and rules.
            </p>
            <Link
              href={`/${universeId}/entries/new`}
              className="text-accent font-sans text-[14px] hover:underline"
            >
              Create first entry
            </Link>
          </div>
        ) : (
          <ul className="border-t border-rule-subtle">
            {recent.map((e) => (
              <li key={e.id} className="border-b border-rule-subtle">
                <Link
                  href={`/${universeId}/entries/${e.id}`}
                  className="flex items-center gap-3 py-3 hover:bg-elevated/50 px-1"
                >
                  <span className="font-mono text-[11px] uppercase text-ink-tertiary w-20 shrink-0">
                    {e.type}
                  </span>
                  <span className="font-serif text-[15px] text-ink flex-1">
                    {e.title}
                  </span>
                  <span className="font-mono text-[11px] text-ink-tertiary">
                    {e.status}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}

function StatTile({
  label,
  value,
  href,
  icon: Icon,
}: {
  label: string;
  value: string | number;
  href: string;
  icon: React.ComponentType<{ size?: number; strokeWidth?: number; className?: string }>;
}) {
  return (
    <Link
      href={href}
      className="border border-rule rounded-xl p-4 bg-surface hover:border-accent transition-colors"
    >
      <div className="flex items-center gap-2 mb-2 text-ink-tertiary">
        <Icon size={14} strokeWidth={1.5} />
        <span className="font-mono text-[11px] uppercase tracking-wide">
          {label}
        </span>
      </div>
      <div className="font-serif text-[24px] font-semibold text-ink">{value}</div>
    </Link>
  );
}
