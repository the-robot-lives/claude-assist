"use client";

import { useEffect, useState } from "react";
import { isLoggedIn, getUser, logout, startLogin } from "@/lib/auth";

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
      <div className="min-h-screen bg-background flex items-center justify-center">
        <p className="font-mono text-[11px] uppercase tracking-widest text-text-tertiary">
          Loading...
        </p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background font-sans">
      {/* Nav */}
      <nav className="sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur-md">
        <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-6">
          <a
            href="/"
            className="font-mono text-sm font-bold tracking-tight text-text-primary"
            style={{ letterSpacing: "-0.02em" }}
          >
            JAILBREAKING<span className="text-critical">SITE</span>
          </a>
          <div className="flex items-center gap-4">
            {user?.email && (
              <span className="font-mono text-[11px] text-text-tertiary">
                {user.email}
              </span>
            )}
            <button
              onClick={logout}
              className="font-mono text-[11px] font-bold uppercase tracking-widest text-text-tertiary hover:text-critical transition-colors duration-100"
            >
              Sign Out
            </button>
          </div>
        </div>
      </nav>

      {/* Content */}
      <main className="mx-auto max-w-5xl px-6 py-16">
        <div className="mb-3">
          <p className="font-mono text-[11px] font-bold uppercase tracking-[0.08em] text-accent">
            DASHBOARD
          </p>
        </div>
        <h1 className="font-mono text-2xl font-bold tracking-tight sm:text-3xl">
          {user?.name ? `Welcome, ${user.name}` : "Welcome"}
        </h1>

        {/* Empty state */}
        <div className="mt-10 overflow-hidden rounded border border-border bg-surface p-16 text-center">
          <div className="inline-block rounded border border-border-strong bg-elevated px-3 py-1.5 mb-6">
            <span className="font-mono text-[10px] font-bold uppercase tracking-[0.1em] text-accent">
              BETA
            </span>
          </div>

          <h2 className="font-mono text-lg font-bold mb-3">
            No scans yet
          </h2>
          <p className="text-[13px] text-text-secondary max-w-md mx-auto mb-8 leading-relaxed">
            Configure your first LLM endpoint to start running attack suites and generating security reports.
          </p>
          <button
            disabled
            className="rounded bg-elevated px-6 py-3 font-mono text-[11px] font-bold uppercase tracking-widest text-text-tertiary cursor-not-allowed border border-border"
          >
            + New Scan &mdash; Coming Soon
          </button>
        </div>

        {/* Severity legend */}
        <div className="mt-10 grid grid-cols-5 gap-px bg-border">
          {[
            { label: "CRITICAL", color: "text-critical", bar: "bg-critical" },
            { label: "HIGH", color: "text-high", bar: "bg-high" },
            { label: "MEDIUM", color: "text-medium", bar: "bg-medium" },
            { label: "LOW", color: "text-low", bar: "bg-low" },
            { label: "PASS", color: "text-pass", bar: "bg-pass" },
          ].map((s) => (
            <div key={s.label} className="bg-surface py-4 text-center">
              <div className={`h-1 w-8 mx-auto mb-2 ${s.bar}`} />
              <div className={`font-mono text-[10px] font-bold uppercase tracking-widest ${s.color}`}>
                {s.label}
              </div>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-border px-6 py-6">
        <div className="mx-auto max-w-5xl text-center">
          <span className="font-mono text-[11px] uppercase tracking-widest text-text-tertiary">
            &copy; 2026 JAILBREAKINGSITE.COM
          </span>
        </div>
      </footer>
    </div>
  );
}
