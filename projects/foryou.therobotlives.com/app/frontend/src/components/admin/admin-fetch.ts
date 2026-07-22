// Local authed fetch wrappers for the admin console (Chunk D).
//
// We deliberately do NOT import from `@/lib/api` for new methods — that file is
// shared with other agents. This module mirrors its bearer-token + 401-refresh
// pattern locally so the admin console owns its own network surface.
//
// Built against the REAL shipped Chunk B contract (verified 2026-07-22), which
// diverges from PRD-M3 in several places; see notes on each method.

const API_URL = process.env.NEXT_PUBLIC_API_URL || "";

// ---- token / refresh (mirrors src/lib/api.ts) -----------------------------

let refreshPromise: Promise<string | null> | null = null;

async function attemptRefresh(): Promise<string | null> {
  const refreshToken =
    typeof window !== "undefined" ? localStorage.getItem("refresh_token") : null;
  if (!refreshToken) return null;
  try {
    const res = await fetch(`${API_URL}/api/v1/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: refreshToken }),
    });
    if (!res.ok) return null;
    const data = await res.json();
    if (data.access_token) {
      localStorage.setItem("access_token", data.access_token);
      if (data.refresh_token) localStorage.setItem("refresh_token", data.refresh_token);
      document.cookie = `access_token=${data.access_token}; path=/; max-age=${60 * 60}; SameSite=Lax`;
      return data.access_token;
    }
    return null;
  } catch {
    return null;
  }
}

function authHeader(token: string | null): Record<string, string> {
  return token ? { Authorization: `Bearer ${token}` } : {};
}

function redirectToLogin() {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
  document.cookie = "access_token=; path=/; max-age=0; SameSite=Lax";
  if (typeof window !== "undefined") window.location.href = "/login";
}

/** Error carrying the HTTP status so callers can branch (403 / 404). */
export class AdminApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = "AdminApiError";
    this.status = status;
  }
}

/** Raw authed fetch with one transparent refresh-and-retry on 401. */
async function authedFetch(path: string, options: RequestInit = {}): Promise<Response> {
  const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null;
  const res = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: { ...authHeader(token), ...options.headers },
  });

  if (res.status === 401 && token && !path.includes("/auth/refresh")) {
    if (!refreshPromise) {
      refreshPromise = attemptRefresh().finally(() => {
        refreshPromise = null;
      });
    }
    const newToken = await refreshPromise;
    if (newToken) {
      return fetch(`${API_URL}${path}`, {
        ...options,
        headers: { ...authHeader(newToken), ...options.headers },
      });
    }
    redirectToLogin();
  }
  return res;
}

/** JSON GET with error surfacing (status-aware). */
async function getJson<T>(path: string): Promise<T> {
  const res = await authedFetch(path, {
    headers: { "Content-Type": "application/json" },
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({} as { error?: string }));
    throw new AdminApiError(body.error || `Request failed: ${res.status}`, res.status);
  }
  return res.json();
}

// ---- types -----------------------------------------------------------------

export type ListKind = "newsletter" | "waitlist" | "inquiry" | "contact" | "mixed";
export type ListStatus = "active" | "archived";
export type SignupStatus = "pending_optin" | "subscribed" | "unsubscribed" | "bounced";

export interface AdminService {
  id: string;
  slug: string;
  name: string;
  status?: string;
  list_count?: number | null;
  signup_count?: number | null;
}

export interface ListSettings {
  opt_in_mode?: "double" | "single";
  [k: string]: unknown;
}

export interface AdminList {
  id: string;
  project_id: string;
  slug: string;
  public_slug: string;
  name: string;
  description?: string | null;
  kind: ListKind;
  status: ListStatus;
  settings?: ListSettings;
  signup_count: number;
}

export interface AdminSignup {
  id: string;
  email: string;
  status: SignupStatus;
  attribs: Record<string, unknown>;
  source?: string | null;
  user_id?: string | null;
  inserted_at: string;
}

export interface SignupsPage {
  signups: AdminSignup[];
  pagination: { limit: number; offset: number; total: number };
}

// Derived opt-in mode: prefer explicit settings, else derive from kind (D-notes / PRD FR-004).
export function optInMode(list: Pick<AdminList, "kind" | "settings">): "double" | "single" {
  if (list.settings?.opt_in_mode) return list.settings.opt_in_mode;
  return list.kind === "newsletter" || list.kind === "mixed" ? "double" : "single";
}

// ---- endpoints (real Chunk B contract) -------------------------------------

/**
 * Services (projects) for an org. The shipped browser surface has no
 * `?with_counts=`; counts are aggregated client-side from each service's lists.
 */
export function adminListServices(orgId: string) {
  return getJson<{ projects?: AdminService[]; organizations?: AdminService[] }>(
    `/api/v1/organizations/${orgId}/projects`
  );
}

/** Lists for a service. Returns per-list live `signup_count`. */
export function adminListLists(orgId: string, projectId: string) {
  return getJson<{ lists: AdminList[] }>(
    `/api/v1/organizations/${orgId}/projects/${projectId}/lists`
  );
}

/** Single list (flat route, returns archived too). */
export function adminShowList(listId: string) {
  return getJson<{ list: AdminList }>(`/api/v1/lists/${listId}`);
}

/**
 * Signups for a list. Real params are `status` + `limit`/`offset` only
 * (no server-side q/sort). Text search + sort are applied client-side.
 */
export function adminListSignups(
  listId: string,
  opts: { status?: string; limit?: number; offset?: number } = {}
) {
  const params = new URLSearchParams();
  if (opts.status) params.set("status", opts.status);
  params.set("limit", String(opts.limit ?? 50));
  params.set("offset", String(opts.offset ?? 0));
  return getJson<SignupsPage>(`/api/v1/lists/${listId}/signups?${params.toString()}`);
}

/** Fetch every signup page (bounded) for a list — used by CSV export. */
export async function adminFetchAllSignups(
  listId: string,
  opts: { status?: string } = {},
  hardCap = 50000
): Promise<AdminSignup[]> {
  const pageSize = 500;
  const all: AdminSignup[] = [];
  let offset = 0;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const res = await adminListSignups(listId, {
      status: opts.status,
      limit: pageSize,
      offset,
    });
    all.push(...res.signups);
    offset += res.signups.length;
    if (res.signups.length < pageSize || offset >= res.pagination.total || offset >= hardCap) {
      break;
    }
  }
  return all;
}

// ---- inquiries (defensive: backend surface may not exist yet) --------------

export interface AdminInquiry {
  id: string;
  name?: string | null;
  email: string;
  message?: string | null;
  source?: string | null;
  page_url?: string | null;
  metadata?: Record<string, unknown> | null;
  status: string;
  inserted_at?: string;
  created_at?: string;
}

/**
 * Admin inquiries index. The shipped router has NO admin inquiries surface yet
 * (only public POST /inquiries). This calls the PRD-specified endpoint and lets
 * the caller degrade gracefully on 404 (see AdminApiError.status).
 */
export function adminListInquiries(
  opts: { q?: string; status?: string; source?: string; page?: number; per_page?: number } = {}
) {
  const params = new URLSearchParams();
  if (opts.q) params.set("q", opts.q);
  if (opts.status) params.set("status", opts.status);
  if (opts.source) params.set("source", opts.source);
  params.set("page", String(opts.page ?? 1));
  params.set("per_page", String(opts.per_page ?? 50));
  return getJson<{
    inquiries: AdminInquiry[];
    total: number;
    page: number;
    per_page: number;
  }>(`/api/v1/admin/inquiries?${params.toString()}`);
}

// ---- CSV (RFC-4180, UTF-8 w/ BOM) — D5 -------------------------------------

/** Escape one field per RFC-4180: quote if it contains comma, quote, CR or LF. */
function csvField(value: unknown): string {
  const s = value === null || value === undefined ? "" : String(value);
  if (/[",\r\n]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}

/**
 * Build an RFC-4180 CSV (UTF-8 BOM) for signups. Columns:
 *   email, status, source, created_at + one column per declared attribute key.
 * `attributeKeys` is the ordered union of attribute keys discovered in the data
 * (there is no browser-facing attribute-schema endpoint in the shipped backend).
 */
export function signupsToCsv(signups: AdminSignup[], attributeKeys: string[]): string {
  const header = ["email", "status", "source", "created_at", ...attributeKeys];
  const rows = signups.map((s) => {
    const base = [s.email, s.status, s.source ?? "", s.inserted_at];
    const attrs = attributeKeys.map((k) => {
      const v = s.attribs?.[k];
      return Array.isArray(v) ? v.join("; ") : (v ?? "");
    });
    return [...base, ...attrs].map(csvField).join(",");
  });
  // ﻿ BOM so Excel reads UTF-8 correctly.
  return "﻿" + [header.map(csvField).join(","), ...rows].join("\r\n") + "\r\n";
}

/** Trigger a browser download of a CSV string. */
export function downloadCsv(filename: string, csv: string) {
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

/** Ordered union of attribute keys present across a set of signups. */
export function collectAttributeKeys(signups: AdminSignup[]): string[] {
  const seen = new Set<string>();
  const order: string[] = [];
  for (const s of signups) {
    for (const k of Object.keys(s.attribs ?? {})) {
      // skip provenance/system envelopes (e.g. listmonk backfill metadata)
      if (k === "listmonk") continue;
      if (!seen.has(k)) {
        seen.add(k);
        order.push(k);
      }
    }
  }
  return order;
}
