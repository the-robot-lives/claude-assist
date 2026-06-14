"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { handleCallback } from "@/lib/auth-pkce";

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
      <div style={{ textAlign: "center" }}>
        <p className="sg-error" style={{ marginBottom: "1rem" }}>{error}</p>
        <a
          href="/"
          className="sg-btn sg-btn--outline sg-btn--sm"
        >
          Back to home
        </a>
      </div>
    );
  }

  return (
    <div style={{ textAlign: "center" }}>
      <div
        style={{
          width: 24,
          height: 24,
          border: "2px solid var(--text-link)",
          borderTopColor: "transparent",
          borderRadius: "50%",
          margin: "0 auto 1rem",
          animation: "spin 0.8s linear infinite",
        }}
      />
      <p style={{ fontFamily: "var(--font-mono)", fontSize: "0.75rem", color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.08em" }}>
        Authenticating...
      </p>
    </div>
  );
}

export default function AuthCallback() {
  return (
    <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", background: "var(--surface)" }}>
      <Suspense
        fallback={
          <p style={{ fontFamily: "var(--font-mono)", fontSize: "0.75rem", color: "var(--text-muted)" }}>
            Loading...
          </p>
        }
      >
        <CallbackHandler />
      </Suspense>
    </div>
  );
}
