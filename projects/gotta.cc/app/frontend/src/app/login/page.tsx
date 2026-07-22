"use client";

import { Suspense, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { NavBar } from "../navbar";
import { Footer } from "@/components/footer";
import { api } from "@/lib/api";
import { saveSession } from "@/lib/session";

const inputClass =
  "w-full rounded-xl border-2 border-rule bg-surface px-4 py-3 font-ui text-base text-ink placeholder:text-ink-tertiary transition-all duration-200 focus:border-coral focus:shadow-[0_0_0_4px_rgba(232,112,74,0.1)] focus:outline-none disabled:opacity-50";
const labelClass =
  "font-ui text-xs font-bold uppercase tracking-[0.06em] text-ink-tertiary";

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const next = searchParams.get("next") || "/";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!email.includes("@") || !password) {
      setError("Enter your email and password.");
      return;
    }
    setError("");
    setLoading(true);
    try {
      const res = await api.authLogin(email.trim(), password);
      saveSession(res);
      router.push(next);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed. Check your details.");
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-cream">
      <NavBar />

      <section className="px-6 py-16">
        <div className="mx-auto max-w-md">
          <p className="mb-6 font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
            Log in
          </p>
          <h1
            className="font-display text-3xl font-semibold tracking-tight text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            Welcome back
          </h1>
          <p className="mt-3 font-body text-base leading-relaxed text-ink-secondary">
            Sign in with the email and password you used to submit sites. This is the
            account for directory submitters — separate from any organization SSO.
          </p>

          <form onSubmit={handleSubmit} className="mt-8 flex flex-col gap-5">
            <div className="flex flex-col gap-1.5">
              <label htmlFor="email" className={labelClass}>
                Email
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                required
                autoComplete="email"
                disabled={loading}
                className={inputClass}
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <label htmlFor="password" className={labelClass}>
                Password
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Your password"
                required
                autoComplete="current-password"
                disabled={loading}
                className={inputClass}
              />
            </div>

            {error && (
              <p className="font-ui text-sm text-error" role="alert">
                {error}
              </p>
            )}

            <button
              type="submit"
              disabled={loading}
              className="rounded-xl bg-coral px-6 py-3 font-ui text-base font-semibold text-white shadow-[0_2px_8px_rgba(232,112,74,0.2)] transition-all duration-150 hover:-translate-y-0.5 hover:bg-coral-hover disabled:opacity-50"
            >
              {loading ? "Signing in…" : "Log in"}
            </button>
          </form>

          <p className="mt-6 font-body text-sm text-ink-secondary">
            New here?{" "}
            <Link
              href={`/register?next=${encodeURIComponent(next)}`}
              className="font-ui font-semibold text-olive hover:text-olive-hover"
            >
              Create an account
            </Link>
          </p>
        </div>
      </section>

      <Footer />
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-screen items-center justify-center bg-cream">
          <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
            Loading…
          </p>
        </div>
      }
    >
      <LoginForm />
    </Suspense>
  );
}
