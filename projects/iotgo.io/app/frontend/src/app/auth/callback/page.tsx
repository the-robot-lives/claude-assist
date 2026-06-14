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
        <p className="text-sm text-critical mb-4">{error}</p>
        <a
          href="/"
          className="text-[11px] font-bold uppercase tracking-widest text-accent hover:text-accent-hover transition-colors"
        >
          Back to home
        </a>
      </div>
    );
  }

  return (
    <div className="text-center">
      <div className="w-4 h-4 border-2 border-accent border-t-transparent rounded-full mx-auto mb-4 animate-spin" />
      <p className="text-[11px] font-bold uppercase tracking-widest text-text-tertiary">
        Authenticating...
      </p>
    </div>
  );
}

export default function AuthCallback() {
  return (
    <div className="min-h-screen bg-background flex items-center justify-center font-mono">
      <Suspense
        fallback={
          <p className="text-[11px] font-bold uppercase tracking-widest text-text-tertiary">
            Loading...
          </p>
        }
      >
        <CallbackHandler />
      </Suspense>
    </div>
  );
}
