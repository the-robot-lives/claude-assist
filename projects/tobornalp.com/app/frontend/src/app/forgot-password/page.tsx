"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { useRouter } from "next/navigation";
import Link from "next/link";

type Step = "request" | "verify" | "done";

const BTN_PRIMARY =
  "inline-flex w-full items-center justify-center rounded-full bg-[var(--acc)] px-5 py-2.5 font-mono text-sm font-bold text-black transition-colors hover:bg-[var(--acc-hi)] disabled:opacity-60 disabled:cursor-not-allowed";

function Field({
  label,
  className,
  ...inputProps
}: { label: string; className?: string } & React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <div className="mb-4">
      <label
        htmlFor={inputProps.id}
        className="mb-1.5 block font-mono text-[11px] uppercase tracking-[.08em] text-[var(--mut)]"
      >
        {label}
      </label>
      <input
        {...inputProps}
        className={`w-full rounded-[10px] border border-[var(--line2)] bg-[var(--bg)] px-3.5 py-2.5 font-mono text-sm text-[var(--ink)] outline-none transition-colors placeholder:text-[var(--faint)] focus:border-[var(--acc)] focus:ring-2 focus:ring-[var(--acc-bg)] ${className ?? ""}`}
      />
    </div>
  );
}

function Brand() {
  return (
    <div className="mb-6 flex items-baseline gap-1 font-mono">
      <span className="text-sm font-bold tracking-tight text-[var(--ink)]">tobornalp</span>
      <span className="text-sm font-bold text-[var(--acc)] motion-safe:animate-pulse">▮</span>
    </div>
  );
}

export default function ForgotPasswordPage() {
  const router = useRouter();
  const [step, setStep] = useState<Step>("request");
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [devCode, setDevCode] = useState<string | null>(null);

  async function handleRequest(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const res = await api.requestPasswordReset(email);
      if (res.dev_code) setDevCode(res.dev_code);
      setStep("verify");
    } catch {
      setError("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  async function handleVerify(e: React.FormEvent) {
    e.preventDefault();
    setError("");

    if (newPassword.length < 8) {
      setError("Password must be at least 8 characters");
      return;
    }
    if (newPassword !== confirmPassword) {
      setError("Passwords do not match");
      return;
    }

    setLoading(true);
    try {
      await api.verifyPasswordReset(email, code, newPassword);
      setStep("done");
    } catch {
      setError("Invalid or expired code");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] px-6 py-16">
      <div className="w-full max-w-[420px] rounded-[14px] border border-[var(--line2)] bg-[var(--panel2)] p-8 shadow-[0_2px_10px_rgba(0,0,0,.35)]">
        <Brand />
        <h1 className="mb-6 font-mono text-lg font-bold text-[var(--ink)]">reset password</h1>

        {step === "request" && (
          <form onSubmit={handleRequest}>
            {error && (
              <p className="mb-4 rounded-[10px] border border-[var(--err)]/30 bg-[var(--err-bg)] px-3 py-2 font-mono text-xs text-[var(--err)]">
                [err] {error}
              </p>
            )}
            <p className="mb-4 font-mono text-[13px] text-[var(--mut)]">
              enter your email and we&apos;ll send you a reset code.
            </p>
            <Field
              id="email"
              label="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
            />
            <button type="submit" className={BTN_PRIMARY} disabled={loading}>
              {loading ? "sending…" : "send reset code"}
            </button>
            <p className="mt-4 font-mono text-xs text-[var(--mut)]">
              <Link href="/login" className="text-[var(--acc)] hover:text-[var(--acc-hi)]">
                back to login
              </Link>
            </p>
          </form>
        )}

        {step === "verify" && (
          <form onSubmit={handleVerify}>
            {error && (
              <p className="mb-4 rounded-[10px] border border-[var(--err)]/30 bg-[var(--err-bg)] px-3 py-2 font-mono text-xs text-[var(--err)]">
                [err] {error}
              </p>
            )}
            <p className="mb-4 font-mono text-[13px] text-[var(--mut)]">
              enter the 6-digit code sent to {email} and your new password.
            </p>
            {devCode && (
              <p className="mb-4 rounded-[10px] border border-dashed border-[var(--line2)] bg-[var(--bg)] px-3.5 py-2.5 font-mono text-xs text-[var(--mut)]">
                <span className="text-[var(--info)]">[info]</span> dev mode code:{" "}
                <span className="text-[var(--ink)]">{devCode}</span>
              </p>
            )}
            <Field
              id="reset-code"
              label="code"
              type="text"
              inputMode="numeric"
              pattern="[0-9]*"
              maxLength={6}
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
              required
              autoComplete="one-time-code"
              className="text-center text-lg tracking-[0.5em]"
            />
            <Field
              id="new-password"
              label="new password"
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              required
              autoComplete="new-password"
              minLength={8}
            />
            <Field
              id="confirm-password"
              label="confirm password"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
              autoComplete="new-password"
              minLength={8}
            />
            <button type="submit" className={BTN_PRIMARY} disabled={loading || code.length !== 6}>
              {loading ? "resetting…" : "reset password"}
            </button>
            <p className="mt-4 font-mono text-xs text-[var(--mut)]">
              <Link href="/login" className="text-[var(--acc)] hover:text-[var(--acc-hi)]">
                back to login
              </Link>
            </p>
          </form>
        )}

        {step === "done" && (
          <div>
            <p className="mb-4 font-mono text-[13px] text-[var(--mut)]">
              <span className="text-[var(--acc)]">[ok]</span> your password has been reset.
            </p>
            <button className={BTN_PRIMARY} onClick={() => router.push("/login")}>
              go to login
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
