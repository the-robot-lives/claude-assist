"use client";

import { useEffect } from "react";

// tobornalp uses Authentik SSO exclusively (like tobor.locker) — no login form.
// /login bounces straight to the backend OIDC init, which redirects to Authentik.
export default function LoginPage() {
  useEffect(() => {
    window.location.href = "/auth/oidc";
  }, []);

  return (
    <div className="content" style={{ maxWidth: 480, margin: "4rem auto", padding: "0 24px" }}>
      <h1 style={{ fontFamily: "var(--font-display)", fontSize: 28, fontWeight: 500, color: "var(--text)" }}>
        Signing In
      </h1>
      <p style={{ fontFamily: "var(--font-body)", color: "var(--text-secondary)" }}>Redirecting to sign in&hellip;</p>
    </div>
  );
}
