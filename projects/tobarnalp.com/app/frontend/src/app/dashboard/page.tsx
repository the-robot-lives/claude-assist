"use client";

import { useEffect, useState } from "react";
import { isLoggedIn, getUser, logout, startLogin } from "@/lib/auth";

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
      <div
        style={{
          minHeight: "100dvh",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "var(--surface, #FAF7F2)",
          color: "var(--text-secondary, #8E8E96)",
          fontFamily: "var(--font-body, 'Lora', serif)",
          fontSize: 15,
        }}
      >
        Loading…
      </div>
    );
  }

  return (
    <div
      style={{
        minHeight: "100dvh",
        background: "var(--surface, #FAF7F2)",
        color: "var(--text, #2C1810)",
      }}
    >
      {/* Nav */}
      <nav
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "16px 32px",
          borderBottom: "1px solid var(--border, #2A2A30)",
          background: "var(--surface, #FAF7F2)",
          position: "sticky",
          top: 0,
          zIndex: 50,
        }}
      >
        <a
          href="/"
          style={{
            fontSize: 20,
            fontWeight: 700,
            fontFamily: "var(--font-body, 'Lora', serif)",
            letterSpacing: "-0.02em",
            color: "inherit",
            textDecoration: "none",
          }}
        >
          tobornalp
        </a>
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <span
            style={{
              fontSize: 13,
              color: "var(--text-secondary, #8E8E96)",
              fontFamily: "var(--font-mono, monospace)",
            }}
          >
            {user?.email ?? user?.name}
          </span>
          <button
            onClick={() => logout()}
            style={{
              padding: "6px 16px",
              background: "transparent",
              border: "1px solid var(--border, #2A2A30)",
              borderRadius: 8,
              color: "var(--text, #2C1810)",
              cursor: "pointer",
              fontSize: 13,
              fontFamily: "var(--font-body, inherit)",
            }}
          >
            Sign Out
          </button>
        </div>
      </nav>

      {/* Content */}
      <div style={{ maxWidth: 720, margin: "0 auto", padding: "80px 32px", textAlign: "center" }}>
        <h1
          style={{
            fontSize: 28,
            fontWeight: 700,
            fontFamily: "var(--font-body, 'Lora', serif)",
            marginBottom: 12,
          }}
        >
          Dashboard
        </h1>
        <p
          style={{
            fontSize: 15,
            color: "var(--text-secondary, #8E8E96)",
            lineHeight: 1.6,
            marginBottom: 40,
          }}
        >
          Welcome back, {user?.name ?? user?.email ?? "there"}. Your workspace is being prepared.
        </p>

        <div
          style={{
            padding: 40,
            background: "var(--surface-alt, #141416)",
            border: "1px solid var(--border, #2A2A30)",
            borderRadius: 12,
          }}
        >
          <div
            style={{
              width: 48,
              height: 48,
              borderRadius: "50%",
              border: "2px dashed var(--border, #2A2A30)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              margin: "0 auto 16px",
              color: "var(--text-muted, #5A5A62)",
              fontSize: 20,
            }}
          >
            +
          </div>
          <p style={{ fontSize: 14, color: "var(--text-muted, #5A5A62)" }}>
            No projects yet. Features coming soon.
          </p>
        </div>
      </div>
    </div>
  );
}
