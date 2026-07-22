"use client";

// tobornalp uses Authentik SSO exclusively (like tobor.locker) — no login form.
// Sign-in must be an explicit user action: /login shows a button that navigates
// to the backend OIDC init (which redirects to Authentik). We intentionally do
// NOT auto-redirect on mount — landing on this route (e.g. bounced here by the
// app-host proxy) should never silently launch an SSO flow.
export default function LoginPage() {
  return (
    <div className="content" style={{ maxWidth: 480, margin: "4rem auto", padding: "0 24px" }}>
      <h1 style={{ fontFamily: "var(--font-display)", fontSize: 28, fontWeight: 500, color: "var(--text)" }}>
        Sign In
      </h1>
      <p style={{ fontFamily: "var(--font-body)", color: "var(--text-secondary)", marginBottom: 24 }}>
        Sign in with your team account to continue.
      </p>
      <a
        href="/auth/oidc"
        className="sg-btn sg-btn--black"
        style={{
          display: "inline-block",
          fontFamily: "var(--font-sans, system-ui, sans-serif)",
          fontWeight: 600,
          fontSize: 15,
          padding: "12px 24px",
          borderRadius: 10,
          background: "var(--brand-blue, #234e23)",
          color: "#fff",
          textDecoration: "none",
        }}
      >
        Continue with SSO
      </a>
    </div>
  );
}
