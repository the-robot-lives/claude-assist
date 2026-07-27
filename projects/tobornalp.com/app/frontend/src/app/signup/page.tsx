"use client";

import { useEffect, useMemo, useState } from "react";
import { useAuth } from "@/context/auth";
import { useRouter } from "next/navigation";
import { api } from "@/lib/api";
import type { SsoDomainMap } from "@/lib/api";
import { emailDomain, matchingSsoProviders, postAuthPath } from "@/lib/auth-flow";
import Link from "next/link";

const SSO_LABELS: Record<string, string> = {
  oidc: "continue with sso",
  google: "continue with google",
  github: "continue with github",
  facebook: "continue with facebook",
  linkedin: "continue with linkedin",
  saml: "continue with saml",
};

const SSO_PATHS: Record<string, string> = {
  oidc: "/auth/oidc",
  google: "/auth/google",
  github: "/auth/github",
  facebook: "/auth/facebook",
  linkedin: "/auth/linkedin",
  saml: "/sso/saml/auth/signin",
};

type Step = "email" | "sso" | "password";

const BTN_PRIMARY =
  "inline-flex w-full items-center justify-center rounded-full bg-[var(--acc)] px-5 py-2.5 font-mono text-sm font-bold text-black transition-colors hover:bg-[var(--acc-hi)] disabled:opacity-60 disabled:cursor-not-allowed";
const BTN_OUTLINE =
  "inline-flex w-full items-center justify-center rounded-full border border-[var(--line2)] bg-[var(--panel2)] px-5 py-2.5 font-mono text-sm font-semibold text-[var(--ink)] transition-colors hover:border-[var(--faint)]";

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
      <span className="text-sm font-bold tracking-tight text-[var(--ink)]">therobotplans</span>
      <span className="text-sm font-bold text-[var(--acc)] motion-safe:animate-pulse">▮</span>
    </div>
  );
}

export default function SignupPage() {
  const { register } = useAuth();
  const router = useRouter();
  const [step, setStep] = useState<Step>("email");
  const [ssoProviders, setSsoProviders] = useState<string[]>([]);
  const [ssoDomains, setSsoDomains] = useState<SsoDomainMap>({});
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [userName, setUserName] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [mobilePhone, setMobilePhone] = useState("");
  const [inviteToken, setInviteToken] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    api
      .ssoProviders()
      .then((res) => {
        setSsoProviders(res.providers);
        setSsoDomains(res.domain_policies ?? res.domains ?? {});
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    if (!userName && emailDomain(email)) {
      setUserName(email.split("@")[0]?.replace(/[^a-zA-Z0-9_-]/g, "_") ?? "");
    }
  }, [email, userName]);

  const domainProviders = useMemo(() => {
    const providers = matchingSsoProviders(email, ssoDomains);
    return providers.filter((provider) => ssoProviders.includes(provider));
  }, [email, ssoDomains, ssoProviders]);

  function handleEmailSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setStep(domainProviders.length > 0 ? "sso" : "password");
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const user = await register({
        email,
        password,
        userName,
        firstName,
        lastName,
        mobilePhone,
        inviteToken,
      });
      router.push(postAuthPath(user));
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Registration failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] px-6 py-16">
      <div className="w-full max-w-[420px] rounded-[14px] border border-[var(--line2)] bg-[var(--panel2)] p-8 shadow-[0_2px_10px_rgba(0,0,0,.35)]">
        <Brand />
        <h1 className="mb-6 font-mono text-lg font-bold text-[var(--ink)]">sign up</h1>

        {step === "email" && (
          <form onSubmit={handleEmailSubmit}>
            <Field
              id="email"
              label="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
            />
            <button type="submit" className={BTN_PRIMARY}>
              continue
            </button>
            <p className="mt-4 font-mono text-xs text-[var(--mut)]">
              already have an account?{" "}
              <Link href="/login" className="text-[var(--acc)] hover:text-[var(--acc-hi)]">
                log in
              </Link>
            </p>
          </form>
        )}

        {step === "sso" && (
          <div>
            <p className="mb-4 font-mono text-[13px] text-[var(--mut)]">{email}</p>
            <div className="flex flex-col gap-2">
              {domainProviders.map((provider) => (
                <a
                  key={provider}
                  href={SSO_PATHS[provider] || `/auth/${provider}`}
                  className={BTN_OUTLINE}
                >
                  {SSO_LABELS[provider] || `continue with ${provider}`}
                </a>
              ))}
              <button type="button" className={BTN_OUTLINE} onClick={() => setStep("password")}>
                use email and password instead
              </button>
              <button type="button" className={BTN_OUTLINE} onClick={() => setStep("email")}>
                change email
              </button>
            </div>
          </div>
        )}

        {step === "password" && (
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
              id="email-password"
              label="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
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
            <Field
              id="password"
              label="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={8}
              autoComplete="new-password"
            />
            <button type="submit" className={BTN_PRIMARY} disabled={loading}>
              {loading ? "creating account…" : "sign up"}
            </button>
            <p className="mt-4 font-mono text-xs text-[var(--mut)]">
              already have an account?{" "}
              <Link href="/login" className="text-[var(--acc)] hover:text-[var(--acc-hi)]">
                log in
              </Link>
            </p>
          </form>
        )}
      </div>
    </div>
  );
}
