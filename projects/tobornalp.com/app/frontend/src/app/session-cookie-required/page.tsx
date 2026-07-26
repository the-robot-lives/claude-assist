"use client";

import { useCookieConsent } from "@/components/cookie-consent";

export default function SessionCookieRequiredPage() {
  const { openSettings } = useCookieConsent();

  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] px-6 py-16">
      <div className="w-full max-w-[420px] rounded-[14px] border border-[var(--line2)] bg-[var(--panel2)] p-8 text-center shadow-[0_2px_10px_rgba(0,0,0,.35)]">
        <div className="mb-6 flex items-baseline justify-center gap-1 font-mono">
          <span className="text-sm font-bold tracking-tight text-[var(--ink)]">tobornalp</span>
          <span className="text-sm font-bold text-[var(--acc)] motion-safe:animate-pulse">▮</span>
        </div>
        <h1 className="mb-3 font-mono text-lg font-bold text-[var(--ink)]">session cookie required</h1>
        <p className="mb-6 font-mono text-[13px] text-[var(--mut)]">
          <span className="text-[var(--warn)]">[warn]</span> this app requires necessary session storage for sign-in, security, and core app behavior.
        </p>
        <button
          type="button"
          onClick={openSettings}
          className="inline-flex w-full items-center justify-center rounded-full bg-[var(--acc)] px-5 py-2.5 font-mono text-sm font-bold text-black transition-colors hover:bg-[var(--acc-hi)]"
        >
          cookie settings
        </button>
      </div>
    </div>
  );
}
