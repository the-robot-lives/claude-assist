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
      <div className="min-h-screen bg-background flex items-center justify-center font-mono">
        <p className="text-[11px] font-bold uppercase tracking-widest text-text-tertiary">
          Loading...
        </p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background font-mono">
      {/* Nav */}
      <header className="sticky top-0 z-50 border-b-2 border-border bg-background">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-3">
          <a
            href="/"
            className="flex items-center gap-2 text-sm font-bold uppercase tracking-widest"
          >
            <svg
              viewBox="0 0 200 200"
              className="h-6 w-6 text-accent"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fillRule="evenodd"
                d="M 100,28 A 72,72 0 1,1 99.999,28 Z M 100,50 A 50,50 0 1,0 99.999,50 Z"
              />
              <polygon points="82,66 82,134 152,100" />
            </svg>
            IOT<span className="text-accent">GO</span>
          </a>
          <div className="flex items-center gap-4">
            {user?.email && (
              <span className="text-[11px] text-text-tertiary">
                {user.email}
              </span>
            )}
            <button
              onClick={logout}
              className="text-[11px] font-bold uppercase tracking-widest text-text-tertiary hover:text-critical transition-colors duration-100"
            >
              Sign Out
            </button>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="mx-auto max-w-6xl px-6 py-10">
        <div className="mb-3">
          <p className="text-[11px] font-bold uppercase tracking-[0.08em] text-text-tertiary">
            DASHBOARD
          </p>
        </div>
        <h1 className="font-[family-name:var(--font-space-grotesk)] text-2xl font-bold tracking-tight sm:text-3xl">
          {user?.name ? `Welcome, ${user.name}` : "Welcome"}
        </h1>

        {/* Empty state */}
        <div className="mt-10 border-2 border-border bg-surface p-16 text-center">
          <div className="inline-flex h-16 w-16 items-center justify-center border-2 border-border mb-6">
            <svg
              viewBox="0 0 200 200"
              className="h-8 w-8 text-text-tertiary"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fillRule="evenodd"
                d="M 100,28 A 72,72 0 1,1 99.999,28 Z M 100,50 A 50,50 0 1,0 99.999,50 Z"
              />
              <polygon points="82,66 82,134 152,100" />
            </svg>
          </div>

          <h2 className="text-lg font-bold tracking-tight mb-2">
            No fleets connected
          </h2>
          <p className="text-[13px] text-text-secondary max-w-sm mx-auto mb-8">
            Connect your first IoT fleet to start monitoring devices with autonomous AI agents.
          </p>
          <button
            disabled
            className="text-[11px] font-bold uppercase tracking-widest px-6 py-3 border-2 border-border text-text-tertiary cursor-not-allowed"
          >
            + Connect Fleet &mdash; Coming Soon
          </button>
        </div>

        {/* Autonomy levels */}
        <div className="mt-10 grid grid-cols-5 gap-0 border-2 border-border">
          {["Observer", "Advisor", "Supervised", "Autonomous", "Adaptive"].map((level, i) => (
            <div key={level} className="border border-border bg-surface py-4 text-center">
              <div className="text-[10px] font-bold text-text-tertiary tracking-[0.2em] mb-1">
                L{i}
              </div>
              <div className="text-[11px] font-bold uppercase tracking-wider text-text-tertiary">
                {level}
              </div>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t-2 border-border px-6 py-6">
        <div className="mx-auto max-w-5xl text-center">
          <span className="text-[11px] uppercase tracking-widest text-text-tertiary">
            &copy; 2026 IOTGO.IO
          </span>
        </div>
      </footer>
    </div>
  );
}
