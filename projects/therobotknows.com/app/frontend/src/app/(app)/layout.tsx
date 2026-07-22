"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, usePathname } from "next/navigation";
import { KnowledgeBaseLogo } from "@/components/layout/knowledge-base-logo";
import { isLoggedIn, getCurrentUser, logout } from "@/lib/auth";

export default function AppShellLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const [ready, setReady] = useState(false);
  const [userEmail, setUserEmail] = useState<string | null>(null);

  useEffect(() => {
    if (!isLoggedIn()) {
      router.replace(`/login?next=${encodeURIComponent(pathname || "/app")}`);
      return;
    }
    getCurrentUser().then((user) => {
      setUserEmail(user?.email ?? user?.user_name ?? null);
      setReady(true);
    });
  }, [router, pathname]);

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-page font-mono text-[11px] uppercase tracking-[0.12em] text-ink-tertiary">
        Loading workspace…
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-page">
      <header className="sticky top-0 z-20 border-b border-rule-subtle bg-surface/95 backdrop-blur-sm">
        <div className="mx-auto flex h-14 max-w-6xl items-center gap-3 px-6">
          <Link href="/app" className="flex shrink-0 items-center gap-2.5">
            <KnowledgeBaseLogo size={28} className="text-ink" />
            <span className="font-serif text-[15px] font-semibold uppercase tracking-[0.04em] text-ink">
              Knowledge Base
            </span>
          </Link>
          <div className="flex-1" />
          <nav className="flex items-center gap-1">
            <Link
              href="/app"
              className="rounded px-3 py-1.5 font-sans text-[13px] text-ink-secondary transition-colors hover:text-ink"
            >
              Universes
            </Link>
            <Link
              href="/settings"
              className="rounded px-3 py-1.5 font-sans text-[13px] text-ink-secondary transition-colors hover:text-ink"
            >
              Settings
            </Link>
            <span className="max-w-[160px] truncate px-2 py-1.5 font-mono text-[11px] text-ink-tertiary">
              {userEmail}
            </span>
            <button
              type="button"
              onClick={() => logout()}
              className="px-3 py-1.5 font-mono text-[11px] uppercase tracking-[0.06em] text-accent transition-colors hover:text-accent-hover"
            >
              Sign out
            </button>
          </nav>
        </div>
      </header>
      <main className="mx-auto max-w-6xl px-6 py-10">{children}</main>
    </div>
  );
}
