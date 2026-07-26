"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/context/auth";
import { OrgSwitcher } from "@/components/org-switcher";

/*
 * Global navbar — mounted in layout.tsx, shown on every route except the
 * org-scoped app shell, which carries its own rail and topbar (see
 * components/pm/org-nav.tsx). Two stacked bars would just eat vertical space.
 *
 * Uses the organic theme's CSS variables directly (--surface, --text,
 * --brand-blue, --border, --font-display) via the scoped .tn-* class
 * namespace and an injected <style> block, so it renders correctly
 * regardless of which design tokens the runtime exposes. The legacy
 * .sg-* classes had no styles in the organic theme and rendered raw.
 */
export function Navbar() {
  const { user, loading, logout } = useAuth();
  const pathname = usePathname();

  if (inOrgShell(pathname)) return null;

  return (
    <>
      <style>{NAV_CSS}</style>
      <nav className="tn-nav">
        <div className="tn-nav__inner">
          <Link href="/" className="tn-nav__brand" aria-label="tobornalp home">
            <BrandMark />
            <span className="tn-nav__brand-text">tobornalp</span>
          </Link>

          <div className="tn-nav__links">
            {loading ? null : user ? (
              <>
                <OrgSwitcher />
                <span className="tn-nav__user" title={user.email}>
                  {user.email}
                </span>
                <button onClick={logout} className="tn-btn tn-btn--ghost tn-btn--sm">
                  Log Out
                </button>
              </>
            ) : (
              <>
                <Link href="/login" className="tn-btn tn-btn--ghost tn-btn--sm">
                  Log In
                </Link>
                <a href="/auth/oidc" className="tn-btn tn-btn--primary tn-btn--sm">
                  Get Started
                </a>
              </>
            )}
          </div>
        </div>
      </nav>
    </>
  );
}

// `/app/<orgId>/…` is the org shell. `admin` and `profile` are static siblings
// of the [orgId] segment, so they route outside it and keep this navbar.
function inOrgShell(pathname: string | null): boolean {
  const seg = pathname?.split("/") ?? [];
  return seg[1] === "app" && !!seg[2] && seg[2] !== "admin" && seg[2] !== "profile";
}

/* Brand mark — matches the organic theme logo (circle + organic path) */
function BrandMark() {
  return (
    <svg
      className="tn-nav__brand-mark"
      width="24"
      height="24"
      viewBox="0 0 28 28"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
    >
      <circle cx="14" cy="14" r="12" stroke="var(--brand-blue)" strokeWidth="1.2" />
      <path
        d="M8 20 C10 10, 18 10, 20 20"
        stroke="var(--brand-blue)"
        strokeWidth="1"
        fill="none"
        opacity="0.5"
      />
      <circle cx="10" cy="12" r="2" fill="var(--brand-blue)" opacity="0.4" />
      <circle cx="18" cy="11" r="2.5" fill="var(--brand-blue)" opacity="0.3" />
      <circle cx="14" cy="16" r="1.5" fill="var(--brand-blue)" opacity="0.5" />
    </svg>
  );
}

const NAV_CSS = `
.tn-nav {
  position: sticky;
  top: 0;
  z-index: 50;
  background: color-mix(in srgb, var(--surface) 88%, transparent);
  backdrop-filter: saturate(140%) blur(8px);
  -webkit-backdrop-filter: saturate(140%) blur(8px);
  border-bottom: 1px solid var(--border);
}
.tn-nav__inner {
  max-width: 1040px;
  margin: 0 auto;
  padding: 0 24px;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}
.tn-nav__brand {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  text-decoration: none;
}
.tn-nav__brand-mark { flex-shrink: 0; }
.tn-nav__brand-text {
  font-family: var(--font-display);
  font-size: 21px;
  font-weight: 500;
  letter-spacing: 0.01em;
  color: var(--text);
}
.tn-nav__links {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  justify-content: flex-end;
}
.tn-nav__user {
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--text-muted);
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Buttons (shared with marketing page rhythm) */
.tn-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-family: var(--font-sans);
  font-weight: 600;
  font-size: 15px;
  padding: 11px 20px;
  border-radius: var(--r-pill);
  text-decoration: none;
  border: 1px solid transparent;
  cursor: pointer;
  transition: transform 120ms ease, background 160ms ease, color 160ms ease, border-color 160ms ease;
}
.tn-btn--sm { font-size: 13px; padding: 6px 16px; }
.tn-btn--primary { background: var(--acc); color: #000; }
.tn-btn--primary:hover { background: var(--acc-hi); transform: translateY(-1px); }
.tn-btn--ghost {
  background: transparent;
  color: var(--text);
  border-color: var(--border-strong, var(--border));
}
.tn-btn--ghost:hover { border-color: var(--brand-blue); color: var(--brand-blue); }

@media (max-width: 600px) {
  .tn-nav__inner { height: auto; padding: 12px 16px; flex-wrap: wrap; }
  .tn-nav__user { display: none; }
}
`;
