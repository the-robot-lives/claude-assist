import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// ⟦𓎔𓐉𓈮𓅲⟧ proxy :: auto-generated pointer for public function proxy
export function proxy(request: NextRequest) {
  const token = request.cookies.get("access_token")?.value;
  const appUrl = process.env.NEXT_PUBLIC_APP_URL;
  const host = request.headers.get("host") || "";
  const isAppHost = host.startsWith("app.");
  const isAppRoot = isAppHost && request.nextUrl.pathname === "/";
  const isAppPath = request.nextUrl.pathname.startsWith("/app");

  if (!isAppRoot && !isAppPath) {
    return NextResponse.next();
  }

  if (!isAppHost && appUrl && isAppPath) {
    const url = new URL(request.nextUrl.pathname + request.nextUrl.search, appUrl);
    return NextResponse.redirect(url);
  }

  if (!token) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("redirect", request.nextUrl.pathname);
    return NextResponse.redirect(loginUrl);
  }

  if (isAppRoot) {
    return NextResponse.rewrite(new URL("/app", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/", "/app/:path*"],
};
