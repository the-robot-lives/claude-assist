"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { handleCallback } from "@/lib/auth";

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

    handleCallback(code).then((ok) => {
      if (ok) {
        router.replace("/dashboard");
      } else {
        setError("Authentication failed. Please try again.");
      }
    });
  }, [searchParams, router]);

  if (error) {
    return (
      <div className="text-center">
        <p className="font-mono text-sm text-[var(--redline)] mb-4">{error}</p>
        <a
          href="/"
          className="font-mono text-[11px] uppercase tracking-[0.12em] text-[var(--anno-yellow)] hover:text-[var(--line-bright)] transition-colors"
        >
          Back to home
        </a>
      </div>
    );
  }

  return (
    <div className="text-center">
      <div
        className="w-4 h-4 border-2 border-[var(--anno-yellow)] border-t-transparent rounded-full mx-auto mb-4 animate-spin"
      />
      <p className="font-mono text-[11px] uppercase tracking-[0.12em] text-[var(--line-secondary)]">
        Authenticating...
      </p>
    </div>
  );
}

export default function AuthCallback() {
  return (
    <div className="min-h-screen flex items-center justify-center">
      <Suspense
        fallback={
          <p className="font-mono text-[11px] uppercase tracking-[0.12em] text-[var(--line-secondary)]">
            Loading...
          </p>
        }
      >
        <CallbackHandler />
      </Suspense>
    </div>
  );
}
