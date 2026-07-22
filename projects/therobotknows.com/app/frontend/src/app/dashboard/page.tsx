"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

/** Legacy /dashboard → /app */
export default function LegacyDashboardRedirect() {
  const router = useRouter();
  useEffect(() => {
    router.replace("/app");
  }, [router]);
  return (
    <div className="flex min-h-screen items-center justify-center bg-page font-mono text-[11px] uppercase text-ink-tertiary">
      Redirecting…
    </div>
  );
}
