"use client";

import { useEffect, useState } from "react";
import { isLoggedIn, getUser, logout, startLogin } from "@/lib/auth";

export default function Dashboard() {
  const [user, setUser] = useState<{ email?: string; name?: string } | null>(
    null,
  );
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
      <div className="bp-root min-h-screen flex items-center justify-center">
        <p className="font-mono text-[11px] uppercase tracking-[0.12em] text-[var(--line-secondary)]">
          Loading...
        </p>
      </div>
    );
  }

  return (
    <div className="bp-root min-h-screen font-body">
      {/* NAV */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-[var(--bp-deep)] border-b border-[var(--bp-border)]">
        <div className="max-w-[960px] mx-auto px-10 h-12 flex items-center justify-between">
          <a
            href="/"
            className="font-label text-lg font-semibold uppercase tracking-[0.08em] text-[var(--line-bright)] hover:text-[var(--anno-yellow)] transition-colors"
          >
            TheRobotMakes
          </a>
          <div className="flex items-center gap-6">
            {user?.email && (
              <span className="font-mono text-[10px] text-[var(--line-secondary)]">
                {user.email}
              </span>
            )}
            <button
              onClick={logout}
              className="font-mono text-[10px] uppercase tracking-[0.1em] text-[var(--line-dim)] hover:text-[var(--redline)] transition-colors"
            >
              Sign Out
            </button>
          </div>
        </div>
      </nav>

      {/* DASHBOARD */}
      <main className="max-w-[960px] mx-auto px-10 pt-28 pb-20">
        <div className="mb-12">
          <div className="font-mono text-[9px] text-[var(--line-dim)] uppercase tracking-[0.2em] mb-2">
            Dashboard
          </div>
          <h1 className="font-label text-4xl font-light uppercase tracking-[0.04em] text-[var(--line-bright)]">
            {user?.name ? `Welcome, ${user.name}` : "Welcome"}
          </h1>
        </div>

        {/* Empty state */}
        <div className="border border-[var(--bp-border)] bg-[var(--bp-surface)] rounded-sm p-16 text-center">
          <div className="inline-block relative mb-8">
            <div className="w-20 h-20 border border-[var(--bp-border-lt)] rounded-full relative">
              <div className="absolute top-1/2 left-0 right-0 h-px bg-[var(--bp-border-lt)]" />
              <div className="absolute left-1/2 top-0 bottom-0 w-px bg-[var(--bp-border-lt)]" />
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-2 h-2 rounded-full bg-[var(--anno-yellow)]" />
            </div>
          </div>

          <h2 className="font-label text-2xl font-light uppercase tracking-[0.06em] text-[var(--line-primary)] mb-3">
            No projects yet
          </h2>
          <p className="font-body text-sm text-[var(--line-secondary)] max-w-sm mx-auto mb-8">
            Start with a pitch. The robots will take it from there.
          </p>
          <button
            disabled
            className="font-mono text-[11px] font-medium uppercase tracking-[0.12em] px-8 py-3.5 bg-[var(--bp-border)] text-[var(--line-dim)] rounded-sm cursor-not-allowed"
          >
            + New Project &mdash; Coming Soon
          </button>
        </div>

        {/* Pipeline key */}
        <div className="mt-12 grid grid-cols-5 gap-px bg-[var(--bp-border)]">
          {["Pitch", "Plan", "Build", "Release", "Refine"].map((phase, i) => (
            <div
              key={phase}
              className="bg-[var(--bp-surface)] py-4 text-center"
            >
              <div className="font-mono text-[8px] text-[var(--line-ghost)] tracking-[0.2em] mb-1">
                {String(i + 1).padStart(2, "0")}
              </div>
              <div className="font-label text-sm font-light uppercase tracking-[0.1em] text-[var(--line-dim)]">
                {phase}
              </div>
            </div>
          ))}
        </div>
      </main>

      {/* FOOTER */}
      <footer className="max-w-[960px] mx-auto px-10 py-8 border-t border-[var(--bp-border)]">
        <div className="font-mono text-[9px] text-[var(--line-ghost)] uppercase tracking-[0.2em] text-center">
          TheRobotMakes &middot; Robot-Assisted SDLC &middot; 2026
        </div>
      </footer>
    </div>
  );
}
