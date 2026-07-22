"use client";

import { FormEvent, useEffect, useState, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { login, startSsoLogin } from "@/lib/auth";
import { authApi } from "@/lib/api/auth";
import { ApiError } from "@/lib/api";
import { KnowledgeBaseLogo } from "@/components/layout/knowledge-base-logo";

function LoginForm() {
  const router = useRouter();
  const search = useSearchParams();
  const next = search.get("next") || "/app";
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [sso, setSso] = useState(false);

  useEffect(() => {
    authApi.ssoProviders().then((r) => {
      setSso(r.providers.includes("oidc"));
    });
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      await login(email, password);
      router.push(next);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="w-full max-w-md rounded-2xl border border-rule bg-surface p-8 shadow-[0_8px_32px_rgba(26,23,20,0.06)]">
      <Link href="/" className="mb-6 flex items-center gap-2">
        <KnowledgeBaseLogo size={28} className="text-ink" />
        <span className="font-serif text-[14px] font-semibold uppercase tracking-[0.06em] text-ink">
          TheRobotKnows
        </span>
      </Link>
      <h1 className="mb-1 font-serif text-[28px] font-bold text-ink">Sign in</h1>
      <p className="mb-6 font-sans text-[14px] text-ink-secondary">
        Continue to your knowledge universes.
      </p>

      {sso && (
        <>
          <button
            type="button"
            onClick={() => startSsoLogin()}
            className="mb-4 flex w-full items-center justify-center gap-2 rounded-lg border border-rule-heavy bg-elevated px-4 py-2.5 font-sans text-[14px] font-medium text-ink transition hover:border-accent"
          >
            Continue with Authentik
          </button>
          <div className="mb-4 flex items-center gap-3">
            <div className="h-px flex-1 bg-rule" />
            <span className="font-mono text-[10px] uppercase tracking-wide text-ink-tertiary">
              or email
            </span>
            <div className="h-px flex-1 bg-rule" />
          </div>
        </>
      )}

      <form onSubmit={onSubmit} className="space-y-4">
        <div>
          <label className="mb-1.5 block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary">
            Email
          </label>
          <input
            type="email"
            required
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full rounded-lg border border-rule bg-page px-3 py-2.5 font-sans text-[14px] focus:border-accent focus:outline-none"
          />
        </div>
        <div>
          <label className="mb-1.5 block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary">
            Password
          </label>
          <input
            type="password"
            required
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full rounded-lg border border-rule bg-page px-3 py-2.5 font-sans text-[14px] focus:border-accent focus:outline-none"
          />
        </div>
        {error && (
          <p className="rounded-md bg-flag-warn-muted px-3 py-2 font-sans text-[13px] text-flag-warn">
            {error}
          </p>
        )}
        <button
          type="submit"
          disabled={loading}
          className="w-full rounded-lg bg-accent py-2.5 font-sans text-[14px] font-medium text-white hover:bg-accent-hover disabled:opacity-60"
        >
          {loading ? "Signing in…" : "Sign in"}
        </button>
      </form>

      <p className="mt-6 text-center font-sans text-[13px] text-ink-secondary">
        Need an account?{" "}
        <Link href="/register" className="text-accent hover:underline">
          Free beta signup
        </Link>
        {" · "}
        <Link href="/reset-password" className="text-accent hover:underline">
          Reset password
        </Link>
      </p>
    </div>
  );
}

export default function LoginPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-page px-4 py-12">
      <Suspense fallback={<div className="text-ink-tertiary">Loading…</div>}>
        <LoginForm />
      </Suspense>
    </div>
  );
}
