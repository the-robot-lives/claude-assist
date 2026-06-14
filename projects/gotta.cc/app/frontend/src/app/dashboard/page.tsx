"use client";

import { useEffect, useState } from "react";
import { isLoggedIn, getUser, logout, startLogin } from "@/lib/auth";

function AsteriskMark({ className = "h-7 w-7" }: { className?: string }) {
  return (
    <svg
      className={`shrink-0 ${className}`}
      viewBox="0 0 200 200"
      aria-hidden="true"
    >
      <g transform="translate(100,100)" style={{ fill: "var(--coral)" }}>
        <rect x="-8" y="-65" width="16" height="130" rx="8" />
        <rect x="-8" y="-65" width="16" height="130" rx="8" transform="rotate(60)" />
        <rect x="-8" y="-65" width="16" height="130" rx="8" transform="rotate(120)" />
      </g>
    </svg>
  );
}

export default function Dashboard() {
  const [user, setUser] = useState<{ email?: string; name?: string } | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!isLoggedIn()) {
      startLogin();
      return;
    }
    setUser(getUser());
    setReady(true);
  }, []);

  if (!ready) {
    return (
      <div className="min-h-screen bg-cream flex items-center justify-center">
        <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
          Loading...
        </p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-cream">
      {/* Nav */}
      <header className="sticky top-0 z-50 border-b border-rule bg-cream/95 backdrop-blur-sm">
        <div className="mx-auto flex max-w-[960px] items-center justify-between px-6 py-4">
          <a href="/" className="flex items-center gap-2.5">
            <AsteriskMark className="h-7 w-7" />
            <span
              className="font-display text-2xl font-bold text-ink"
              style={{ fontVariationSettings: "'WONK' 1" }}
            >
              gotta.cc
            </span>
          </a>
          <div className="flex items-center gap-4">
            {user?.email && (
              <span className="font-mono text-[11px] text-ink-tertiary">
                {user.email}
              </span>
            )}
            <button
              onClick={logout}
              className="font-mono text-[11px] uppercase tracking-[0.06em] text-ink-tertiary hover:text-error transition-colors"
            >
              Sign Out
            </button>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="mx-auto max-w-[960px] px-6 py-10">
        <div className="mb-8">
          <p className="font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive mb-2">
            Dashboard
          </p>
          <h1
            className="font-display text-[clamp(28px,4vw,40px)] font-semibold leading-tight tracking-tight text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            {user?.name ? `Welcome, ${user.name}` : "Welcome"}
          </h1>
        </div>

        {/* Empty state */}
        <div className="rounded-2xl bg-surface p-16 text-center shadow-[0_2px_8px_rgba(0,0,0,0.06)]">
          <div className="inline-block relative mb-8">
            <AsteriskMark className="h-12 w-12" />
          </div>

          <h2
            className="font-display text-2xl font-semibold text-ink mb-3"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            No collections yet
          </h2>
          <p className="font-body text-sm text-ink-secondary max-w-sm mx-auto mb-8 leading-relaxed">
            Save your favorite sites, build curated collections, and submit new discoveries to the directory.
          </p>
          <button
            disabled
            className="font-ui text-xs font-semibold uppercase tracking-[0.06em] px-8 py-3.5 bg-sunken text-ink-tertiary rounded-xl cursor-not-allowed"
          >
            + New Collection &mdash; Coming Soon
          </button>
        </div>

        {/* Pipeline key */}
        <div className="mt-12 grid grid-cols-5 gap-px bg-rule rounded-2xl overflow-hidden">
          {["Discover", "Score", "Curate", "Collect", "Share"].map((phase, i) => (
            <div key={phase} className="bg-surface py-4 text-center">
              <div className="font-mono text-[9px] text-ink-tertiary tracking-[0.2em] mb-1">
                {String(i + 1).padStart(2, "0")}
              </div>
              <div
                className="font-display text-sm font-semibold uppercase tracking-[0.04em] text-ink-tertiary"
                style={{ fontVariationSettings: "'WONK' 1" }}
              >
                {phase}
              </div>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-rule px-6 py-6">
        <div className="mx-auto flex max-w-[960px] items-center justify-center">
          <span className="flex items-center gap-1.5 font-ui text-xs text-ink-tertiary">
            <AsteriskMark className="h-3.5 w-3.5" />
            &copy; 2026 gotta.cc
          </span>
        </div>
      </footer>
    </div>
  );
}
