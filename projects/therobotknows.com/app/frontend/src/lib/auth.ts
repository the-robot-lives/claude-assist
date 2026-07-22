/**
 * Auth helpers for TheRobotKnows.
 *
 * Per ADR-006: Phoenix Guardian is the sole token authority.
 * The frontend never talks to Authentik directly — use backend
 * `/api/v1/auth/*` (and optional backend OIDC start URLs for SSO).
 */

import { authApi, clearTokens, type AuthUser } from "@/lib/api/auth";

export type { AuthUser };

export async function login(email: string, password: string) {
  return authApi.login(email, password);
}

export async function register(email: string, password: string, userName?: string) {
  return authApi.register(email, password, userName);
}

export async function getCurrentUser(): Promise<AuthUser | null> {
  if (!authApi.isLoggedIn()) return null;
  try {
    const res = await authApi.me();
    return res?.user ?? null;
  } catch {
    return null;
  }
}

/** @deprecated Prefer getCurrentUser() — kept for residual UI that decoded id_token. */
export function getUser(): { email?: string; name?: string } | null {
  if (typeof window === "undefined") return null;
  if (!localStorage.getItem("access_token")) return null;
  // Synchronous stub for layout chrome; full user comes from /auth/me.
  return { email: undefined, name: undefined };
}

export function logout() {
  authApi.logout();
  if (typeof window !== "undefined") {
    window.location.href = "/login";
  }
}

export function isLoggedIn(): boolean {
  return authApi.isLoggedIn();
}

/**
 * Optional SSO: redirect to backend OIDC start (ueberauth), not Authentik.
 * Backend issues Guardian tokens after callback + sso/exchange.
 */
export function startSsoLogin(provider = "oidc") {
  const base = process.env.NEXT_PUBLIC_API_URL || "";
  window.location.href = `${base}/auth/${provider}`;
}

export { clearTokens };
