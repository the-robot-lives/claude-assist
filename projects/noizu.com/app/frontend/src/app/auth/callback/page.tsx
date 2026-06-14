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
        <p className="text-sm text-red-400 mb-4">{error}</p>
        <a
          href="/"
          className="text-sm text-gold-400 hover:text-gold-300 transition-colors"
        >
          Back to home
        </a>
      </div>
    );
  }

  return (
    <div className="text-center">
      <div className="w-5 h-5 border-2 border-gold-400 border-t-transparent rounded-full mx-auto mb-4 animate-spin" />
      <p className="text-sm text-zinc-400 font-mono">Authenticating...</p>
    </div>
  );
}

export default function AuthCallback() {
  return (
    <div className="min-h-screen bg-zinc-950 flex items-center justify-center">
      <Suspense
        fallback={
          <p className="text-sm text-zinc-400 font-mono">Loading...</p>
        }
      >
        <CallbackHandler />
      </Suspense>
    </div>
  );
}
