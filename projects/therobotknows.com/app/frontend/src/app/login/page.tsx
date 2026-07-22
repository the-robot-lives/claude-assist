"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { login } from "@/lib/auth";
import { ApiError } from "@/lib/api";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      await login(email, password);
      router.push("/");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-page flex items-center justify-center px-4">
      <div className="w-full max-w-md bg-surface border border-rule rounded-xl p-8 shadow-sm">
        <h1 className="font-serif text-[28px] font-bold text-ink mb-1">Sign in</h1>
        <p className="font-sans text-[14px] text-ink-secondary mb-6">
          Knowledge Base · therobotknows.com
        </p>

        <form onSubmit={onSubmit} className="space-y-4">
          <div>
            <label className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5">
              Email
            </label>
            <input
              type="email"
              required
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded-lg border border-rule bg-page px-3 py-2.5 font-sans text-[14px] text-ink focus:outline-none focus:border-accent"
            />
          </div>
          <div>
            <label className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5">
              Password
            </label>
            <input
              type="password"
              required
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-lg border border-rule bg-page px-3 py-2.5 font-sans text-[14px] text-ink focus:outline-none focus:border-accent"
            />
          </div>

          {error && (
            <p className="font-sans text-[13px] text-flag-warn bg-flag-warn-muted rounded-md px-3 py-2">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-lg bg-accent text-white font-sans text-[14px] font-medium py-2.5 hover:opacity-90 disabled:opacity-60"
          >
            {loading ? "Signing in…" : "Sign in"}
          </button>
        </form>

        <p className="mt-6 font-sans text-[13px] text-ink-secondary text-center">
          No account?{" "}
          <Link href="/register" className="text-accent hover:underline">
            Create one
          </Link>
          {" · "}
          <Link href="/reset-password" className="text-accent hover:underline">
            Reset password
          </Link>
        </p>
      </div>
    </div>
  );
}
