"use client";

import { useEffect, useState } from "react";
import { isLoggedIn, getUser, logout, startLogin } from "@/lib/auth";

function CodeFreshLogo({ size = 20 }: { size?: number }) {
  return (
    <svg viewBox="0 0 16 16" width={size} height={size} xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <rect x="2" y="3" width="12" height="10" rx="2.5" fill="#D4915E" />
      <circle cx="8" cy="8" r="1.5" fill="#08090D" />
    </svg>
  );
}

export default function DashboardPage() {
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
      <div className="min-h-screen bg-background flex items-center justify-center">
        <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-text-tertiary">
          Loading...
        </p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Nav */}
      <header className="sticky top-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-3">
          <a href="/" className="inline-flex items-center gap-2 transition-opacity hover:opacity-80">
            <CodeFreshLogo size={20} />
            <span className="font-sans text-sm font-semibold tracking-tight">
              codefre<span className="text-accent">.</span>sh
            </span>
          </a>
          <div className="flex items-center gap-4">
            {user?.email && (
              <span className="font-mono text-[11px] text-text-tertiary">
                {user.email}
              </span>
            )}
            <button
              onClick={logout}
              className="font-mono text-[11px] uppercase tracking-[0.08em] text-text-tertiary hover:text-eval-fail transition-colors"
            >
              Sign Out
            </button>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="mx-auto max-w-6xl px-6 py-10">
        <div className="mb-8">
          <p className="font-mono text-[9px] text-text-tertiary uppercase tracking-[0.2em] mb-2">
            Dashboard
          </p>
          <h1 className="text-[32px] font-bold tracking-tight text-text-primary">
            {user?.name ? `Welcome, ${user.name}` : "Welcome"}
          </h1>
        </div>

        {/* Empty state */}
        <div className="rounded-[6px] border-[1.5px] border-border bg-surface p-16 text-center">
          <div className="inline-block mb-8">
            <CodeFreshLogo size={48} />
          </div>
          <h2 className="text-xl font-semibold text-text-primary mb-3">
            No test scripts yet
          </h2>
          <p className="text-sm text-text-secondary max-w-sm mx-auto mb-8">
            Create your first conversation script to start testing your AI agents.
          </p>
          <button
            disabled
            className="font-mono text-[11px] font-medium uppercase tracking-[0.08em] px-8 py-3.5 bg-elevated text-text-tertiary rounded-md cursor-not-allowed"
          >
            + New Script &mdash; Coming Soon
          </button>
        </div>

        {/* Pipeline phases */}
        <div className="mt-12 grid grid-cols-4 gap-px bg-border">
          {["Script", "Run", "Evaluate", "Report"].map((phase, i) => (
            <div key={phase} className="bg-surface py-4 text-center">
              <div className="font-mono text-[8px] text-text-tertiary tracking-[0.2em] mb-1">
                {String(i + 1).padStart(2, "0")}
              </div>
              <div className="font-sans text-xs font-semibold uppercase tracking-[0.06em] text-text-tertiary">
                {phase}
              </div>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer className="mx-auto max-w-6xl px-6 py-8 border-t border-border">
        <div className="font-mono text-[9px] text-text-tertiary uppercase tracking-[0.2em] text-center">
          codefre.sh &middot; Behavioral Testing for AI Agents &middot; 2026
        </div>
      </footer>
    </div>
  );
}
