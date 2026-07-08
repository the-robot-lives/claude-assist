"use client";

import { Suspense, useEffect, useRef, useState } from "react";
import { useAuth } from "@/context/auth";
import { useRouter, useSearchParams } from "next/navigation";

const ERROR_MESSAGES: Record<string, string> = {
  not_provisioned: "No account exists for this email and self-registration is not available. Please contact your administrator.",
  sso_failed: "SSO authentication failed. Please try again.",
  oidc_failed: "OpenID Connect authentication failed.",
  google_failed: "Google sign-in failed.",
  facebook_failed: "Facebook sign-in failed.",
  github_failed: "GitHub sign-in failed.",
  linkedin_failed: "LinkedIn sign-in failed.",
};

function SSOCallback() {
  const { ssoExchange } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [error, setError] = useState("");
  const [verifying, setVerifying] = useState(true);
  // Guard against React StrictMode double-invocation consuming the one-time code twice.
  const ran = useRef(false);

  useEffect(() => {
    if (ran.current) return;
    const code = searchParams.get("code");
    const errorParam = searchParams.get("error");

    if (errorParam) {
      setError(ERROR_MESSAGES[errorParam] || "Authentication failed.");
      setVerifying(false);
      return;
    }

    if (!code) {
      setError("No authorization code provided.");
      setVerifying(false);
      return;
    }

    ran.current = true;
    ssoExchange(code)
      .then(() => router.push("/"))
      .catch(() => {
        setError("Failed to complete sign-in. The code may have expired.");
        setVerifying(false);
      });
  }, [searchParams, ssoExchange, router]);

  return (
    <div className="content" style={{ maxWidth: 480, margin: "4rem auto", padding: "0 24px" }}>
      <h1 style={{ fontFamily: "var(--font-display)", fontSize: 28, fontWeight: 500, color: "var(--text)" }}>
        Signing In
      </h1>
      {verifying && <p style={{ fontFamily: "var(--font-body)", color: "var(--text-secondary)" }}>Completing authentication…</p>}
      {error && (
        <>
          <p style={{ color: "var(--brand-red)", fontFamily: "var(--font-body)" }}>{error}</p>
          <p>
            <a href="/auth/oidc" style={{ color: "var(--brand-blue)" }}>Try again</a>
          </p>
        </>
      )}
    </div>
  );
}

export default function SSOCallbackPage() {
  return (
    <Suspense fallback={<div className="content"><main><p>Loading…</p></main></div>}>
      <SSOCallback />
    </Suspense>
  );
}
