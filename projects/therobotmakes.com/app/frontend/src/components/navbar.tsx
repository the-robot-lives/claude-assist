"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/context/auth";
import { OrgSwitcher } from "@/components/org-switcher";
import { CookieSettingsButton } from "@/components/cookie-consent";

// Routes that render the standalone blueprint theme with their own nav.
const BLUEPRINT_ROUTES = ["/", "/dashboard", "/auth/callback"];

export function Navbar() {
  const { user, loading, logout } = useAuth();
  const pathname = usePathname();

  if (BLUEPRINT_ROUTES.includes(pathname)) return null;

  return (
    <nav className="sg-navbar">
      <div className="sg-navbar__inner">
        <Link href="/" className="sg-navbar__brand">
          Project Name
        </Link>
        <div className="sg-navbar__links">
          <CookieSettingsButton />
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
