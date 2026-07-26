"use client";

import { useEffect } from "react";
import { useAuth } from "@/context/auth";
import { useRouter } from "next/navigation";

export default function PendingApprovalPage() {
  const { user, loading, logout } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) router.push("/login");
    if (!loading && user && user.status !== "pending" && user.status !== "waitlist") router.push("/app");
  }, [loading, router, user]);

  if (loading || !user) return null;

  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-[var(--bg)] px-6 py-16">
      <div className="w-full max-w-[420px] rounded-[14px] border border-[var(--line2)] bg-[var(--panel2)] p-8 text-center shadow-[0_2px_10px_rgba(0,0,0,.35)]">
        <div className="mb-6 flex items-baseline justify-center gap-1 font-mono">
          <span className="text-sm font-bold tracking-tight text-[var(--ink)]">tobornalp</span>
          <span className="text-sm font-bold text-[var(--acc)] motion-safe:animate-pulse">▮</span>
        </div>
        <h1 className="mb-3 font-mono text-lg font-bold text-[var(--ink)]">pending approval</h1>
        <p className="mb-6 font-mono text-[13px] text-[var(--mut)]">
          <span className="text-[var(--info)]">[info]</span> your account is registered and waiting for manual approval.
        </p>
        <button
          type="button"
          onClick={logout}
          className="inline-flex w-full items-center justify-center rounded-full border border-[var(--line2)] bg-[var(--panel2)] px-5 py-2.5 font-mono text-sm font-semibold text-[var(--ink)] transition-colors hover:border-[var(--faint)]"
        >
          log out
        </button>
      </div>
    </div>
  );
}
