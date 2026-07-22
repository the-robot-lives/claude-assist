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

function RegisterForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const next = searchParams.get("next") || "/submit";

  const [email, setEmail] = useState("");
  const [userName, setUserName] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  function validate(): string | null {
    if (!email.includes("@")) return "Enter a valid email address.";
    if (userName.trim().length < 2) return "Username must be at least 2 characters.";
    if (password.length < 8) return "Password must be at least 8 characters.";
    return null;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const problem = validate();
    if (problem) {
      setError(problem);
      return;
    }
    setError("");
    setLoading(true);
    try {
      const res = await api.authRegister(email.trim(), password, userName.trim());
      saveSession(res);
      router.push(next);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed. Try again.");
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-cream">
      <NavBar />

      <section className="px-6 py-16">
        <div className="mx-auto max-w-md">
          <p className="mb-6 font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
            Create an account
          </p>
          <h1
            className="font-display text-3xl font-semibold tracking-tight text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            Join gotta.cc
          </h1>
          <p className="mt-3 font-body text-base leading-relaxed text-ink-secondary">
            An account lets you submit sites to the directory and claim ones you own.
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
              <label htmlFor="username" className={labelClass}>
                Username
              </label>
              <input
                id="username"
                type="text"
                value={userName}
                onChange={(e) => setUserName(e.target.value)}
                placeholder="your-handle"
                required
                autoComplete="username"
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
                placeholder="At least 8 characters"
                required
                autoComplete="new-password"
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
              {loading ? "Creating account…" : "Create account"}
            </button>
          </form>

          <p className="mt-6 font-body text-sm text-ink-secondary">
            Already have an account?{" "}
            <Link
              href={`/login?next=${encodeURIComponent(next)}`}
              className="font-ui font-semibold text-olive hover:text-olive-hover"
            >
              Log in
            </Link>
          </p>
        </div>
      </section>

      <Footer />
    </div>
  );
}

export default function RegisterPage() {
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
      <RegisterForm />
    </Suspense>
  );
}
