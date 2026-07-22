"use client";

import Link from "next/link";
import { useAuth } from "@/context/auth";
import { OrgSwitcher } from "@/components/org-switcher";

export function Navbar() {
  const { user, loading, logout } = useAuth();

  return (
    <nav className="sg-navbar">
      <div className="sg-navbar__inner">
        <Link href="/" className="sg-navbar__brand">
          FORYOU
        </Link>
        <div className="sg-navbar__links">
          {loading ? null : user ? (
            <>
              <OrgSwitcher />
              <Link href="/app/me" className="sg-navbar__user">
                My preferences
              </Link>
              <span className="sg-navbar__user">{user.email}</span>
              <button onClick={logout} className="sg-btn sg-btn--outline sg-btn--sm">
                Log Out
              </button>
            </>
          ) : (
            <>
              <Link href="/login" className="sg-btn sg-btn--outline sg-btn--sm">
                Log In
              </Link>
              <Link href="/signup" className="sg-btn sg-btn--black sg-btn--sm">
                Sign Up
              </Link>
            </>
          )}
        </div>
      </div>
    </nav>
  );
}
