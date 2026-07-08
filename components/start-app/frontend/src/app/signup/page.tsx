"use client";

import { useEffect, useMemo, useState } from "react";
import { useAuth } from "@/context/auth";
import { useRouter } from "next/navigation";
import { api } from "@/lib/api";
import { emailDomain, matchingSsoProviders, postAuthPath } from "@/lib/auth-flow";
import Link from "next/link";

const SSO_LABELS: Record<string, string> = {
  oidc: "Continue with SSO",
  google: "Continue with Google",
  github: "Continue with GitHub",
  facebook: "Continue with Facebook",
  linkedin: "Continue with LinkedIn",
  saml: "Continue with SAML",
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

export default function SignupPage() {
  const { register } = useAuth();
  const router = useRouter();
  const [step, setStep] = useState<Step>("email");
  const [ssoProviders, setSsoProviders] = useState<string[]>([]);
  const [ssoDomains, setSsoDomains] = useState<Record<string, string[]>>({});
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
        setSsoDomains(res.domains ?? {});
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
    <div className="content">
      <main>
        <h1 className="sg-page-title">Sign Up</h1>

        {step === "email" && (
          <form onSubmit={handleEmailSubmit} style={{ maxWidth: 400 }}>
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
              Already have an account? <Link href="/login">Log in</Link>
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
                {SSO_LABELS[provider] || `Continue with ${provider}`}
              </a>
            ))}
            <button
              type="button"
              className="sg-btn sg-btn--outline"
              onClick={() => setStep("password")}
              style={{ width: "100%", marginTop: "0.5rem" }}
            >
              Use email and password instead
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
          <form onSubmit={handleSubmit} style={{ maxWidth: 400 }}>
            {error && <p className="sg-error">{error}</p>}
            <div className="sg-field">
              <label htmlFor="invite-token">Invite Token</label>
              <input
                id="invite-token"
                type="text"
                value={inviteToken}
                onChange={(e) => setInviteToken(e.target.value)}
                autoComplete="off"
              />
            </div>
            <div className="sg-field">
              <label htmlFor="email-password">Email</label>
              <input
                id="email-password"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
            </div>
            <div className="sg-field">
              <label htmlFor="user-name">User Name</label>
              <input
                id="user-name"
                type="text"
                value={userName}
                onChange={(e) => setUserName(e.target.value)}
                required
                autoComplete="username"
              />
            </div>
            <div className="sg-field">
              <label htmlFor="first-name">First Name</label>
              <input id="first-name" type="text" value={firstName} onChange={(e) => setFirstName(e.target.value)} required autoComplete="given-name" />
            </div>
            <div className="sg-field">
              <label htmlFor="last-name">Last Name</label>
              <input id="last-name" type="text" value={lastName} onChange={(e) => setLastName(e.target.value)} required autoComplete="family-name" />
            </div>
            <div className="sg-field">
              <label htmlFor="mobile-phone">Mobile</label>
              <input id="mobile-phone" type="tel" value={mobilePhone} onChange={(e) => setMobilePhone(e.target.value)} required autoComplete="tel" />
            </div>
            <div className="sg-field">
              <label htmlFor="password">Password</label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                minLength={8}
                autoComplete="new-password"
              />
            </div>
            <button type="submit" className="sg-btn sg-btn--black" disabled={loading}>
              {loading ? "Creating account..." : "Sign Up"}
            </button>
            <p style={{ marginTop: "1rem" }}>
              Already have an account? <Link href="/login">Log in</Link>
            </p>
          </form>
        )}
      </main>
    </div>
  );
}
