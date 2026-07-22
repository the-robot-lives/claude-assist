"use client";

import * as React from "react";
import { useParams } from "next/navigation";
import { generationsApi, entriesApi, type Generation } from "@/lib/api";
import { ENTRY_TYPES, ENTRY_TYPE_LABELS, type EntryType } from "@/lib/constants";
import { Loader2 } from "lucide-react";

export default function GeneratePage() {
  const { universeId } = useParams() as { universeId: string };
  const [prompt, setPrompt] = React.useState("");
  const [entryType, setEntryType] = React.useState<EntryType>("concept");
  const [sources, setSources] = React.useState<
    { id: string; title: string; included: boolean }[]
  >([]);
  const [active, setActive] = React.useState<Generation | null>(null);
  const [history, setHistory] = React.useState<Generation[]>([]);
  const [busy, setBusy] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);

  const loadHistory = React.useCallback(async () => {
    const res = await generationsApi.list(universeId);
    setHistory(res.generations || []);
  }, [universeId]);

  React.useEffect(() => {
    entriesApi.list(universeId, { per_page: 50 }).then((res) => {
      setSources(
        res.entries.slice(0, 12).map((e) => ({
          id: e.id,
          title: e.title,
          included: true,
        })),
      );
    });
    loadHistory().catch(() => {});
  }, [universeId, loadHistory]);

  React.useEffect(() => {
    if (!active || !["pending", "running"].includes(active.status)) return;
    const t = setInterval(async () => {
      try {
        const { generation } = await generationsApi.get(universeId, active.id);
        setActive(generation);
        if (!["pending", "running"].includes(generation.status)) {
          loadHistory();
        }
      } catch {
        /* ignore poll errors */
      }
    }, 700);
    return () => clearInterval(t);
  }, [active, universeId, loadHistory]);

  async function onGenerate(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const { generation } = await generationsApi.create(universeId, {
        prompt,
        entry_type: entryType,
        source_entry_ids: sources.filter((s) => s.included).map((s) => s.id),
      });
      setActive(generation);
      await loadHistory();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Generation failed");
    } finally {
      setBusy(false);
    }
  }

  async function onPromote() {
    if (!active) return;
    setBusy(true);
    try {
      const { generation } = await generationsApi.promote(universeId, active.id);
      setActive(generation);
      await loadHistory();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Promote failed");
    } finally {
      setBusy(false);
    }
  }

  async function onDiscard() {
    if (!active) return;
    setBusy(true);
    try {
      const { generation } = await generationsApi.discard(universeId, active.id);
      setActive(generation);
      await loadHistory();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Discard failed");
    } finally {
      setBusy(false);
    }
  }

  const bodyText =
    active?.output_body &&
    typeof active.output_body === "object" &&
    "text" in active.output_body
      ? String(active.output_body.text || "")
      : "";

  return (
    <div className="max-w-4xl mx-auto px-6 py-10">
      <h1 className="font-serif text-[28px] font-bold text-ink mb-2">
        Generation studio
      </h1>
      <p className="font-sans text-[14px] text-ink-secondary mb-8">
        v0.1: single-entry context + selected sources (not full-universe RAG).
      </p>

      <form onSubmit={onGenerate} className="space-y-4 mb-10">
        <div className="grid sm:grid-cols-3 gap-4">
          <div className="sm:col-span-2">
            <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1.5">
              Prompt
            </label>
            <textarea
              required
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
              rows={4}
              className="w-full rounded-lg border border-rule px-3 py-2.5 font-sans text-[14px]"
              placeholder="Write the founding myth of Thornwall…"
            />
          </div>
          <div>
            <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1.5">
              Entry type
            </label>
            <select
              value={entryType}
              onChange={(e) => setEntryType(e.target.value as EntryType)}
              className="w-full rounded-lg border border-rule px-3 py-2.5 font-sans text-[14px]"
            >
              {ENTRY_TYPES.map((t) => (
                <option key={t} value={t}>
                  {ENTRY_TYPE_LABELS[t]}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div>
          <p className="font-mono text-[11px] uppercase text-ink-tertiary mb-2">
            Source entries
          </p>
          <div className="flex flex-wrap gap-2">
            {sources.map((s) => (
              <label
                key={s.id}
                className="inline-flex items-center gap-1.5 font-mono text-[11px] border border-rule rounded-full px-3 py-1"
              >
                <input
                  type="checkbox"
                  checked={s.included}
                  onChange={() =>
                    setSources((prev) =>
                      prev.map((x) =>
                        x.id === s.id ? { ...x, included: !x.included } : x,
                      ),
                    )
                  }
                />
                {s.title}
              </label>
            ))}
            {sources.length === 0 && (
              <span className="text-[13px] text-ink-tertiary">
                No entries yet — generation will run without sources.
              </span>
            )}
          </div>
        </div>

        {error && (
          <p className="text-[13px] text-flag-warn bg-flag-warn-muted px-3 py-2 rounded-md">
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={busy || !prompt.trim()}
          className="rounded-lg bg-accent text-white px-5 py-2.5 text-[14px] disabled:opacity-60"
        >
          {busy ? "Working…" : "Generate"}
        </button>
      </form>

      {active && (
        <section className="border border-rule rounded-xl p-6 mb-10 bg-surface">
          <div className="flex items-center justify-between gap-3 mb-3">
            <h2 className="font-serif text-[20px] font-semibold text-ink">
              {active.output_title || "In progress…"}
            </h2>
            <span className="font-mono text-[11px] uppercase text-ink-tertiary">
              {active.status}
              {["pending", "running"].includes(active.status) && (
                <Loader2 className="inline ml-2 animate-spin" size={12} />
              )}
            </span>
          </div>
          {bodyText && (
            <pre className="font-body text-[14px] text-ink whitespace-pre-wrap mb-4">
              {bodyText}
            </pre>
          )}
          {active.citations && active.citations.length > 0 && (
            <div className="mb-4">
              <p className="font-mono text-[11px] uppercase text-ink-tertiary mb-1">
                Citations
              </p>
              <ul className="list-disc pl-5 font-sans text-[13px] text-ink-secondary">
                {active.citations.map((c, i) => (
                  <li key={i}>{c.title}</li>
                ))}
              </ul>
            </div>
          )}
          {active.status === "complete" && (
            <div className="flex gap-2">
              <button
                type="button"
                onClick={onPromote}
                disabled={busy}
                className="rounded-lg bg-accent text-white px-4 py-2 text-[13px]"
              >
                Promote to entry
              </button>
              <button
                type="button"
                onClick={onDiscard}
                disabled={busy}
                className="rounded-lg border border-rule px-4 py-2 text-[13px]"
              >
                Discard
              </button>
            </div>
          )}
        </section>
      )}

      <section>
        <h2 className="font-mono text-[11px] uppercase text-ink-tertiary mb-3">
          History
        </h2>
        <ul className="border-t border-rule-subtle">
          {history.map((g) => (
            <li key={g.id} className="border-b border-rule-subtle py-3 flex gap-3">
              <button
                type="button"
                onClick={() => setActive(g)}
                className="text-left flex-1"
              >
                <span className="font-sans text-[14px] text-ink block">
                  {g.prompt.slice(0, 80)}
                </span>
                <span className="font-mono text-[11px] text-ink-tertiary">
                  {g.entry_type} · {g.status}
                  {g.cost_cents != null ? ` · ${g.cost_cents}¢` : ""}
                </span>
              </button>
            </li>
          ))}
          {history.length === 0 && (
            <li className="py-6 text-ink-tertiary text-[14px]">
              No generations yet.
            </li>
          )}
        </ul>
      </section>
    </div>
  );
}
