"use client";

import { Suspense, useEffect, useState } from "react";
import { useAuth } from "@/context/auth";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { postAuthPath } from "@/lib/auth-flow";

const ERROR_MESSAGES: Record<string, string> = {
  not_provisioned: "No account exists for this email. Please contact your administrator.",
  sso_unavailable: "SSO is not available for this email domain.",
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

  useEffect(() => {
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

    ssoExchange(code)
      .then((user) => router.push(postAuthPath(user)))
      .catch(() => {
        setError("Failed to complete sign-in. The code may have expired.");
        setVerifying(false);
      });
  }, [searchParams, ssoExchange, router]);

  return (
    <div className="content">
      <main>
        <h1 className="sg-page-title">Signing In</h1>
        {verifying && <p>Completing authentication...</p>}
        {error && (
          <>
            <p className="sg-error">{error}</p>
            <p><Link href="/login">Back to login</Link></p>
          </>
        )}
      </main>
    </div>
  );
}

// ⟦𓊧𓁮𓆜𓁷⟧ SSOCallbackPage :: auto-generated pointer for public function SSOCallbackPage
export default function SSOCallbackPage() {
  return (
    <Suspense fallback={<div className="content"><main><p>Loading...</p></main></div>}>
      <SSOCallback />
    </Suspense>
  );
}
