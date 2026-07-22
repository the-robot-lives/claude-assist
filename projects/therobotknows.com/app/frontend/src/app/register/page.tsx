"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { register } from "@/lib/auth";
import { ApiError } from "@/lib/api";

export default function RegisterPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [userName, setUserName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      await register(email, password, userName || undefined);
      router.push("/");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Registration failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-page flex items-center justify-center px-4">
      <div className="w-full max-w-md bg-surface border border-rule rounded-xl p-8 shadow-sm">
        <h1 className="font-serif text-[28px] font-bold text-ink mb-1">Create account</h1>
        <p className="font-sans text-[14px] text-ink-secondary mb-6">
          Start building consistent creative universes.
        </p>

        <form onSubmit={onSubmit} className="space-y-4">
          <div>
            <label className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5">
              Display name
            </label>
            <input
              type="text"
              autoComplete="username"
              value={userName}
              onChange={(e) => setUserName(e.target.value)}
              className="w-full rounded-lg border border-rule bg-page px-3 py-2.5 font-sans text-[14px] text-ink focus:outline-none focus:border-accent"
            />
          </div>
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
              minLength={8}
              autoComplete="new-password"
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
            {loading ? "Creating…" : "Create account"}
          </button>
        </form>

        <p className="mt-6 font-sans text-[13px] text-ink-secondary text-center">
          Already have an account?{" "}
          <Link href="/login" className="text-accent hover:underline">
            Sign in
          </Link>
        </p>
      </div>
    </div>
  );
}
