import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// The dashboard is served on app.tobornalp.com. Its routes live under /app/* in
// the Next app dir. This middleware does two things:
//   1. On the app.* subdomain, rewrite clean paths into /app/* so the subdomain
//      root *is* the dashboard (app.tobornalp.com/<orgId>/today → /app/...).
//   2. Gate the dashboard (/app/*) behind the access_token cookie.
// The apex (tobornalp.com) marketing site is otherwise untouched.
const APP_HOST_PREFIX = "app.";

// Root-level paths that must NOT be prefixed with /app on the subdomain:
// backend/auth routes and the shared marketing/auth pages that live at root.
const PASSTHROUGH = [
  "/app",
  "/api",
  "/auth",
  "/_next",
  "/login",
  "/signup",
  "/forgot-password",
  "/sitemap",
  "/styleguide",
  "/health",
];

function isPassthrough(pathname: string) {
  return (
    pathname.includes(".") ||
    PASSTHROUGH.some((p) => pathname === p || pathname.startsWith(`${p}/`))
  );
}

export function middleware(req: NextRequest) {
  const host = (req.headers.get("host") || "").toLowerCase();
  const isAppHost = host.startsWith(APP_HOST_PREFIX);
  const { pathname } = req.nextUrl;

  // 1) Resolve the effective (internal) path.
  let effectivePath = pathname;
  if (isAppHost && !isPassthrough(pathname)) {
    effectivePath = pathname === "/" ? "/app" : `/app${pathname}`;
  }

  // 2) Auth gate for dashboard routes.
  if (effectivePath === "/app" || effectivePath.startsWith("/app/")) {
    const token = req.cookies.get("access_token")?.value;
    if (!token) {
      const loginUrl = new URL("/login", req.url);
      loginUrl.searchParams.set("redirect", pathname);
      return NextResponse.redirect(loginUrl);
    }
  }

  // 3) Apply the rewrite when the subdomain remapped the path.
  if (effectivePath !== pathname) {
    const url = req.nextUrl.clone();
    url.pathname = effectivePath;
    return NextResponse.rewrite(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
