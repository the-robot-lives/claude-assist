"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/context/auth";
import { api } from "@/lib/api";
import { appUrl, postAuthPath, userPendingApproval } from "@/lib/auth-flow";
import { useRouter } from "next/navigation";

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

export default function CompleteRegistrationPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [userName, setUserName] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [mobilePhone, setMobilePhone] = useState("");
  const [inviteToken, setInviteToken] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!loading && !user) router.push("/login");
    if (user) {
      setUserName(user.user_name || user.email.split("@")[0] || "");
      setMobilePhone(user.mobile_phone || "");
    }
  }, [loading, router, user]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setSaving(true);
    try {
      const res = await api.completeRegistration({
        userName,
        firstName,
        lastName,
        mobilePhone,
        inviteToken,
      });
      router.push(userPendingApproval(res.user) ? "/pending-approval" : appUrl("/app"));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to complete registration");
    } finally {
      setSaving(false);
    }
  }

  if (loading || !user) return null;

  if (!user.requires_profile_completion && !userPendingApproval(user)) {
    router.push(postAuthPath(user));
    return null;
  }

  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] px-6 py-16">
      <div className="w-full max-w-[420px] rounded-[14px] border border-[var(--line2)] bg-[var(--panel2)] p-8 shadow-[0_2px_10px_rgba(0,0,0,.35)]">
        <div className="mb-6 flex items-baseline gap-1 font-mono">
          <span className="text-sm font-bold tracking-tight text-[var(--ink)]">tobornalp</span>
          <span className="text-sm font-bold text-[var(--acc)] motion-safe:animate-pulse">▮</span>
        </div>
        <h1 className="mb-6 font-mono text-lg font-bold text-[var(--ink)]">complete registration</h1>
        <form onSubmit={handleSubmit}>
          {error && (
            <p className="mb-4 rounded-[10px] border border-[var(--err)]/30 bg-[var(--err-bg)] px-3 py-2 font-mono text-xs text-[var(--err)]">
              [err] {error}
            </p>
          )}
          <Field
            id="invite-token"
            label="invite token"
            type="text"
            value={inviteToken}
            onChange={(e) => setInviteToken(e.target.value)}
            autoComplete="off"
          />
          <Field
            id="user-name"
            label="user name"
            type="text"
            value={userName}
            onChange={(e) => setUserName(e.target.value)}
            required
            autoComplete="username"
          />
          <Field
            id="first-name"
            label="first name"
            type="text"
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            required
            autoComplete="given-name"
          />
          <Field
            id="last-name"
            label="last name"
            type="text"
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            required
            autoComplete="family-name"
          />
          <Field
            id="mobile-phone"
            label="mobile"
            type="tel"
            value={mobilePhone}
            onChange={(e) => setMobilePhone(e.target.value)}
            required
            autoComplete="tel"
          />
          <button type="submit" className={BTN_PRIMARY} disabled={saving}>
            {saving ? "saving…" : "continue"}
          </button>
        </form>
      </div>
    </div>
  );
}
