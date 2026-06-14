"use client";

import { useEffect, useState } from "react";
import { isLoggedIn, getUser, logout, startLogin } from "@/lib/auth-pkce";
import { Logo } from "@/components/logo";
import Link from "next/link";

const PIPELINE = ["Concept", "Validate", "Build", "Scale"];

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
      <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", background: "var(--surface)" }}>
        <p style={{ fontFamily: "var(--font-mono)", fontSize: "0.75rem", color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.08em" }}>
          Loading...
        </p>
      </div>
    );
  }

  return (
    <div style={{ minHeight: "100vh", background: "var(--surface)" }}>
      {/* Nav */}
      <header style={{ position: "sticky", top: 0, zIndex: 10, background: "var(--surface)", borderBottom: "1px solid var(--border)" }}>
        <div className="content" style={{ display: "flex", alignItems: "center", height: 56, gap: 12 }}>
          <Link href="/" style={{ display: "inline-flex", alignItems: "center" }}>
            <Logo size={32} showText={false} />
          </Link>
          <span style={{ fontFamily: "var(--font-display)", fontSize: "0.9375rem", fontWeight: 600, color: "var(--text)", textTransform: "uppercase", letterSpacing: "0.04em" }}>
            Dashboard
          </span>
          <div style={{ flex: 1 }} />
          <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
            {user?.email && (
              <span style={{ fontFamily: "var(--font-mono)", fontSize: "0.6875rem", color: "var(--text-muted)" }}>
                {user.email}
              </span>
            )}
            <button
              onClick={logout}
              style={{ fontFamily: "var(--font-mono)", fontSize: "0.6875rem", textTransform: "uppercase", letterSpacing: "0.06em", color: "var(--text-muted)", background: "none", border: "none", cursor: "pointer" }}
            >
              Sign Out
            </button>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="content" style={{ paddingTop: 40, paddingBottom: 40 }}>
        <div style={{ marginBottom: 32 }}>
          <p style={{ fontFamily: "var(--font-mono)", fontSize: "0.5625rem", color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.2em", marginBottom: 8 }}>
            Dashboard
          </p>
          <h1 style={{ fontFamily: "var(--font-display)", fontSize: "2rem", fontWeight: 700, color: "var(--text)", lineHeight: 1.2 }}>
            {user?.name ? `Welcome, ${user.name}` : "Welcome"}
          </h1>
        </div>

        {/* Empty state */}
        <div style={{ border: "1px solid var(--border)", background: "var(--surface-alt)", borderRadius: 12, padding: "4rem 2rem", textAlign: "center" }}>
          <div style={{ marginBottom: 32 }}>
            <Logo size={48} showText={false} />
          </div>

          <h2 style={{ fontFamily: "var(--font-display)", fontSize: "1.5rem", fontWeight: 600, color: "var(--text)", marginBottom: 12 }}>
            No projects yet
          </h2>
          <p style={{ fontFamily: "var(--font-body)", fontSize: "0.875rem", color: "var(--text-secondary)", maxWidth: 400, margin: "0 auto 2rem" }}>
            Your portfolio dashboard is coming soon. Manage products, track validation metrics, and monitor deployments from here.
          </p>
          <button
            disabled
            className="sg-btn sg-btn--outline"
            style={{ opacity: 0.5, cursor: "not-allowed" }}
          >
            + New Project &mdash; Coming Soon
          </button>
        </div>

        {/* Pipeline phases */}
        <div style={{ marginTop: 48, display: "grid", gridTemplateColumns: `repeat(${PIPELINE.length}, 1fr)`, gap: 1, background: "var(--border)" }}>
          {PIPELINE.map((phase, i) => (
            <div key={phase} style={{ background: "var(--surface-alt)", padding: "1rem", textAlign: "center" }}>
              <div style={{ fontFamily: "var(--font-mono)", fontSize: "0.5rem", color: "var(--text-muted)", letterSpacing: "0.2em", marginBottom: 4 }}>
                {String(i + 1).padStart(2, "0")}
              </div>
              <div style={{ fontFamily: "var(--font-display)", fontSize: "0.875rem", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.06em", color: "var(--text-muted)" }}>
                {phase}
              </div>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer style={{ borderTop: "1px solid var(--border)", padding: "2rem 0" }}>
        <div className="content" style={{ textAlign: "center" }}>
          <p style={{ fontFamily: "var(--font-mono)", fontSize: "0.5625rem", color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.2em" }}>
            DeRobot.is &middot; AI-Native Product Portfolio &middot; 2026
          </p>
        </div>
      </footer>
    </div>
  );
}
