"use client";

import { Suspense, useEffect, useRef, useState } from "react";
import { useAuth } from "@/context/auth";
import { useRouter, useSearchParams } from "next/navigation";
import { postAuthPath } from "@/lib/auth-flow";

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
      .then((user) => router.push(postAuthPath(user)))
      .catch(() => {
        setError("Failed to complete sign-in. The code may have expired.");
        setVerifying(false);
      });
  }, [searchParams, ssoExchange, router]);

  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] px-6 py-16">
      <div className="w-full max-w-[420px] rounded-[14px] border border-[var(--line2)] bg-[var(--panel2)] p-8 shadow-[0_2px_10px_rgba(0,0,0,.35)]">
        <div className="mb-6 flex items-baseline gap-1 font-mono">
          <span className="text-sm font-bold tracking-tight text-[var(--ink)]">therobotplans</span>
          <span className="text-sm font-bold text-[var(--acc)] motion-safe:animate-pulse">▮</span>
        </div>
        <h1 className="mb-4 font-mono text-lg font-bold text-[var(--ink)]">signing in</h1>
        {verifying && (
          <p className="font-mono text-[13px] text-[var(--mut)]">
            <span className="text-[var(--info)]">[info]</span> completing authentication…
          </p>
        )}
        {error && (
          <>
            <p className="mb-4 rounded-[10px] border border-[var(--err)]/30 bg-[var(--err-bg)] px-3 py-2 font-mono text-xs text-[var(--err)]">
              [err] {error}
            </p>
            <a href="/auth/oidc" className="font-mono text-xs text-[var(--acc)] hover:text-[var(--acc-hi)]">
              try again
            </a>
          </>
        )}
      </div>
    </div>
  );
}

export default function SSOCallbackPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] font-mono text-sm text-[var(--mut)]">
          loading…
        </div>
      }
    >
      <SSOCallback />
    </Suspense>
  );
}
