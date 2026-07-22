/**
 * Auth helpers — Guardian tokens via backend only (ADR-006).
 * Authentik is reached only through backend /auth/oidc.
 */

import { authApi, clearTokens, type AuthUser } from "@/lib/api/auth";

export type { AuthUser };

export async function login(email: string, password: string) {
  return authApi.login(email, password);
}

export async function register(
  email: string,
  password: string,
  inviteToken: string,
  userName?: string,
) {
  return authApi.register({ email, password, inviteToken, userName });
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

export function logout() {
  authApi.logout();
  if (typeof window !== "undefined") {
    window.location.href = "/";
  }
}

export function isLoggedIn(): boolean {
  return authApi.isLoggedIn();
}

export function startSsoLogin() {
  authApi.startOidcLogin();
}

export { clearTokens, authApi };
