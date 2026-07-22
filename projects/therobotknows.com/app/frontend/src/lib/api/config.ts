/**
 * API client configuration.
 *
 * NEXT_PUBLIC_API_MODE: "mock" | "live" (default mock until M1 backends land)
 * NEXT_PUBLIC_API_URL: base URL for live mode (empty = same-origin / nginx proxy)
 */

export type ApiMode = "mock" | "live";

export function getApiMode(): ApiMode {
  const mode = process.env.NEXT_PUBLIC_API_MODE;
  if (mode === "live") return "live";
  return "mock";
}

export function getApiBaseUrl(): string {
  return process.env.NEXT_PUBLIC_API_URL ?? "";
}

export function isMockMode(): boolean {
  return getApiMode() === "mock";
}
