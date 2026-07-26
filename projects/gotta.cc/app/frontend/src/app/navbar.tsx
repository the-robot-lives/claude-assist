"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { isAuthed, clearSession } from "@/lib/session";

function NavLink({
  href,
  label,
  active,
  secondary = false,
}: {
  href: string;
  label: string;
  active: boolean;
  secondary?: boolean;
}) {
  return (
    <Link
      href={href}
      className={`${active ? "gc-on" : ""} ${secondary ? "gc-nav-secondary" : ""}`}
    >
      {label}
    </Link>
  );
}

/**
 * Sticky masthead. `siteCount`, when known, personalises the search
 * placeholder ("Search 4,218 sites worth your time…").
 */
export function NavBar({ siteCount }: { siteCount?: number } = {}) {
  const pathname = usePathname();
  const router = useRouter();
  const searchRef = useRef<HTMLInputElement>(null);
  const [q, setQ] = useState("");

  const browseActive = pathname === "/";
  const aboutActive = pathname?.startsWith("/about") ?? false;
  const submitActive = pathname?.startsWith("/submit") ?? false;
  const mySubmissionsActive = pathname?.startsWith("/my-submissions") ?? false;

  // Native session is client-only (localStorage). Start logged-out so the
  // server render matches the first client render, then resolve in an effect.
  const [authed, setAuthed] = useState(false);
  useEffect(() => {
    setAuthed(isAuthed());
  }, [pathname]);

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        searchRef.current?.focus();
        searchRef.current?.select();
      }
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  function handleSignOut() {
    clearSession();
    setAuthed(false);
    window.location.assign("/");
  }

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    const trimmed = q.trim();
    if (trimmed) router.push(`/search?q=${encodeURIComponent(trimmed)}`);
  }

  const placeholder = siteCount
    ? `Search ${siteCount.toLocaleString()} sites worth your time…`
    : "Search sites worth your time…";

  return (
    <header className="gc-masthead">
      <div className="gc-wrap gc-masthead-inner">
        <Link href="/" className="gc-wordmark">
          gotta<span className="gc-tld">.cc</span>
        </Link>
        <span className="gc-wordmark-tag">A directory for a web worth reading</span>

        <form className="gc-searchbar" role="search" onSubmit={handleSearch}>
          <svg
            width="15"
            height="15"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth={2.2}
            strokeLinecap="round"
            aria-hidden="true"
          >
            <circle cx="11" cy="11" r="7" />
            <path d="M21 21l-4.3-4.3" />
          </svg>
          <input
            ref={searchRef}
            type="search"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder={placeholder}
            aria-label="Search sites"
          />
          <kbd className="gc-kbd">⌘K</kbd>
        </form>

        <nav className="gc-nav">
          <NavLink href="/" label="Browse" active={browseActive} />
          <NavLink href="/about" label="About" active={aboutActive} />
          {authed && (
            <NavLink
              href="/my-submissions"
              label="My submissions"
              active={mySubmissionsActive}
              secondary
            />
          )}
          {authed ? (
            <button onClick={handleSignOut}>Sign out</button>
          ) : (
            <NavLink href="/login" label="Sign in" active={false} />
          )}
          <Link
            href="/submit"
            className={`gc-btn-submit ${submitActive ? "gc-on" : ""}`}
          >
            Submit a site
          </Link>
        </nav>
      </div>
    </header>
  );
}
