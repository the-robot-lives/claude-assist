"use client";

import Link from "next/link";
import { KnowledgeBaseLogo } from "@/components/layout/knowledge-base-logo";
import { isLoggedIn } from "@/lib/auth";
import { useEffect, useState } from "react";

export function MarketingHeader() {
  const [loggedIn, setLoggedIn] = useState(false);
  useEffect(() => {
    setLoggedIn(isLoggedIn());
  }, []);

  return (
    <header className="sticky top-0 z-40 border-b border-rule-subtle bg-page/90 backdrop-blur-md">
      <div className="mx-auto flex h-16 max-w-6xl items-center gap-4 px-6">
        <Link href="/" className="flex items-center gap-2.5 shrink-0">
          <KnowledgeBaseLogo size={30} className="text-ink" />
          <span className="font-serif text-[15px] font-semibold uppercase tracking-[0.06em] text-ink">
            TheRobotKnows
          </span>
        </Link>
        <nav className="ml-auto hidden items-center gap-1 sm:flex">
          <a
            href="#features"
            className="rounded-lg px-3 py-2 font-sans text-[13px] text-ink-secondary transition-colors hover:text-ink"
          >
            Features
          </a>
          <a
            href="#how"
            className="rounded-lg px-3 py-2 font-sans text-[13px] text-ink-secondary transition-colors hover:text-ink"
          >
            How it works
          </a>
          <a
            href="#beta"
            className="rounded-lg px-3 py-2 font-sans text-[13px] text-ink-secondary transition-colors hover:text-ink"
          >
            Free beta
          </a>
        </nav>
        <div className="flex items-center gap-2">
          {loggedIn ? (
            <Link
              href="/app"
              className="rounded-lg bg-accent px-4 py-2 font-sans text-[13px] font-medium text-white transition-colors hover:bg-accent-hover"
            >
              Open app
            </Link>
          ) : (
            <>
              <Link
                href="/login"
                className="rounded-lg px-3 py-2 font-mono text-[11px] uppercase tracking-[0.06em] text-accent transition-colors hover:text-accent-hover"
              >
                Sign in
              </Link>
              <Link
                href="/register"
                className="rounded-lg bg-ink px-4 py-2 font-sans text-[13px] font-medium text-page transition-opacity hover:opacity-90"
              >
                Join free beta
              </Link>
            </>
          )}
        </div>
      </div>
    </header>
  );
}
