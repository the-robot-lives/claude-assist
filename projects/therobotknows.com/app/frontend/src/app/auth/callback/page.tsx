"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { request } from "@/lib/api/client";
import { isMockMode } from "@/lib/api/config";

/**
 * Backend SSO callback landing: ?code= from Guardian sso/exchange flow.
 * Authentik-direct PKCE is removed (ADR-006).
 */
function CallbackHandler() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const code = searchParams.get("code");
    if (!code) {
      setError("No authorization code received.");
      return;
    }

    (async () => {
      try {
        if (isMockMode()) {
          localStorage.setItem("access_token", "mock-access");
          localStorage.setItem("refresh_token", "mock-refresh");
          router.replace("/");
          return;
        }
        const data = await request<{
          access_token: string;
          refresh_token?: string;
        }>("/api/v1/auth/sso/exchange", {
          method: "POST",
          skipAuth: true,
          body: JSON.stringify({ code }),
        });
        localStorage.setItem("access_token", data.access_token);
        if (data.refresh_token) {
          localStorage.setItem("refresh_token", data.refresh_token);
        }
        router.replace("/");
      } catch {
        setError("Authentication failed. Please try again.");
      }
    })();
  }, [searchParams, router]);

  if (error) {
    return (
      <div className="text-center">
        <p className="font-sans text-sm text-[var(--flag-error)] mb-4">{error}</p>
        <a
          href="/login"
          className="font-mono text-[11px] uppercase tracking-[0.08em] text-[var(--accent)] hover:text-[var(--accent-hover)] transition-colors"
        >
          Back to sign in
        </a>
      </div>
    );
  }

  return (
    <div className="text-center">
      <div className="w-4 h-4 border-2 border-[var(--accent)] border-t-transparent rounded-full mx-auto mb-4 animate-spin" />
      <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
        Authenticating...
      </p>
    </div>
  );
}

export default function AuthCallback() {
  return (
    <div className="min-h-screen bg-page flex items-center justify-center">
      <Suspense
        fallback={
          <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
            Loading...
          </p>
        }
      >
        <CallbackHandler />
      </Suspense>
    </div>
  );
}
