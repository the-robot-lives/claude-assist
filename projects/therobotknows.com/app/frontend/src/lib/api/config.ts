/**
 * API client configuration.
 *
 * NEXT_PUBLIC_API_MODE: "mock" | "live" — default **live** for real auth/API.
 * NEXT_PUBLIC_API_URL: backend origin (empty = same-origin /api proxy)
 */

export type ApiMode = "mock" | "live";

export function getApiMode(): ApiMode {
  if (process.env.NEXT_PUBLIC_API_MODE === "mock") return "mock";
  return "live";
}

export function getApiBaseUrl(): string {
  if (typeof window !== "undefined") {
    const runtime = (window as unknown as { __ENV?: { API_URL?: string } })
      .__ENV?.API_URL;
    if (runtime) return runtime.replace(/\/$/, "");
  }
  return (process.env.NEXT_PUBLIC_API_URL ?? "").replace(/\/$/, "");
}

/** Absolute origin for browser redirects to backend (SSO). */
export function getBackendOrigin(): string {
  const base = getApiBaseUrl();
  if (base) return base;
  if (typeof window !== "undefined") return window.location.origin;
  return "";
}

export function isMockMode(): boolean {
  return getApiMode() === "mock";
}
