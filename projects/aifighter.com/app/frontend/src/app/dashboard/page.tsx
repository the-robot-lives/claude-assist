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
      <div className="min-h-screen bg-[var(--void-deep)] flex items-center justify-center">
        <p className="font-[var(--font-data)] text-[11px] uppercase tracking-[0.12em] text-[var(--text-secondary)]">
          Loading...
        </p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[var(--void-deep)]">
      {/* NAV */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-[var(--void-deep)] border-b border-[var(--void-border)]">
        <div className="max-w-[960px] mx-auto px-6 h-12 flex items-center justify-between">
          <a
            href="/"
            className="flex items-center gap-2 text-[var(--text-primary)] hover:text-[var(--synapse)] transition-colors"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="22" height="22" aria-hidden="true">
              <polygon points="38,100 82,35 82,165" fill="#FF3366"/>
              <polygon points="162,100 118,35 118,165" fill="#00FFAA"/>
              <circle cx="100" cy="100" r="10" fill="#FFFFFF"/>
            </svg>
            <span className="font-[var(--font-display)] text-sm font-bold uppercase tracking-[0.08em]">
              AI Fighter
            </span>
          </a>
          <div className="flex items-center gap-6">
            {user?.email && (
              <span className="font-[var(--font-data)] text-[10px] text-[var(--text-secondary)]">
                {user.email}
              </span>
            )}
            <button
              onClick={logout}
              className="font-[var(--font-data)] text-[10px] uppercase tracking-[0.1em] text-[var(--text-dim)] hover:text-[var(--combat)] transition-colors"
            >
              Sign Out
            </button>
          </div>
        </div>
      </nav>

      {/* DASHBOARD */}
      <main className="max-w-[960px] mx-auto px-6 pt-28 pb-20">
        <div className="mb-12">
          <div className="font-[var(--font-data)] text-[9px] text-[var(--text-dim)] uppercase tracking-[0.2em] mb-2">
            Command Center
          </div>
          <h1 className="font-[var(--font-display)] text-4xl font-bold uppercase tracking-[0.02em] text-[var(--text-primary)]">
            {user?.name ? `Welcome, ${user.name}` : "Welcome, Fighter"}
          </h1>
        </div>

        {/* Empty state */}
        <div className="border border-[var(--void-border)] bg-[var(--void-surface)] rounded-sm p-16 text-center">
          <div className="inline-block relative mb-8">
            <div className="w-20 h-20 border border-[var(--void-border)] rounded-full relative">
              <div className="absolute top-1/2 left-0 right-0 h-px bg-[var(--void-border)]" />
              <div className="absolute left-1/2 top-0 bottom-0 w-px bg-[var(--void-border)]" />
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-2 h-2 rounded-full bg-[var(--synapse)]" />
            </div>
          </div>

          <h2 className="font-[var(--font-display)] text-2xl font-bold uppercase tracking-[0.04em] text-[var(--text-primary)] mb-3">
            No fighters yet
          </h2>
          <p className="text-sm text-[var(--text-secondary)] max-w-sm mx-auto mb-8">
            Wire your first neural network. Design the brain. Enter the arena.
          </p>
          <button
            disabled
            className="font-[var(--font-data)] text-[11px] font-medium uppercase tracking-[0.12em] px-8 py-3.5 bg-[var(--void-border)] text-[var(--text-dim)] rounded-sm cursor-not-allowed"
          >
            + New Fighter &mdash; Coming Soon
          </button>
        </div>

        {/* Pipeline key */}
        <div className="mt-12 grid grid-cols-4 gap-px bg-[var(--void-border)]">
          {["Design", "Train", "Battle", "Rank"].map((phase, i) => (
            <div
              key={phase}
              className="bg-[var(--void-surface)] py-4 text-center"
            >
              <div className="font-[var(--font-data)] text-[8px] text-[var(--text-dim)] tracking-[0.2em] mb-1">
                {String(i + 1).padStart(2, "0")}
              </div>
              <div className="font-[var(--font-display)] text-sm font-bold uppercase tracking-[0.1em] text-[var(--text-dim)]">
                {phase}
              </div>
            </div>
          ))}
        </div>
      </main>

      {/* FOOTER */}
      <footer className="max-w-[960px] mx-auto px-6 py-8 border-t border-[var(--void-border)]">
        <div className="font-[var(--font-data)] text-[9px] text-[var(--text-dim)] uppercase tracking-[0.2em] text-center">
          AI Fighter &middot; Neural Combat &middot; 2026
        </div>
      </footer>
    </div>
  );
}
