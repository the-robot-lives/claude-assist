"use client";

import { useEffect, useState } from "react";
import { isLoggedIn, getUser, logout, startLogin } from "@/lib/auth";
import { Logomark } from "@/components/Logo";

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
      <div className="min-h-screen bg-zinc-950 flex items-center justify-center">
        <p className="text-sm text-zinc-400 font-mono">Loading...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-zinc-950">
      {/* Nav */}
      <header className="sticky top-0 z-50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex h-14 sm:h-16 items-center justify-between mt-2 rounded-2xl glass px-4 sm:px-6">
            <a href="/" className="flex items-center gap-3">
              <Logomark className="h-8 w-8" />
              <div className="flex items-baseline gap-1.5">
                <span className="font-semibold text-white text-lg tracking-tight">
                  noizu
                </span>
                <span className="text-sm font-medium text-gold-400">Labs</span>
              </div>
            </a>
            <div className="flex items-center gap-4">
              {user?.email && (
                <span className="text-xs text-zinc-400 font-mono hidden sm:block">
                  {user.email}
                </span>
              )}
              <button
                onClick={logout}
                className="text-xs text-zinc-400 hover:text-red-400 font-mono transition-colors"
              >
                Sign Out
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="mb-10">
          <p className="text-xs text-zinc-500 font-mono uppercase tracking-widest mb-2">
            Dashboard
          </p>
          <h1 className="text-3xl font-semibold text-white tracking-tight">
            {user?.name ? `Welcome, ${user.name}` : "Welcome"}
          </h1>
        </div>

        {/* Empty state */}
        <div className="glass rounded-2xl p-16 text-center">
          <div className="inline-block mb-8">
            <Logomark className="h-12 w-12 text-zinc-600" />
          </div>

          <h2 className="text-xl font-semibold text-white mb-3">
            Nothing here yet
          </h2>
          <p className="text-sm text-zinc-400 max-w-sm mx-auto mb-8">
            Your personal dashboard is coming soon. Stay tuned for project management, API access, and more.
          </p>
          <button
            disabled
            className="text-xs font-mono uppercase tracking-widest px-8 py-3 bg-white/[0.05] text-zinc-500 rounded-lg cursor-not-allowed border border-white/[0.06]"
          >
            Coming Soon
          </button>
        </div>

        {/* Capability grid */}
        <div className="mt-10 grid grid-cols-2 sm:grid-cols-4 gap-px bg-white/[0.06] rounded-xl overflow-hidden">
          {["Projects", "API Keys", "Analytics", "Settings"].map((item) => (
            <div key={item} className="bg-zinc-950 py-5 text-center">
              <div className="text-sm font-medium text-zinc-500">{item}</div>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 border-t border-white/[0.06]">
        <div className="text-xs text-zinc-600 font-mono text-center tracking-wider">
          Noizu Labs &middot; 2026
        </div>
      </footer>
    </div>
  );
}
