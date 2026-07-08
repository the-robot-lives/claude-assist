import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const APP_HOST_PREFIX = "app.";

const PASSTHROUGH = [
  "/app",
  "/api",
  "/auth",
  "/_next",
  "/login",
  "/signup",
  "/forgot-password",
  "/complete-registration",
  "/pending-approval",
  "/session-cookie-required",
  "/sitemap",
  "/styleguide",
  "/health",
];

function isPassthrough(pathname: string) {
  return (
    pathname.includes(".") ||
    PASSTHROUGH.some((path) => pathname === path || pathname.startsWith(`${path}/`))
  );
}

export function proxy(request: NextRequest) {
  const token = request.cookies.get("access_token")?.value;
  const appUrl = process.env.NEXT_PUBLIC_APP_URL;
  const host = request.headers.get("host") || "";
  const isAppHost = host.toLowerCase().startsWith(APP_HOST_PREFIX);
  const { pathname } = request.nextUrl;

  let effectivePath = pathname;
  if (isAppHost && !isPassthrough(pathname)) {
    effectivePath = pathname === "/" ? "/app" : `/app${pathname}`;
  }

  const isAppPath = effectivePath === "/app" || effectivePath.startsWith("/app/");

  if (!isAppPath) {
    return NextResponse.next();
  }

  if (!isAppHost && appUrl) {
    const url = new URL(effectivePath + request.nextUrl.search, appUrl);
    return NextResponse.redirect(url);
  }

  if (!token) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("redirect", pathname);
    return NextResponse.redirect(loginUrl);
  }

  if (effectivePath !== pathname) {
    const url = request.nextUrl.clone();
    url.pathname = effectivePath;
    return NextResponse.rewrite(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
