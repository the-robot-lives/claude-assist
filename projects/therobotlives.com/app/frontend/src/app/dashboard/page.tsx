"use client";

import { useEffect, useState } from "react";
import { isLoggedIn, getUser, logout, startLogin } from "@/lib/auth";

export default function DashboardPage() {
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
      <div className="flex min-h-screen items-center justify-center bg-background">
        <div
          className="h-5 w-5 rounded-full border-2 border-accent border-t-transparent animate-spin"
        />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Nav */}
      <nav className="sticky top-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-6 py-3">
          <a href="/" className="flex items-center gap-2">
            <span
              className="flex h-6 w-6 items-center justify-center rounded-md text-xs"
              style={{ background: "var(--accent)", color: "#080B14" }}
            >
              R
            </span>
            <span className="text-sm font-semibold tracking-tight">
              <span className="text-text-tertiary">the</span>
              <span className="text-accent">robot</span>
              <span>lives</span>
            </span>
          </a>
          <div className="flex items-center gap-4">
            <span className="font-mono text-xs text-text-secondary">
              {user?.email ?? "User"}
            </span>
            <button
              onClick={logout}
              className="rounded-lg border border-border px-3 py-1 text-xs text-text-secondary transition-colors hover:border-error hover:text-error"
            >
              Sign Out
            </button>
          </div>
        </div>
      </nav>

      {/* Content */}
      <main className="mx-auto max-w-5xl px-6 py-16">
        <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
        <p className="mt-2 text-sm text-text-secondary">
          Welcome back, {user?.name || user?.email || "explorer"}.
        </p>

        {/* Empty state */}
        <div className="mt-12 flex flex-col items-center rounded-2xl border border-dashed border-border bg-surface p-12 text-center">
          <div
            className="mb-4 flex h-14 w-14 items-center justify-center rounded-full"
            style={{ background: "var(--accent-muted)" }}
          >
            <span className="text-2xl">🤖</span>
          </div>
          <h2 className="text-base font-semibold">No activity yet</h2>
          <p className="mt-2 max-w-sm text-sm text-text-secondary">
            Spaces, agents, and resources will appear here once the platform
            launches. Stay tuned.
          </p>
          <div className="mt-6 flex gap-3">
            <div className="rounded-lg border border-border bg-elevated px-4 py-2">
              <span className="font-mono text-[11px] text-text-tertiary uppercase tracking-wider">
                Spaces
              </span>
              <p className="mt-1 text-lg font-semibold text-accent">0</p>
            </div>
            <div className="rounded-lg border border-border bg-elevated px-4 py-2">
              <span className="font-mono text-[11px] text-text-tertiary uppercase tracking-wider">
                Agents
              </span>
              <p className="mt-1 text-lg font-semibold text-neural">0</p>
            </div>
            <div className="rounded-lg border border-border bg-elevated px-4 py-2">
              <span className="font-mono text-[11px] text-text-tertiary uppercase tracking-wider">
                Resources
              </span>
              <p className="mt-1 text-lg font-semibold text-accent-warm">0</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
