"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { authApi } from "@/lib/api/auth";
import { ApiError } from "@/lib/api";

export default function ResetPasswordPage() {
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [step, setStep] = useState<"request" | "verify">("request");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onRequest(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const res = await authApi.requestPasswordReset(email);
      setMessage(res.message + (res.dev_code ? ` (dev code: ${res.dev_code})` : ""));
      setStep("verify");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Request failed");
    } finally {
      setLoading(false);
    }
  }

  async function onVerify(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const res = await authApi.verifyPasswordReset(email, code, newPassword);
      setMessage(res.message);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Reset failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-page flex items-center justify-center px-4">
      <div className="w-full max-w-md bg-surface border border-rule rounded-xl p-8 shadow-sm">
        <h1 className="font-serif text-[28px] font-bold text-ink mb-1">Reset password</h1>
        <p className="font-sans text-[14px] text-ink-secondary mb-6">
          We&apos;ll email a code if the account exists.
        </p>

        {step === "request" ? (
          <form onSubmit={onRequest} className="space-y-4">
            <div>
              <label className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5">
                Email
              </label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
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
              className="w-full rounded-lg bg-accent text-white font-sans text-[14px] font-medium py-2.5 disabled:opacity-60"
            >
              {loading ? "Sending…" : "Send reset code"}
            </button>
          </form>
        ) : (
          <form onSubmit={onVerify} className="space-y-4">
            {message && (
              <p className="font-sans text-[13px] text-ink-secondary bg-accent-muted rounded-md px-3 py-2">
                {message}
              </p>
            )}
            <div>
              <label className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5">
                Code
              </label>
              <input
                type="text"
                required
                value={code}
                onChange={(e) => setCode(e.target.value)}
                className="w-full rounded-lg border border-rule bg-page px-3 py-2.5 font-sans text-[14px] text-ink focus:outline-none focus:border-accent"
              />
            </div>
            <div>
              <label className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5">
                New password
              </label>
              <input
                type="password"
                required
                minLength={8}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
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
              className="w-full rounded-lg bg-accent text-white font-sans text-[14px] font-medium py-2.5 disabled:opacity-60"
            >
              {loading ? "Updating…" : "Set new password"}
            </button>
          </form>
        )}

        <p className="mt-6 font-sans text-[13px] text-ink-secondary text-center">
          <Link href="/login" className="text-accent hover:underline">
            Back to sign in
          </Link>
        </p>
      </div>
    </div>
  );
}
