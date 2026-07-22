"use client";

import { useEffect, useMemo, useState } from "react";
import { useAuth } from "@/context/auth";
import { useRouter } from "next/navigation";
import { api } from "@/lib/api";
import type { SsoDomainMap } from "@/lib/api";
import { matchingSsoProviders, navigateTo, postAuthPath } from "@/lib/auth-flow";
import Link from "next/link";

const SSO_LABELS: Record<string, string> = {
  oidc: "Sign in with SSO",
  google: "Sign in with Google",
  github: "Sign in with GitHub",
  facebook: "Sign in with Facebook",
  linkedin: "Sign in with LinkedIn",
  saml: "Sign in with SAML",
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

export default function LoginPage() {
  const { login } = useAuth();
  const router = useRouter();
  const [step, setStep] = useState<Step>("email");
  const [ssoProviders, setSsoProviders] = useState<string[]>([]);
  const [ssoDomains, setSsoDomains] = useState<SsoDomainMap>({});
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
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

  const domainProviders = useMemo(() => {
    const providers = matchingSsoProviders(email, ssoDomains);
    return providers.filter((provider) => ssoProviders.includes(provider));
  }, [email, ssoDomains, ssoProviders]);

  function handleEmailSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setStep(domainProviders.length > 0 ? "sso" : "password");
  }

  async function handlePasswordSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const user = await login(email, password);
      navigateTo(router, postAuthPath(user));
    } catch {
      setError("Invalid email or password");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="content">
      <main>
        <h1 className="sg-page-title">Log In</h1>

        {step === "email" && (
          <form onSubmit={handleEmailSubmit} style={{ maxWidth: 400 }}>
            {error && <p className="sg-error">{error}</p>}
            <div className="sg-field">
              <label htmlFor="email">Email</label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
            </div>
            <button type="submit" className="sg-btn sg-btn--black">
              Continue
            </button>
            <p style={{ marginTop: "1rem" }}>
              Don&apos;t have an account? <Link href="/signup">Sign up</Link>
            </p>
          </form>
        )}

        {step === "sso" && (
          <div style={{ maxWidth: 400 }}>
            <p style={{ marginBottom: "1rem" }}>{email}</p>
            {domainProviders.map((provider) => (
              <a
                key={provider}
                href={SSO_PATHS[provider] || `/auth/${provider}`}
                className="sg-btn sg-btn--black"
                style={{ display: "flex", width: "100%", marginBottom: "0.5rem" }}
              >
                {SSO_LABELS[provider] || `Sign in with ${provider}`}
              </a>
            ))}
            <button
              type="button"
              className="sg-btn sg-btn--outline"
              onClick={() => setStep("password")}
              style={{ width: "100%", marginTop: "0.5rem" }}
            >
              Use password instead
            </button>
            <button
              type="button"
              className="sg-btn sg-btn--outline"
              onClick={() => setStep("email")}
              style={{ width: "100%", marginTop: "0.5rem" }}
            >
              Change email
            </button>
          </div>
        )}

        {step === "password" && (
          <form onSubmit={handlePasswordSubmit} style={{ maxWidth: 400 }}>
            {error && <p className="sg-error">{error}</p>}
            <div className="sg-field">
              <label htmlFor="password-email">Email</label>
              <input
                id="password-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
            </div>
            <div className="sg-field">
              <label htmlFor="password">Password</label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete="current-password"
              />
            </div>
            <button type="submit" className="sg-btn sg-btn--black" disabled={loading}>
              {loading ? "Logging in..." : "Log In"}
            </button>
            <div style={{ marginTop: "1rem" }}>
              <p><Link href="/forgot-password">Forgot password?</Link></p>
              <p><a href="#" onClick={(e) => { e.preventDefault(); setStep("email"); }}>Change email</a></p>
              <p>Don&apos;t have an account? <Link href="/signup">Sign up</Link></p>
            </div>
          </form>
        )}
      </main>
    </div>
  );
}
