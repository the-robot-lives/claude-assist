"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  APPS,
  AUTOSTART,
  BINDINGS,
  bindingMatchesQuery,
  CATEGORIES,
  formatKeys,
  RICE,
  type CategoryId,
  type KeyId,
} from "@/lib/bindings";
import { bindingMatchesHeld, eventToKeyIds } from "@/lib/keys";
import { BindingRow } from "./BindingRow";
import { Keyboard } from "./Keyboard";
import { MonitorMap } from "./MonitorMap";

type Filter = CategoryId | "all";

export function CheatSheetApp() {
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState<Filter>("all");
  const [activeKeys, setActiveKeys] = useState<Set<KeyId>>(new Set());
  const [listen, setListen] = useState(false);
  const [held, setHeld] = useState<KeyId[]>([]);
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [flashIds, setFlashIds] = useState<Set<string>>(new Set());
  const searchRef = useRef<HTMLInputElement>(null);

  const filtered = useMemo(() => {
    return BINDINGS.filter((b) => {
      if (category !== "all" && b.category !== category) return false;
      return bindingMatchesQuery(b, query);
    });
  }, [query, category]);

  const byCategory = useMemo(() => {
    const map = new Map<CategoryId, typeof filtered>();
    for (const b of filtered) {
      const list = map.get(b.category) ?? [];
      list.push(b);
      map.set(b.category, list);
    }
    return map;
  }, [filtered]);

  const onHover = useCallback((keys: KeyId[]) => {
    if (listen) return;
    setActiveKeys(new Set(keys));
  }, [listen]);

  const onLeave = useCallback(() => {
    if (listen) return;
    setActiveKeys(new Set());
  }, [listen]);

  const onCopy = useCallback(async (binding: (typeof BINDINGS)[number]) => {
    const text = `${formatKeys(binding.keys)}  →  ${binding.action}`;
    try {
      await navigator.clipboard.writeText(text);
      setCopiedId(binding.id);
      window.setTimeout(() => setCopiedId((id) => (id === binding.id ? null : id)), 1400);
    } catch {
      // ignore
    }
  }, []);

  // ⌘/Ctrl+K focus search
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        searchRef.current?.focus();
        searchRef.current?.select();
      }
      if (e.key === "Escape") {
        setQuery("");
        searchRef.current?.blur();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  // Listen / practice mode
  useEffect(() => {
    if (!listen) {
      setHeld([]);
      setFlashIds(new Set());
      setActiveKeys(new Set());
      return;
    }

    const isTypingTarget = (e: KeyboardEvent) => {
      const t = e.target as HTMLElement | null;
      return !!(
        t &&
        (t.tagName === "INPUT" || t.tagName === "TEXTAREA" || t.isContentEditable)
      );
    };

    const modsFrom = (e: KeyboardEvent): KeyId[] => {
      const mods: KeyId[] = [];
      if (e.metaKey) mods.push("super");
      if (e.ctrlKey) mods.push(e.code === "ControlRight" ? "rctrl" : "ctrl");
      if (e.altKey) mods.push("alt");
      if (e.shiftKey) mods.push("shift");
      return mods;
    };

    const applyHeld = (heldNow: KeyId[]) => {
      setHeld(heldNow);
      setActiveKeys(new Set(heldNow));
      const matches = BINDINGS.filter((b) => bindingMatchesHeld(heldNow, b.keyIds));
      const exact = matches.filter((b) => b.keyIds.length === heldNow.length);
      const hit = exact.length ? exact : matches;
      setFlashIds(new Set(hit.map((b) => b.id)));
    };

    const down = (e: KeyboardEvent) => {
      if (isTypingTarget(e)) return;
      e.preventDefault();
      const ids = eventToKeyIds(e);
      const mods = modsFrom(e);
      const nonMods = ids.filter(
        (k) => !["super", "shift", "ctrl", "alt", "rctrl"].includes(k)
      );
      applyHeld([...new Set([...mods, ...nonMods])]);
    };

    const up = (e: KeyboardEvent) => {
      if (isTypingTarget(e)) return;
      const mods = modsFrom(e);
      applyHeld(mods);
      if (mods.length === 0) setFlashIds(new Set());
    };

    window.addEventListener("keydown", down);
    window.addEventListener("keyup", up);
    return () => {
      window.removeEventListener("keydown", down);
      window.removeEventListener("keyup", up);
    };
  }, [listen]);

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: BINDINGS.length };
    for (const cat of CATEGORIES) {
      c[cat.id] = BINDINGS.filter((b) => b.category === cat.id).length;
    }
    return c;
  }, []);

  return (
    <div className="mx-auto flex w-full max-w-7xl flex-col gap-6 px-4 py-6 sm:px-6 lg:px-8">
      {/* Header */}
      <header className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-[11px] font-medium uppercase tracking-[0.25em] text-tn-magenta">
            Hyprland · Tokyo Night rice · Next.js
          </p>
          <h1 className="mt-1 bg-gradient-to-r from-tn-blue via-tn-cyan to-tn-magenta bg-clip-text text-3xl font-bold tracking-tight text-transparent sm:text-4xl">
            hyprriceitsnice
          </h1>
          <p className="mt-2 max-w-xl text-sm text-muted">
            Interactive cheat sheet for{" "}
            <code className="rounded bg-tn-bg-dark px-1.5 py-0.5 font-mono text-[12px] text-tn-cyan">
              ~/.config/hypr
            </code>
            . Search, filter, hover to light keys, click to copy. Toggle listen mode to flash matching binds.
          </p>
          <div className="mt-3 flex flex-wrap gap-2 text-[11px]">
            <span className="rounded-full border border-tn-blue/50 bg-tn-blue/15 px-2.5 py-1 font-medium text-tn-blue">
              Next.js app
            </span>
            <a
              href="/hyprriceitsnice.html"
              className="rounded-full border border-tn-border bg-card px-2.5 py-1 text-muted transition hover:border-tn-magenta/50 hover:text-tn-magenta"
            >
              Standalone HTML →
            </a>
            <span className="rounded-full border border-tn-border/60 px-2.5 py-1 text-muted/70">
              also cheatsheet.md
            </span>
          </div>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <button
            type="button"
            onClick={() => setListen((v) => !v)}
            className={`rounded-lg border px-3 py-2 text-xs font-semibold transition ${
              listen
                ? "glow-border border-tn-green/60 bg-tn-green/15 text-tn-green"
                : "border-tn-border bg-card text-foreground/80 hover:border-tn-blue/50"
            }`}
          >
            {listen ? "● Listen on" : "○ Listen mode"}
          </button>
          <span className="rounded-lg border border-tn-border bg-card px-3 py-2 text-[11px] text-muted">
            {filtered.length} / {BINDINGS.length} binds
          </span>
        </div>
      </header>

      {/* Search + filters */}
      <div className="sticky top-0 z-20 -mx-1 space-y-3 rounded-xl border border-tn-border/80 bg-tn-bg-dark/85 p-3 backdrop-blur-md">
        <div className="relative">
          <input
            ref={searchRef}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search binds, apps, tags…  (Ctrl/⌘+K)"
            className="w-full rounded-lg border border-tn-border bg-background/80 py-2.5 pl-3 pr-20 text-sm text-foreground placeholder:text-muted focus:border-tn-blue focus:outline-none focus:ring-2 focus:ring-[var(--ring)]"
            aria-label="Search keybindings"
          />
          <kbd className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 rounded border border-tn-border bg-card px-1.5 py-0.5 font-mono text-[10px] text-muted">
            ⌘K
          </kbd>
        </div>
        <div className="flex gap-1.5 overflow-x-auto scroll-thin pb-0.5">
          <FilterChip
            active={category === "all"}
            onClick={() => setCategory("all")}
            label="All"
            count={counts.all}
          />
          {CATEGORIES.map((c) => (
            <FilterChip
              key={c.id}
              active={category === c.id}
              onClick={() => setCategory(c.id)}
              label={`${c.emoji} ${c.label}`}
              count={counts[c.id] ?? 0}
            />
          ))}
        </div>
      </div>

      {listen && (
        <div className="rounded-lg border border-tn-green/40 bg-tn-green/10 px-3 py-2 text-xs text-tn-green">
          Listen mode: press combos outside the search box. Matching rows flash green.
          Held:{" "}
          <span className="font-mono">
            {held.length ? held.map((k) => k.toUpperCase()).join(" + ") : "—"}
          </span>
        </div>
      )}

      {/* Keyboard + side meta */}
      <div className="grid gap-4 xl:grid-cols-[1.4fr_1fr]">
        <Keyboard active={activeKeys} />
        <aside className="flex flex-col gap-3">
          <MetaCard title="Default apps">
            <dl className="space-y-1.5">
              {APPS.map((a) => (
                <div key={a.key} className="flex justify-between gap-2 text-[12px]">
                  <dt className="font-mono text-muted">{a.key}</dt>
                  <dd className="text-tn-cyan">{a.value}</dd>
                </div>
              ))}
            </dl>
          </MetaCard>
          <MetaCard title="Rice">
            <dl className="space-y-1.5 text-[12px]">
              <Row k="Layout" v={RICE.layout} />
              <Row k="Gaps" v={RICE.gaps} />
              <Row k="Border" v={RICE.border} />
              <Row k="Active" v={RICE.activeBorder} />
              <Row k="Blur" v={RICE.blur} />
              <Row k="Theme" v={RICE.theme} />
            </dl>
            <div className="mt-3 h-2 overflow-hidden rounded-full bg-tn-bg-dark">
              <div
                className="h-full w-full"
                style={{
                  background: "linear-gradient(90deg, #7aa2f7, #bb9af7)",
                }}
              />
            </div>
          </MetaCard>
          <MetaCard title="Autostart">
            <ul className="space-y-1 text-[12px] text-foreground/85">
              {AUTOSTART.map((s) => (
                <li key={s} className="flex gap-2">
                  <span className="text-tn-blue">▹</span>
                  {s}
                </li>
              ))}
            </ul>
          </MetaCard>
        </aside>
      </div>

      <MonitorMap />

      {/* Bindings list */}
      <section className="space-y-6">
        {filtered.length === 0 && (
          <div className="rounded-xl border border-dashed border-tn-border px-4 py-12 text-center text-sm text-muted">
            No binds match “{query}”.
          </div>
        )}

        {(category === "all" ? CATEGORIES : CATEGORIES.filter((c) => c.id === category)).map(
          (cat) => {
            const items = byCategory.get(cat.id);
            if (!items?.length) return null;
            return (
              <div key={cat.id} id={cat.id} className="scroll-mt-28">
                <div className="mb-2 flex items-baseline justify-between gap-2">
                  <h2 className="text-sm font-semibold tracking-wide">
                    <span className="mr-1.5">{cat.emoji}</span>
                    {cat.label}
                    <span className="ml-2 text-[11px] font-normal text-muted">
                      {cat.description}
                    </span>
                  </h2>
                  <span className="text-[11px] text-muted">{items.length}</span>
                </div>
                <div className="grid gap-2 sm:grid-cols-2">
                  {items.map((b) => (
                    <BindingRow
                      key={b.id}
                      binding={b}
                      hot={flashIds.has(b.id)}
                      hover={!listen && b.keyIds.some((k) => activeKeys.has(k)) && activeKeys.size > 0 && b.keyIds.every((k) => activeKeys.has(k))}
                      copied={copiedId === b.id}
                      onHover={onHover}
                      onLeave={onLeave}
                      onCopy={onCopy}
                    />
                  ))}
                </div>
              </div>
            );
          }
        )}
      </section>

      <footer className="border-t border-tn-border/60 pt-4 pb-8 text-center text-[11px] text-muted">
        Sourced from{" "}
        <code className="text-tn-cyan">hyprland.conf</code> +{" "}
        <code className="text-tn-cyan">ai-workspace-extension.conf</code>
        . SUPER+SHIFT+Q exit is intentionally disabled. SUPER+Space is the launcher (later bind wins).
      </footer>
    </div>
  );
}

function FilterChip({
  active,
  onClick,
  label,
  count,
}: {
  active: boolean;
  onClick: () => void;
  label: string;
  count: number;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-medium transition ${
        active
          ? "border-tn-blue/70 bg-tn-blue/15 text-tn-blue"
          : "border-tn-border bg-card text-muted hover:border-tn-blue/40 hover:text-foreground"
      }`}
    >
      {label}
      <span className={`ml-1.5 ${active ? "text-tn-blue/70" : "text-muted/70"}`}>{count}</span>
    </button>
  );
}

function MetaCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-xl border border-tn-border bg-card/70 p-3">
      <h3 className="mb-2 text-[10px] font-semibold uppercase tracking-[0.18em] text-muted">
        {title}
      </h3>
      {children}
    </div>
  );
}

function Row({ k, v }: { k: string; v: string }) {
  return (
    <div className="flex justify-between gap-3">
      <dt className="text-muted">{k}</dt>
      <dd className="text-right text-foreground/85">{v}</dd>
    </div>
  );
}
