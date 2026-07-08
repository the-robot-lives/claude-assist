"use client";

import { Suspense, useEffect, useRef, useState } from "react";
import { useAuth } from "@/context/auth";
import { useRouter, useSearchParams } from "next/navigation";
import { api } from "@/lib/api";
import { getConsentPreferences } from "@/lib/consent";
import { postAuthPath } from "@/lib/auth-flow";

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
      <div className="content" style={{ maxWidth: 480, margin: "4rem auto", padding: "0 24px" }}>
        <h1 style={{ fontFamily: "var(--font-display)", fontSize: 28, fontWeight: 500, color: "var(--text)" }}>
          Complete Registration
        </h1>
        <p style={{ color: "var(--brand-red)", fontFamily: "var(--font-body)" }}>No registration token provided.</p>
        <p>
          <a href="/auth/oidc" style={{ color: "var(--brand-blue)" }}>Start sign in again</a>
        </p>
      </div>
    );
  }

  return (
    <div className="content" style={{ maxWidth: 480, margin: "4rem auto", padding: "0 24px" }}>
      <h1 style={{ fontFamily: "var(--font-display)", fontSize: 28, fontWeight: 500, color: "var(--text)" }}>
        Complete Registration
      </h1>
      <p style={{ fontFamily: "var(--font-body)", color: "var(--text-secondary)", marginBottom: "1.5rem" }}>
        Finish setting up your tobornalp account.
      </p>

      <form onSubmit={handleSubmit} style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
        {error && (
          <p style={{ color: "var(--brand-red)", fontFamily: "var(--font-body)", fontSize: 14, margin: 0 }}>
            {error}{" "}
            <a href="/auth/oidc" style={{ color: "var(--brand-blue)" }}>Sign in again</a>
          </p>
        )}
        {email && (
          <label style={fieldStyle}>
            <span style={labelStyle}>Email</span>
            <input type="email" value={email} readOnly disabled style={inputStyle} />
          </label>
        )}
        <label style={fieldStyle}>
          <span style={labelStyle}>First name</span>
          <input
            type="text"
            value={first}
            onChange={(e) => setFirst(e.target.value)}
            required
            autoComplete="given-name"
            style={inputStyle}
          />
        </label>
        <label style={fieldStyle}>
          <span style={labelStyle}>Last name</span>
          <input
            type="text"
            value={last}
            onChange={(e) => setLast(e.target.value)}
            required
            autoComplete="family-name"
            style={inputStyle}
          />
        </label>
        <label style={fieldStyle}>
          <span style={labelStyle}>
            Invite code {inviteRequired ? <span style={{ color: "var(--brand-red)" }}>*</span> : <span style={{ color: "var(--text-muted)" }}>(optional)</span>}
          </span>
          <input
            type="text"
            value={inviteToken}
            onChange={(e) => setInviteToken(e.target.value)}
            placeholder={inviteRequired ? "Required for your email domain" : "If you have one"}
            style={inputStyle}
          />
        </label>
        <button
          type="submit"
          disabled={submitting}
          style={{
            background: "var(--brand-blue)",
            color: "#fff",
            fontFamily: "var(--font-sans)",
            fontWeight: 600,
            fontSize: 15,
            padding: "12px 20px",
            border: "none",
            borderRadius: 11,
            cursor: submitting ? "not-allowed" : "pointer",
            opacity: submitting ? 0.6 : 1,
            marginTop: "0.5rem",
          }}
        >
          {submitting ? "Creating account…" : "Create Account"}
        </button>
      </form>
    </div>
  );
}

const fieldStyle: React.CSSProperties = { display: "flex", flexDirection: "column", gap: "0.4rem" };
const labelStyle: React.CSSProperties = { fontFamily: "var(--font-mono)", fontSize: 12, fontWeight: 600, color: "var(--text-secondary)" };
const inputStyle: React.CSSProperties = {
  fontFamily: "var(--font-body)",
  fontSize: 15,
  padding: "11px 14px",
  borderRadius: 10,
  border: "1px solid var(--border)",
  background: "var(--surface)",
  color: "var(--text)",
};

export default function RegisterPage() {
  return (
    <Suspense fallback={<div className="content"><main><p>Loading…</p></main></div>}>
      <Register />
    </Suspense>
  );
}
