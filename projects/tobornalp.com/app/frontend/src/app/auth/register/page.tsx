"use client";

import { Suspense, useEffect, useRef, useState } from "react";
import { useAuth } from "@/context/auth";
import { useRouter, useSearchParams } from "next/navigation";
import { api } from "@/lib/api";
import { getConsentPreferences } from "@/lib/consent";
import { postAuthPath } from "@/lib/auth-flow";

const BTN_PRIMARY =
  "inline-flex w-full items-center justify-center rounded-full bg-[var(--acc)] px-5 py-2.5 font-mono text-sm font-bold text-black transition-colors hover:bg-[var(--acc-hi)] disabled:opacity-60 disabled:cursor-not-allowed";

function Field({
  label,
  className,
  ...inputProps
}: { label: React.ReactNode; className?: string } & React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <label className="mb-4 block">
      <span className="mb-1.5 block font-mono text-[11px] uppercase tracking-[.08em] text-[var(--mut)]">
        {label}
      </span>
      <input
        {...inputProps}
        className={`w-full rounded-[10px] border border-[var(--line2)] bg-[var(--bg)] px-3.5 py-2.5 font-mono text-sm text-[var(--ink)] outline-none transition-colors placeholder:text-[var(--faint)] focus:border-[var(--acc)] focus:ring-2 focus:ring-[var(--acc-bg)] disabled:opacity-60 ${className ?? ""}`}
      />
    </label>
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

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] px-6 py-16">
      <div className="w-full max-w-[420px] rounded-[14px] border border-[var(--line2)] bg-[var(--panel2)] p-8 shadow-[0_2px_10px_rgba(0,0,0,.35)]">
        {children}
      </div>
    </div>
  );
}

function Register() {
  const { ssoRegister } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const token = searchParams.get("token");
  const inviteRequiredParam = searchParams.get("invite") === "1";

  const [email, setEmail] = useState("");
  const [first, setFirst] = useState("");
  const [last, setLast] = useState("");
  const [inviteToken, setInviteToken] = useState("");
  const [inviteRequired, setInviteRequired] = useState(inviteRequiredParam);
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const resolved = useRef(false);

  // Prefill the verified identity from the registration token.
  useEffect(() => {
    if (!token || resolved.current) return;
    resolved.current = true;
    api
      .getRegistration(token)
      .then((res) => {
        setEmail(res.email);
        if (res.invite_required) setInviteRequired(true);
      })
      .catch(() => setError("This registration link is invalid or has expired."));
  }, [token]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!token) return;
    if (inviteRequired && !inviteToken.trim()) {
      setError("An invite code is required to register with this email domain.");
      return;
    }
    setError("");
    setSubmitting(true);
    try {
      const user = await ssoRegister({
        token,
        first,
        last,
        invite_token: inviteToken.trim() || undefined,
        // Carry the visitor's cookie-consent choice onto the new account.
        consent: getConsentPreferences() as unknown as Record<string, boolean>,
      });
      router.push(postAuthPath(user));
    } catch (err) {
      setError(
        err instanceof Error && err.message
          ? err.message
          : "Failed to complete registration. The link may have expired — please sign in again."
      );
      setSubmitting(false);
    }
  }

  if (!token) {
    return (
      <Shell>
        <Brand />
        <h1 className="mb-2 font-mono text-lg font-bold text-[var(--ink)]">complete registration</h1>
        <p className="mb-4 rounded-[10px] border border-[var(--err)]/30 bg-[var(--err-bg)] px-3 py-2 font-mono text-xs text-[var(--err)]">
          [err] no registration token provided.
        </p>
        <a href="/auth/oidc" className="font-mono text-xs text-[var(--acc)] hover:text-[var(--acc-hi)]">
          start sign in again
        </a>
      </Shell>
    );
  }

  return (
    <Shell>
      <Brand />
      <h1 className="mb-2 font-mono text-lg font-bold text-[var(--ink)]">complete registration</h1>
      <p className="mb-6 font-mono text-[13px] text-[var(--mut)]">
        finish setting up your tobornalp account.
      </p>

      <form onSubmit={handleSubmit}>
        {error && (
          <p className="mb-4 rounded-[10px] border border-[var(--err)]/30 bg-[var(--err-bg)] px-3 py-2 font-mono text-xs text-[var(--err)]">
            [err] {error}{" "}
            <a href="/auth/oidc" className="text-[var(--acc)] hover:text-[var(--acc-hi)]">
              sign in again
            </a>
          </p>
        )}
        {email && (
          <Field id="email" label="email" type="email" value={email} readOnly disabled />
        )}
        <Field
          id="first-name"
          label="first name"
          type="text"
          value={first}
          onChange={(e) => setFirst(e.target.value)}
          required
          autoComplete="given-name"
        />
        <Field
          id="last-name"
          label="last name"
          type="text"
          value={last}
          onChange={(e) => setLast(e.target.value)}
          required
          autoComplete="family-name"
        />
        <Field
          id="invite-token"
          label={
            <>
              invite code{" "}
              {inviteRequired ? (
                <span className="text-[var(--err)]">*</span>
              ) : (
                <span className="text-[var(--faint)]">(optional)</span>
              )}
            </>
          }
          type="text"
          value={inviteToken}
          onChange={(e) => setInviteToken(e.target.value)}
          placeholder={inviteRequired ? "required for your email domain" : "if you have one"}
        />
        <button type="submit" disabled={submitting} className={`${BTN_PRIMARY} mt-2`}>
          {submitting ? "creating account…" : "create account"}
        </button>
      </form>
    </Shell>
  );
}

export default function RegisterPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] font-mono text-sm text-[var(--mut)]">
          loading…
        </div>
      }
    >
      <Register />
    </Suspense>
  );
}
