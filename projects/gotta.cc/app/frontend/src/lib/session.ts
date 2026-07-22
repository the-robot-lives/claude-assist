// Native-auth token store for gotta.cc site submitters.
//
// This is intentionally SEPARATE from the Authentik OIDC client in
// `src/lib/auth.ts`. It manages the native (email + password) session that the
// submission / claim / moderation flows run on. The shared `request<T>` helper
// in `src/lib/api.ts` sources its Bearer token from here.
//
// Storage: the access/refresh tokens live under the same `access_token` /
// `refresh_token` localStorage keys the shared fetch layer already reads, so
// the existing auto-refresh path keeps working. The cached native user object
// lives under a dedicated `gotta_user` key — its presence is what marks a
// genuine native session (`isAuthed()`), distinct from an Authentik login.

import type { AuthResponse, AuthUser } from "./api";

const ACCESS_KEY = "access_token";
const REFRESH_KEY = "refresh_token";
const USER_KEY = "gotta_user";

function hasWindow(): boolean {
  return typeof window !== "undefined";
}

/** Persist a native auth response (tokens + user) after register/login. */
export function saveSession(res: AuthResponse): void {
  if (!hasWindow()) return;
  localStorage.setItem(ACCESS_KEY, res.access_token);
  if (res.refresh_token) localStorage.setItem(REFRESH_KEY, res.refresh_token);
  localStorage.setItem(USER_KEY, JSON.stringify(res.user));
  // Mirror the cookie the shared fetch layer keeps for parity.
  document.cookie = `access_token=${res.access_token}; path=/; max-age=${60 * 60}; SameSite=Lax`;
}

/** Current native access token (Bearer), or null. */
export function getAccessToken(): string | null {
  return hasWindow() ? localStorage.getItem(ACCESS_KEY) : null;
}

/** Current native refresh token, or null. */
export function getRefreshToken(): string | null {
  return hasWindow() ? localStorage.getItem(REFRESH_KEY) : null;
}

/** Cached native user, or null if there is no native session. */
export function getUser(): AuthUser | null {
  if (!hasWindow()) return null;
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AuthUser;
  } catch {
    return null;
  }
}

/** Clear the native session (sign out). Leaves the Authentik id_token alone. */
export function clearSession(): void {
  if (!hasWindow()) return;
  localStorage.removeItem(ACCESS_KEY);
  localStorage.removeItem(REFRESH_KEY);
  localStorage.removeItem(USER_KEY);
  document.cookie = "access_token=; path=/; max-age=0; SameSite=Lax";
}

/** True when a native (email/password) session is present. */
export function isAuthed(): boolean {
  return getUser() !== null;
}
