"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { startLogin } from "@/lib/auth";
import { isAuthed, clearSession } from "@/lib/session";

function AsteriskMark({ className = "h-7 w-7" }: { className?: string }) {
  return (
    <svg
      className={`shrink-0 ${className}`}
      viewBox="0 0 200 200"
      aria-hidden="true"
    >
      <g transform="translate(100,100)" style={{ fill: "var(--coral)" }}>
        <rect x="-8" y="-65" width="16" height="130" rx="8" />
        <rect x="-8" y="-65" width="16" height="130" rx="8" transform="rotate(60)" />
        <rect x="-8" y="-65" width="16" height="130" rx="8" transform="rotate(120)" />
      </g>
    </svg>
  );
}

function NavLink({
  href,
  label,
  active,
}: {
  href: string;
  label: string;
  active: boolean;
}) {
  return (
    <Link
      href={href}
      className={`hidden font-ui text-sm font-semibold transition-colors duration-200 hover:text-ink sm:inline ${
        active ? "text-ink" : "text-ink-secondary"
      }`}
    >
      {label}
    </Link>
  );
}

export function NavBar() {
  const pathname = usePathname();
  const browseActive = pathname === "/";
  const searchActive = pathname?.startsWith("/search") ?? false;
  const aboutActive = pathname?.startsWith("/about") ?? false;
  const submitActive = pathname?.startsWith("/submit") ?? false;
  const mySubmissionsActive = pathname?.startsWith("/my-submissions") ?? false;

  // Native session is client-only (localStorage). Start logged-out so the
  // server render matches the first client render, then resolve in an effect.
  const [authed, setAuthed] = useState(false);
  useEffect(() => {
    setAuthed(isAuthed());
  }, [pathname]);

  function handleSignOut() {
    clearSession();
    setAuthed(false);
    window.location.assign("/");
  }

  return (
    <nav className="sticky top-0 z-50 border-b border-rule bg-cream/95 backdrop-blur-sm">
      <div className="mx-auto flex max-w-[960px] items-center justify-between px-6 py-4">
        <Link href="/" className="flex items-center gap-2.5">
          <AsteriskMark className="h-7 w-7" />
          <span
            className="font-display text-2xl font-bold text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            gotta.cc
          </span>
        </Link>
        <div className="flex items-center gap-8">
          <NavLink href="/" label="Browse" active={browseActive} />
          <NavLink href="/search" label="Search" active={searchActive} />
          <NavLink href="/about" label="About" active={aboutActive} />
          <NavLink href="/submit" label="Submit" active={submitActive} />
          {authed && (
            <NavLink
              href="/my-submissions"
              label="My Submissions"
              active={mySubmissionsActive}
            />
          )}
          {authed ? (
            <button
              onClick={handleSignOut}
              className="hidden font-ui text-sm font-semibold text-olive transition-colors duration-200 hover:text-olive-hover sm:inline"
            >
              Sign out
            </button>
          ) : (
            <Link
              href="/login"
              className="hidden font-ui text-sm font-semibold text-olive transition-colors duration-200 hover:text-olive-hover sm:inline"
            >
              Log in
            </Link>
          )}
          <button
            onClick={() => startLogin()}
            className="font-ui text-sm font-semibold text-olive hover:text-olive-hover transition-colors duration-200"
          >
            Sign In
          </button>
          <Link
            href="/about#waitlist"
            className="rounded-xl bg-coral px-5 py-2 font-ui text-sm font-semibold text-white transition-all duration-150 hover:-translate-y-0.5 hover:bg-coral-hover"
          >
            Join Waitlist
          </Link>
        </div>
      </div>
    </nav>
  );
}
