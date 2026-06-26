import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// gotta.cc authenticates client-side via Authentik (PKCE; tokens in
// localStorage, see src/lib/auth.ts). The /dashboard route guards itself.
// No server-side cookie guard is needed, so the middleware is a no-op.
export function proxy(_request: NextRequest) {
  return NextResponse.next();
}

// Matcher points at an unused path so the middleware never runs on real routes.
export const config = {
  matcher: ["/__never__"],
};
