"use client";

import { Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { handleCallback } from "@/lib/auth";

function CallbackHandler() {
  const params = useSearchParams();
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const code = params.get("code");
    if (!code) {
      setError("No authorization code received.");
      return;
    }

    handleCallback(code).then((ok) => {
      if (ok) {
        router.replace("/dashboard");
      } else {
        setError("Token exchange failed. Please try again.");
      }
    });
  }, [params, router]);

  return (
    <div
      style={{
        minHeight: "100dvh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "var(--surface, #FAF7F2)",
        color: "var(--text, #2C1810)",
        fontFamily: "var(--font-body, 'Lora', serif)",
      }}
    >
      <div style={{ textAlign: "center", maxWidth: 400, padding: 32 }}>
        {error ? (
          <>
            <p style={{ fontSize: 16, marginBottom: 20 }}>{error}</p>
            <a
              href="/"
              style={{
                color: "var(--teal, #4A7B6F)",
                fontSize: 14,
                textDecoration: "underline",
              }}
            >
              Back to home
            </a>
          </>
        ) : (
          <p style={{ fontSize: 15, color: "var(--text-secondary, #8E8E96)" }}>
            Signing you in…
          </p>
        )}
      </div>
    </div>
  );
}

export default function AuthCallbackPage() {
  return (
    <Suspense
      fallback={
        <div
          style={{
            minHeight: "100dvh",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "var(--surface, #FAF7F2)",
            color: "var(--text-secondary, #8E8E96)",
            fontFamily: "var(--font-body, 'Lora', serif)",
            fontSize: 15,
          }}
        >
          Loading…
        </div>
      }
    >
      <CallbackHandler />
    </Suspense>
  );
}
