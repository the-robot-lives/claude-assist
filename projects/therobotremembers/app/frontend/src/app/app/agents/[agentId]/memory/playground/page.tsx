"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { toast } from "sonner";
import { api, type RecallMood, type RecallResult } from "@/lib/api";
import {
  contentTypeColor,
  contributionColor,
  contributionFamilyKey,
  prettySource,
  CONTRIBUTION_FAMILIES,
  clamp,
} from "@/lib/memory-viz";

type MoodKey = keyof RecallMood;

const VAD: { key: MoodKey; label: string; min: number; max: number }[] = [
  { key: "valence", label: "Valence", min: -1, max: 1 },
  { key: "arousal", label: "Arousal", min: -1, max: 1 },
  { key: "dominance", label: "Dominance", min: -1, max: 1 },
];
const HORMONES: { key: MoodKey; label: string; min: number; max: number }[] = [
  { key: "cortisol", label: "Cortisol", min: 0, max: 1 },
  { key: "dopamine", label: "Dopamine", min: 0, max: 1 },
  { key: "oxytocin", label: "Oxytocin", min: 0, max: 1 },
  { key: "serotonin", label: "Serotonin", min: 0, max: 1 },
];

const DEFAULT_MOOD: Required<RecallMood> = {
  valence: 0,
  arousal: 0,
  dominance: 0,
  cortisol: 0.5,
  dopamine: 0.5,
  oxytocin: 0.5,
  serotonin: 0.5,
};

export default function RecallPlaygroundPage() {
  const { agentId: rawAgentId } = useParams<{ agentId: string }>();
  const agentId = rawAgentId ?? "";

  const [query, setQuery] = useState("");
  const [includeMood, setIncludeMood] = useState(false);
  const [mood, setMood] = useState<Required<RecallMood>>(DEFAULT_MOOD);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [rrfK, setRrfK] = useState(60);
  const [limit, setLimit] = useState(12);

  const [results, setResults] = useState<RecallResult[] | null>(null);
  const [durationMs, setDurationMs] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const canRun = query.trim().length > 0 || includeMood;

  // Normalize contribution bar widths against the largest contribution seen.
  const maxContribution = useMemo(() => {
    if (!results) return 0;
    let m = 0;
    for (const r of results) for (const c of r.contributions) if (c.score > m) m = c.score;
    return m;
  }, [results]);

  const legendFamilies = useMemo(() => {
    if (!results) return [];
    const present = new Set<string>();
    for (const r of results) for (const c of r.contributions) present.add(contributionFamilyKey(c.source));
    return Array.from(present).map((key) => {
      const known = CONTRIBUTION_FAMILIES.find((f) => f.key === key);
      return known ?? { key, label: key, color: contributionColor(`${key}:`) };
    });
  }, [results]);

  async function run() {
    if (!canRun || !agentId) return;
    setLoading(true);
    setError(null);
    try {
      const body: Parameters<typeof api.recallPreview>[1] = { limit };
      if (query.trim()) body.query = query.trim();
      if (includeMood) body.mood = mood;
      if (showAdvanced && rrfK !== 60) body.overrides = { rrf_k: rrfK };

      const res = await api.recallPreview(agentId, body);
      setResults(res.results ?? []);
      setDurationMs(res.duration_ms ?? null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Recall preview failed");
      setResults(null);
      setDurationMs(null);
      toast.error("Recall preview failed");
    } finally {
      setLoading(false);
    }
  }

  function setMoodValue(key: MoodKey, value: number) {
    setMood((m) => ({ ...m, [key]: value }));
  }

  return (
    <div className="mem-page">
      <div className="mem-breadcrumb">
        <Link href="/app/agents">Agents</Link> /{" "}
        <Link href={`/app/agents/${encodeURIComponent(agentId)}/memory`}>{agentId}</Link> /
        playground
      </div>

      <div className="mem-header">
        <div>
          <h1 className="mem-title">Recall playground</h1>
          <p className="mem-subtitle">
            Rank this agent&apos;s memories against a query and emotional context.
          </p>
        </div>
      </div>

      <div className="mem-banner mem-banner--info">
        Preview only — this runs recall ranking without reinforcing memories or
        mutating agent state.
      </div>

      <div className="mem-field">
        <label htmlFor="recall-query">Query</label>
        <textarea
          id="recall-query"
          rows={3}
          value={query}
          placeholder="What should the agent try to remember?"
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>

      <div className="mem-field">
        <label style={{ display: "flex", alignItems: "center", gap: "0.5rem", cursor: "pointer" }}>
          <input
            type="checkbox"
            checked={includeMood}
            onChange={(e) => setIncludeMood(e.target.checked)}
          />
          Include emotional context (mood)
        </label>
      </div>

      {includeMood && (
        <div style={{ marginBottom: "1rem" }}>
          <div className="mem-control__label" style={{ marginBottom: "0.4rem" }}>
            VAD (valence / arousal / dominance, −1…1)
          </div>
          <div className="mem-moods">
            {VAD.map((s) => (
              <MoodSlider key={s.key} label={s.label} min={s.min} max={s.max} value={mood[s.key] ?? 0} onChange={(v) => setMoodValue(s.key, v)} />
            ))}
          </div>
          <div className="mem-control__label" style={{ margin: "0.75rem 0 0.4rem" }}>
            Hormones (0…1)
          </div>
          <div className="mem-moods">
            {HORMONES.map((s) => (
              <MoodSlider key={s.key} label={s.label} min={s.min} max={s.max} value={mood[s.key] ?? 0.5} onChange={(v) => setMoodValue(s.key, v)} />
            ))}
          </div>
        </div>
      )}

      <div className="mem-field">
        <label style={{ display: "flex", alignItems: "center", gap: "0.5rem", cursor: "pointer" }}>
          <input
            type="checkbox"
            checked={showAdvanced}
            onChange={(e) => setShowAdvanced(e.target.checked)}
          />
          Advanced overrides
        </label>
      </div>

      {showAdvanced && (
        <div className="mem-toolbar" style={{ background: "transparent" }}>
          <div className="mem-control">
            <span className="mem-control__label">rrf_k</span>
            <input
              type="number"
              min={1}
              max={500}
              value={rrfK}
              onChange={(e) => setRrfK(clamp(parseInt(e.target.value || "60", 10), 1, 500))}
            />
          </div>
          <div className="mem-control">
            <span className="mem-control__label">limit</span>
            <input
              type="number"
              min={1}
              max={100}
              value={limit}
              onChange={(e) => setLimit(clamp(parseInt(e.target.value || "12", 10), 1, 100))}
            />
          </div>
        </div>
      )}

      <div style={{ display: "flex", alignItems: "center", gap: "1rem", margin: "0.5rem 0 1.5rem" }}>
        <button className="sg-btn sg-btn--black" disabled={!canRun || loading} onClick={run}>
          {loading ? "Running…" : "Run preview"}
        </button>
        {!canRun && (
          <span className="mem-subtitle">Enter a query or enable mood to run.</span>
        )}
        {durationMs !== null && (
          <span className="mem-subtitle">Completed in {durationMs} ms</span>
        )}
      </div>

      {error && (
        <div className="mem-banner mem-banner--error" role="alert">
          {error}
        </div>
      )}

      {results && legendFamilies.length > 0 && (
        <div className="mem-legend" style={{ marginBottom: "0.75rem" }}>
          {legendFamilies.map((f) => (
            <span key={f.key} className="mem-legend-item">
              <span className="mem-swatch" style={{ background: f.color }} />
              {f.label}
            </span>
          ))}
        </div>
      )}

      {results && results.length === 0 && !loading && (
        <div className="mem-empty">No memories matched this preview.</div>
      )}

      {results?.map((r, i) => (
        <div className="mem-result" key={r.memory.id}>
          <div className="mem-result__head">
            <span className="mem-result__rank">#{i + 1}</span>
            <span className="mem-result__score">{r.score.toFixed(4)}</span>
          </div>
          <div style={{ marginTop: "0.25rem" }}>
            <span className="mem-badge">
              <span className="mem-badge__dot" style={{ background: contentTypeColor(r.memory.content_type) }} />
              {r.memory.content_type}
            </span>
          </div>
          <p className="mem-result__summary">{r.memory.summary || "—"}</p>
          <div className="mem-contrib">
            {r.contributions.map((c) => (
              <div className="mem-contrib__row" key={`${r.memory.id}-${c.source}`}>
                <span title={c.source}>{prettySource(c.source)}</span>
                <span className="mem-bar-track">
                  <span
                    className="mem-bar-fill"
                    style={{
                      width: `${maxContribution > 0 ? (c.score / maxContribution) * 100 : 0}%`,
                      background: contributionColor(c.source),
                    }}
                  />
                </span>
                <span className="mem-contrib__score">{c.score.toFixed(4)}</span>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function MoodSlider({
  label,
  min,
  max,
  value,
  onChange,
}: {
  label: string;
  min: number;
  max: number;
  value: number;
  onChange: (v: number) => void;
}) {
  return (
    <div className="mem-mood">
      <div className="mem-mood__head">
        <span>{label}</span>
        <span className="mem-mood__val">{value.toFixed(2)}</span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={0.05}
        value={value}
        onChange={(e) => onChange(parseFloat(e.target.value))}
      />
    </div>
  );
}
