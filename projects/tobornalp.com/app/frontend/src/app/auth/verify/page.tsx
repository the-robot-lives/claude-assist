"use client";

import { Suspense, useEffect, useState } from "react";
import { useAuth } from "@/context/auth";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";

function VerifyMagicLink() {
  const { loginWithMagicLink } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [error, setError] = useState("");
  const [verifying, setVerifying] = useState(true);

  useEffect(() => {
    const token = searchParams.get("token");
    if (!token) {
      setError("No token provided");
      setVerifying(false);
      return;
    }

    loginWithMagicLink(token)
      .then(() => router.push("/"))
      .catch(() => {
        setError("Invalid or expired magic link");
        setVerifying(false);
      });
  }, [searchParams, loginWithMagicLink, router]);

  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] px-6 py-16">
      <div className="w-full max-w-[420px] rounded-[14px] border border-[var(--line2)] bg-[var(--panel2)] p-8 text-center shadow-[0_2px_10px_rgba(0,0,0,.35)]">
        <div className="mb-6 flex items-baseline justify-center gap-1 font-mono">
          <span className="text-sm font-bold tracking-tight text-[var(--ink)]">tobornalp</span>
          <span className="text-sm font-bold text-[var(--acc)] motion-safe:animate-pulse">▮</span>
        </div>
        <h1 className="mb-4 font-mono text-lg font-bold text-[var(--ink)]">verify magic link</h1>
        {verifying && (
          <p className="font-mono text-[13px] text-[var(--mut)]">
            <span className="text-[var(--info)]">[info]</span> verifying your magic link…
          </p>
        )}
        {error && (
          <>
            <p className="mb-4 rounded-[10px] border border-[var(--err)]/30 bg-[var(--err-bg)] px-3 py-2 font-mono text-xs text-[var(--err)]">
              [err] {error}
            </p>
            <Link href="/login" className="font-mono text-xs text-[var(--acc)] hover:text-[var(--acc-hi)]">
              back to login
            </Link>
          </>
        )}
      </div>
    </div>
  );
}

export default function VerifyMagicLinkPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] font-mono text-sm text-[var(--mut)]">
          loading…
        </div>
      }
    >
      <VerifyMagicLink />
    </Suspense>
  );
}
