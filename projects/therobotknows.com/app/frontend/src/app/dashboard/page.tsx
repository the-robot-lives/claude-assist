"use client";

import { useEffect, useState } from "react";
import { isLoggedIn, getUser, logout, startLogin } from "@/lib/auth";
import { KnowledgeBaseLogo } from "@/components/layout/knowledge-base-logo";

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
      <div className="min-h-screen bg-page flex items-center justify-center">
        <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
          Loading...
        </p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-page">
      {/* Nav */}
      <header className="sticky top-0 z-10 bg-surface/95 backdrop-blur-sm border-b border-rule-subtle">
        <div className="max-w-6xl mx-auto px-6 h-14 flex items-center gap-3">
          <a href="/" className="flex items-center gap-2.5 shrink-0">
            <KnowledgeBaseLogo size={28} className="text-ink" />
            <span className="font-serif text-[15px] font-semibold tracking-[0.04em] text-ink uppercase">
              Knowledge Base
            </span>
          </a>
          <div className="flex-1" />
          <div className="flex items-center gap-4">
            {user?.email && (
              <span className="font-mono text-[11px] text-ink-tertiary">
                {user.email}
              </span>
            )}
            <button
              onClick={logout}
              className="font-mono text-[11px] uppercase tracking-[0.06em] text-ink-tertiary hover:text-[var(--flag-error)] transition-colors"
            >
              Sign Out
            </button>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-6xl mx-auto px-6 py-10">
        <div className="mb-8">
          <p className="font-mono text-[9px] text-ink-tertiary uppercase tracking-[0.2em] mb-2">
            Dashboard
          </p>
          <h1 className="font-serif text-[32px] font-bold text-ink leading-tight tracking-[-0.01em]">
            {user?.name ? `Welcome, ${user.name}` : "Welcome"}
          </h1>
        </div>

        {/* Empty state */}
        <div className="border border-rule bg-surface rounded-xl p-16 text-center">
          <div className="inline-block relative mb-8">
            <KnowledgeBaseLogo size={48} className="text-ink-tertiary" />
          </div>

          <h2 className="font-serif text-[24px] font-semibold text-ink mb-3">
            No universes yet
          </h2>
          <p className="font-sans text-[14px] text-ink-secondary max-w-sm mx-auto mb-8">
            Create your first universe to start building a living, cross-referenced knowledge base.
          </p>
          <button
            disabled
            className="font-mono text-[11px] font-medium uppercase tracking-[0.08em] px-8 py-3.5 bg-elevated text-ink-tertiary rounded-lg cursor-not-allowed"
          >
            + New Universe &mdash; Coming Soon
          </button>
        </div>

        {/* Pipeline key */}
        <div className="mt-12 grid grid-cols-5 gap-px bg-rule">
          {["Create", "Populate", "Connect", "Validate", "Publish"].map((phase, i) => (
            <div key={phase} className="bg-surface py-4 text-center">
              <div className="font-mono text-[8px] text-ink-tertiary tracking-[0.2em] mb-1">
                {String(i + 1).padStart(2, "0")}
              </div>
              <div className="font-serif text-sm font-semibold uppercase tracking-[0.06em] text-ink-tertiary">
                {phase}
              </div>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer className="max-w-6xl mx-auto px-6 py-8 border-t border-rule-subtle">
        <div className="font-mono text-[9px] text-ink-tertiary uppercase tracking-[0.2em] text-center">
          TheRobotKnows &middot; AI-Powered Knowledge Base &middot; 2026
        </div>
      </footer>
    </div>
  );
}
