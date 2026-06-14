"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { handleCallback } from "@/lib/auth";

function CallbackHandler() {
  const params = useSearchParams();
  const router = useRouter();
  const [error, setError] = useState(false);

  useEffect(() => {
    const code = params.get("code");
    if (!code) {
      setError(true);
      return;
    }
    handleCallback(code).then((ok) => {
      if (ok) {
        router.replace("/dashboard");
      } else {
        setError(true);
      }
    });
  }, [params, router]);

  if (error) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <div className="text-center">
          <p className="text-sm text-error">Authentication failed</p>
          <a
            href="/"
            className="mt-4 inline-block text-xs text-accent hover:underline"
          >
            Back to home
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-background">
      <div className="flex items-center gap-3">
        <div
          className="h-5 w-5 rounded-full border-2 border-accent border-t-transparent animate-spin"
        />
        <span className="text-sm text-text-secondary">Signing in&hellip;</span>
      </div>
    </div>
  );
}

export default function AuthCallbackPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-screen items-center justify-center bg-background">
          <span className="text-sm text-text-tertiary">Loading&hellip;</span>
        </div>
      }
    >
      <CallbackHandler />
    </Suspense>
  );
}
