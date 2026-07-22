"use client";

import { FormEvent, useEffect, useState, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { register, startSsoLogin } from "@/lib/auth";
import { authApi } from "@/lib/api/auth";
import { ApiError } from "@/lib/api";
import { KnowledgeBaseLogo } from "@/components/layout/knowledge-base-logo";

function RegisterForm() {
  const router = useRouter();
  const search = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [userName, setUserName] = useState("");
  const [inviteToken, setInviteToken] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [sso, setSso] = useState(false);

  useEffect(() => {
    const inv =
      search.get("invite") ||
      search.get("invite_token") ||
      search.get("token") ||
      "";
    if (inv) setInviteToken(inv);
    authApi.ssoProviders().then((r) => setSso(r.providers.includes("oidc")));
  }, [search]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!inviteToken.trim()) {
      setError("An invite token is required for email signup.");
      return;
    }
    setLoading(true);
    setError(null);
    try {
      await register(email, password, inviteToken.trim(), userName || undefined);
      router.push("/app");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Registration failed");
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
      <h1 className="mb-1 font-serif text-[28px] font-bold text-ink">
        Join free beta
      </h1>
      <p className="mb-6 font-sans text-[14px] text-ink-secondary">
        Email signup requires an invite. Authentik SSO does not.
      </p>

      {sso && (
        <>
          <button
            type="button"
            onClick={() => startSsoLogin()}
            className="mb-4 flex w-full items-center justify-center gap-2 rounded-lg border border-rule-heavy bg-elevated px-4 py-2.5 font-sans text-[14px] font-medium text-ink transition hover:border-accent"
          >
            Sign up with Authentik
          </button>
          <div className="mb-4 flex items-center gap-3">
            <div className="h-px flex-1 bg-rule" />
            <span className="font-mono text-[10px] uppercase tracking-wide text-ink-tertiary">
              or with invite
            </span>
            <div className="h-px flex-1 bg-rule" />
          </div>
        </>
      )}

      <form onSubmit={onSubmit} className="space-y-4">
        <div>
          <label className="mb-1.5 block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary">
            Invite token
          </label>
          <input
            type="text"
            required
            value={inviteToken}
            onChange={(e) => setInviteToken(e.target.value)}
            placeholder="Paste your invite token"
            className="w-full rounded-lg border border-rule bg-page px-3 py-2.5 font-mono text-[13px] focus:border-accent focus:outline-none"
          />
        </div>
        <div>
          <label className="mb-1.5 block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary">
            Display name
          </label>
          <input
            type="text"
            autoComplete="username"
            value={userName}
            onChange={(e) => setUserName(e.target.value)}
            className="w-full rounded-lg border border-rule bg-page px-3 py-2.5 font-sans text-[14px] focus:border-accent focus:outline-none"
          />
        </div>
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
            minLength={8}
            autoComplete="new-password"
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
          {loading ? "Creating…" : "Create free beta account"}
        </button>
      </form>

      <p className="mt-6 text-center font-sans text-[13px] text-ink-secondary">
        Already have an account?{" "}
        <Link href="/login" className="text-accent hover:underline">
          Sign in
        </Link>
      </p>
    </div>
  );
}

export default function RegisterPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-page px-4 py-12">
      <Suspense fallback={<div className="text-ink-tertiary">Loading…</div>}>
        <RegisterForm />
      </Suspense>
    </div>
  );
}
