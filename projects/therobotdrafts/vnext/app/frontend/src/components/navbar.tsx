"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/context/auth";
import { OrgSwitcher } from "@/components/org-switcher";

export function Navbar() {
  const { user, loading, logout } = useAuth();
  const pathname = usePathname();

  // The studio owns its whole viewport, and the landing page carries its own header.
  if (pathname === "/" || pathname === "/studio") return null;

  return (
    <nav className="sg-navbar">
      <div className="sg-navbar__inner">
        <Link href="/" className="sg-navbar__brand">
          The Robot Draft
        </Link>
        <div className="sg-navbar__links">
          {loading ? null : user ? (
            <>
              <OrgSwitcher />
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
