"use client";

// tobornalp uses Authentik SSO exclusively (like tobor.locker) — no login form.
// Sign-in must be an explicit user action: /login shows a button that navigates
// to the backend OIDC init (which redirects to Authentik). We intentionally do
// NOT auto-redirect on mount — landing on this route (e.g. bounced here by the
// app-host proxy) should never silently launch an SSO flow.
export default function LoginPage() {
  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] px-6 py-16">
      <div className="w-full max-w-[400px] rounded-[14px] border border-[var(--line2)] bg-[var(--panel2)] p-8 shadow-[0_2px_10px_rgba(0,0,0,.35)]">
        <div className="mb-6 flex items-baseline gap-1 font-mono">
          <span className="text-sm font-bold tracking-tight text-[var(--ink)]">therobotplans</span>
          <span className="text-sm font-bold text-[var(--acc)] motion-safe:animate-pulse">▮</span>
        </div>
        <h1 className="mb-2 font-mono text-lg font-bold text-[var(--ink)]">sign in</h1>
        <p className="mb-6 font-mono text-[13px] text-[var(--mut)]">
          sign in with your team account to continue.
        </p>
        <a
          href="/auth/oidc"
          className="inline-flex w-full items-center justify-center rounded-full bg-[var(--acc)] px-5 py-2.5 font-mono text-sm font-bold text-black transition-colors hover:bg-[var(--acc-hi)]"
        >
          continue with sso
        </a>
      </div>
    </div>
  );
}
