"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { authApi } from "@/lib/api/auth";
import Link from "next/link";

function Handler() {
  const search = useSearchParams();
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const err = search.get("error");
    if (err) {
      setError(
        err === "not_provisioned"
          ? "Your SSO account is not provisioned for this app."
          : `Authentication failed (${err}).`,
      );
      return;
    }
    const code = search.get("code");
    if (!code) {
      setError("No authorization code received.");
      return;
    }
    authApi
      .exchangeSsoCode(code)
      .then(() => router.replace("/app"))
      .catch(() => setError("SSO exchange failed. Please try again."));
  }, [search, router]);

  if (error) {
    return (
      <div className="text-center">
        <p className="mb-4 font-sans text-sm text-flag-error">{error}</p>
        <Link href="/login" className="font-mono text-[11px] uppercase text-accent">
          Back to sign in
        </Link>
      </div>
    );
  }

  return (
    <div className="text-center">
      <div className="mx-auto mb-4 h-4 w-4 animate-spin rounded-full border-2 border-accent border-t-transparent" />
      <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
        Completing Authentik sign-in…
      </p>
    </div>
  );
}

export default function SsoCallbackPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-page">
      <Suspense
        fallback={
          <p className="font-mono text-[11px] uppercase text-ink-tertiary">
            Loading…
          </p>
        }
      >
        <Handler />
      </Suspense>
    </div>
  );
}
