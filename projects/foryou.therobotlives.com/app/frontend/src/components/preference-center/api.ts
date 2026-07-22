// Local API client for the Preference Center (Chunk E).
//
// Deliberately self-contained: the shared `src/lib/api.ts` is owned by other
// agents, so this module carries its own bearer-token + 401-refresh fetch
// wrapper (mirrors the pattern at `src/lib/api.ts:73`). All `/api/v1/me/*`
// endpoints are account-scoped and require an authenticated Guardian session.

const API_URL = process.env.NEXT_PUBLIC_API_URL || "";

// ---------------------------------------------------------------------------
// Types — forward-compatible with the documented SignupView (PRD-M3) while
// tolerating the leaner shape Chunk B's serializer ships today.
// ---------------------------------------------------------------------------

export type Frequency = "immediate" | "daily" | "weekly" | "monthly";

export const CHANNEL_KEYS = [
  "email",
  "sms",
  "push",
  "webhook",
  "physical_mail",
] as const;
export type ChannelKey = (typeof CHANNEL_KEYS)[number];

export interface QuietPeriod {
  start: string; // "22:00"
  end: string; // "07:00"
  timezone?: string;
  days?: string[]; // ["mon","tue",...]
}

export interface ContactPrefs {
  frequency?: Frequency;
  channels?: Partial<Record<ChannelKey, boolean>>;
  quiet_periods?: QuietPeriod[];
}

export type SignupStatus =
  | "subscribed"
  | "pending_optin"
  | "unsubscribed"
  | "bounced";

export interface ListRef {
  id: string;
  name: string;
  public_slug?: string;
  slug?: string;
  kind?: string;
  // Present once Chunk B joins list defaults; consumed for inheritance/channels.
  settings?: {
    contact_prefs?: ContactPrefs;
    available_channels?: ChannelKey[];
  } | null;
}

export interface ServiceRef {
  id?: string;
  name?: string;
  slug?: string;
  branding?: { name?: string } | null;
}

export interface SignupView {
  id: string;
  email: string;
  status: SignupStatus;
  attribs?: Record<string, unknown> | null;
  contact_prefs?: ContactPrefs | null; // subscriber override; {} => inherit
  pause_until?: string | null;
  source?: string | null;
  inserted_at: string;
  subscribed_at?: string | null; // reserved (Chunk B may add)
  list?: ListRef | null;
  service?: ServiceRef | null; // reserved (Chunk B may add)
  can_resubscribe?: boolean; // reserved; defaults handled in UI
}

// Inquiries endpoint returns a union: inquiry-kind signups + legacy rows
// (tagged source:"legacy", with name/message and no status/list — D9).
export interface InquiryView {
  id: string;
  source?: string | null;
  legacy_source?: string | null;
  status?: SignupStatus;
  email?: string;
  name?: string;
  message?: string;
  attribs?: Record<string, unknown> | null;
  contact_prefs?: ContactPrefs | null;
  list?: ListRef | null;
  inserted_at: string;
}

export interface ContactPrefsBody {
  contact_prefs?: ContactPrefs;
  pause_until?: string | null;
  reset_to_default?: true;
}

export interface MyExport {
  user?: { email?: string };
  generated_at?: string;
  signups?: SignupView[];
  inquiries?: InquiryView[];
  [k: string]: unknown;
}

// ---------------------------------------------------------------------------
// Fetch wrapper (bearer token + single-flight 401 refresh + retry).
// ---------------------------------------------------------------------------

let refreshPromise: Promise<string | null> | null = null;

async function attemptRefresh(): Promise<string | null> {
  const refreshToken =
    typeof window !== "undefined"
      ? localStorage.getItem("refresh_token")
      : null;
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
      if (data.refresh_token) {
        localStorage.setItem("refresh_token", data.refresh_token);
      }
      document.cookie = `access_token=${data.access_token}; path=/; max-age=${60 * 60}; SameSite=Lax`;
      return data.access_token;
    }
    return null;
  } catch {
    return null;
  }
}

/** Error carrying the HTTP status so callers can branch (404 => remove row, etc.). */
export class PcApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = "PcApiError";
    this.status = status;
  }
}

async function extractError(res: Response): Promise<PcApiError> {
  const body = await res.json().catch(() => ({}));
  const msg =
    body.error ||
    body.errors?.email?.[0] ||
    body.message ||
    `Request failed: ${res.status}`;
  return new PcApiError(msg, res.status);
}

async function pcRequest<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const token =
    typeof window !== "undefined"
      ? localStorage.getItem("access_token")
      : null;

  const res = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (res.status === 401 && token && !path.includes("/auth/refresh")) {
    if (!refreshPromise) {
      refreshPromise = attemptRefresh().finally(() => {
        refreshPromise = null;
      });
    }
    const newToken = await refreshPromise;
    if (newToken) {
      const retryRes = await fetch(`${API_URL}${path}`, {
        ...options,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${newToken}`,
          ...options.headers,
        },
      });
      if (!retryRes.ok) throw await extractError(retryRes);
      return parseBody<T>(retryRes);
    }
    // Refresh failed — clear session and bounce to login (preserve return path).
    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    document.cookie = "access_token=; path=/; max-age=0; SameSite=Lax";
    if (typeof window !== "undefined") {
      window.location.href = "/login?next=/app/me";
    }
    throw new PcApiError("Session expired", 401);
  }

  if (!res.ok) throw await extractError(res);
  return parseBody<T>(res);
}

async function parseBody<T>(res: Response): Promise<T> {
  if (res.status === 204) return {} as T;
  const text = await res.text();
  if (!text) return {} as T;
  return JSON.parse(text) as T;
}

// ---------------------------------------------------------------------------
// Endpoint methods.
// ---------------------------------------------------------------------------

export const pcApi = {
  getMySignups: () =>
    pcRequest<{ signups: SignupView[] }>("/api/v1/me/signups"),

  getMyInquiries: () =>
    pcRequest<{ inquiries: InquiryView[] }>("/api/v1/me/inquiries"),

  // DELETE returns 204 today; tolerate an optional JSON body.
  unsubscribeMySignup: (id: string) =>
    pcRequest<{ id?: string; status?: string }>(
      `/api/v1/me/signups/${id}`,
      { method: "DELETE" },
    ),

  updateMySignupPrefs: (id: string, body: ContactPrefsBody) =>
    pcRequest<{ signup: SignupView }>(`/api/v1/me/signups/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  resubscribeMySignup: (id: string) =>
    pcRequest<{ signup: SignupView }>(
      `/api/v1/me/signups/${id}/resubscribe`,
      { method: "POST" },
    ),

  resumeMySignup: (id: string) =>
    pcRequest<{ signup: SignupView }>(`/api/v1/me/signups/${id}/resume`, {
      method: "POST",
    }),

  exportMyData: () => pcRequest<MyExport>("/api/v1/me/export"),

  requestDeletion: () =>
    pcRequest<{ status: string }>("/api/v1/me/deletion-request", {
      method: "POST",
      body: JSON.stringify({ confirm: true }),
    }),
};
