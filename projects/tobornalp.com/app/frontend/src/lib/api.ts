import { getRuntimeConfig, runtimeCookieDomainAttribute } from "@/lib/runtime-config";

function apiUrl() {
  return getRuntimeConfig().API_URL || process.env.NEXT_PUBLIC_API_URL || "";
}

export interface User {
  id: string;
  email: string;
  user_name?: string;
  handle?: string;
  mobile_phone?: string;
  status?: string;
  verified?: boolean;
  profile_completed_at?: string | null;
  profile_complete?: boolean;
  requires_profile_completion?: boolean;
  // Account-persisted cookie-consent categories (authoritative across subdomains).
  consent_preferences?: Record<string, boolean> | null;
}

export interface Organization {
  id: string;
  slug: string;
  name: string;
  role?: string;
}

interface AuthResponse {
  user: User;
  access_token: string;
  refresh_token: string;
  organizations?: Organization[];
}

export interface RegisterPayload {
  email: string;
  password: string;
  userName: string;
  firstName: string;
  lastName: string;
  mobilePhone: string;
  inviteToken?: string;
}

export interface CompleteRegistrationPayload {
  userName: string;
  firstName: string;
  lastName: string;
  mobilePhone: string;
  inviteToken?: string;
}

interface MagicLinkResponse {
  message: string;
  dev_link?: string;
}

interface OtpResponse {
  message: string;
  dev_code?: string;
}

interface PasswordResetResponse {
  message: string;
  dev_code?: string;
}

export interface SsoDomainPolicy {
  providers: string[];
  auto_approve?: boolean;
}

export type SsoDomainMap = Record<string, string[] | SsoDomainPolicy>;

interface SsoProvidersResponse {
  providers: string[];
  domains?: Record<string, string[]>;
  domain_policies?: Record<string, SsoDomainPolicy>;
}

let refreshPromise: Promise<string | null> | null = null;

function authCookie(value: string | null) {
  if (typeof document === "undefined") return;
  const domain = runtimeCookieDomainAttribute();
  try {
    if (value) {
      document.cookie = `access_token=${value}; path=/; max-age=${60 * 60}; SameSite=Lax${domain}`;
    } else {
      document.cookie = `access_token=; path=/; max-age=0; SameSite=Lax${domain}`;
    }
  } catch {
    // Localhost or strict browser policies can reject Domain cookies; localStorage remains canonical.
  }
}

async function attemptRefresh(): Promise<string | null> {
  const refreshToken = typeof window !== "undefined" ? localStorage.getItem("refresh_token") : null;
  if (!refreshToken) return null;

  try {
    const res = await fetch(`${apiUrl()}/api/v1/auth/refresh`, {
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
      // Sync cookie for middleware
      authCookie(data.access_token);
      return data.access_token;
    }
    return null;
  } catch {
    return null;
  }
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null;

  const res = await fetch(`${apiUrl()}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (res.status === 401 && token && !path.includes("/auth/refresh")) {
    // Deduplicate concurrent refresh attempts
    if (!refreshPromise) {
      refreshPromise = attemptRefresh().finally(() => { refreshPromise = null; });
    }

    const newToken = await refreshPromise;
    if (newToken) {
      // Retry the original request with the new token
      const retryRes = await fetch(`${apiUrl()}${path}`, {
        ...options,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${newToken}`,
          ...options.headers,
        },
      });

      if (!retryRes.ok) {
        const body = await retryRes.json().catch(() => ({}));
        throw new Error(body.error || body.errors?.email?.[0] || `Request failed: ${retryRes.status}`);
      }

      return retryRes.json();
    }

    // Refresh failed — clear tokens and redirect to login
    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    authCookie(null);
    if (typeof window !== "undefined") {
      window.location.href = "/login";
    }
  }

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || body.errors?.email?.[0] || `Request failed: ${res.status}`);
  }

  return res.json();
}

export const api = {
  register(payload: RegisterPayload) {
    return request<AuthResponse>("/api/v1/auth/register", {
      method: "POST",
      body: JSON.stringify({
        user: {
          email: payload.email,
          password: payload.password,
          user_name: payload.userName,
          first_name: payload.firstName,
          last_name: payload.lastName,
          mobile_phone: payload.mobilePhone,
        },
        invite_token: payload.inviteToken || undefined,
      }),
    });
  },

  login(email: string, password: string) {
    return request<AuthResponse>("/api/v1/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });
  },

  requestMagicLink(email: string) {
    return request<MagicLinkResponse>("/api/v1/auth/magic-link", {
      method: "POST",
      body: JSON.stringify({ email }),
    });
  },

  verifyMagicLink(token: string) {
    return request<AuthResponse>("/api/v1/auth/magic-link/verify", {
      method: "POST",
      body: JSON.stringify({ token }),
    });
  },

  requestOtpLogin(email: string) {
    return request<OtpResponse>("/api/v1/auth/otp-login", {
      method: "POST",
      body: JSON.stringify({ email }),
    });
  },

  verifyOtpLogin(email: string, code: string) {
    return request<AuthResponse>("/api/v1/auth/otp-login/verify", {
      method: "POST",
      body: JSON.stringify({ email, code }),
    });
  },

  requestPasswordReset(email: string) {
    return request<PasswordResetResponse>("/api/v1/auth/password-reset", {
      method: "POST",
      body: JSON.stringify({ email }),
    });
  },

  verifyPasswordReset(email: string, code: string, newPassword: string) {
    return request<{ message: string }>("/api/v1/auth/password-reset/verify", {
      method: "POST",
      body: JSON.stringify({ email, code, new_password: newPassword }),
    });
  },

  refresh(refreshToken: string) {
    return request<{ access_token: string; refresh_token?: string }>("/api/v1/auth/refresh", {
      method: "POST",
      body: JSON.stringify({ refresh_token: refreshToken }),
    });
  },

  ssoProviders() {
    return request<SsoProvidersResponse>("/api/v1/auth/sso/providers");
  },

  ssoExchange(code: string) {
    return request<AuthResponse>("/api/v1/auth/sso/exchange", {
      method: "POST",
      body: JSON.stringify({ code }),
    });
  },

  getRegistration(token: string) {
    return request<{ email: string; provider: string; invite_required?: boolean; auto_approve?: boolean }>(
      `/api/v1/auth/sso/registration?token=${encodeURIComponent(token)}`,
    );
  },

  ssoRegister(payload: { token: string; first: string; last: string; invite_token?: string; consent?: Record<string, boolean> }) {
    return request<AuthResponse>("/api/v1/auth/sso/register", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },

  // Persist cookie-consent categories on the account (crosses the apex → app.*
  // boundary; account value is authoritative). No-op safe when unauthenticated.
  updateConsent(preferences: Record<string, boolean>) {
    return request<{ consent_preferences: Record<string, boolean> }>("/api/v1/users/active/consent", {
      method: "PUT",
      body: JSON.stringify({ preferences }),
    });
  },

  me() {
    return request<{ user: User; organizations?: Organization[] }>("/api/v1/auth/me");
  },

  getProfile() {
    return request<{ user: User }>("/api/v1/users/me");
  },

  updateProfile(data: { user_name?: string; email?: string; mobile_phone?: string; first_name?: string; last_name?: string; current_password?: string; new_password?: string }) {
    return request<{ user: User }>("/api/v1/users/me", {
      method: "PATCH",
      body: JSON.stringify({ user: data }),
    });
  },

  completeRegistration(data: CompleteRegistrationPayload) {
    return request<{ user: User }>("/api/v1/users/me/complete-registration", {
      method: "POST",
      body: JSON.stringify({
        user: {
          user_name: data.userName,
          first_name: data.firstName,
          last_name: data.lastName,
          mobile_phone: data.mobilePhone,
          invite_token: data.inviteToken || undefined,
        },
      }),
    });
  },

  listOrganizations() {
    return request<{ organizations: Organization[] }>("/api/v1/organizations");
  },

  createOrganization(slug: string, name: string) {
    return request<{ organization: Organization }>("/api/v1/organizations", {
      method: "POST",
      body: JSON.stringify({ organization: { slug, name } }),
    });
  },

  getOrganization(id: string) {
    return request<{ organization: Organization }>(`/api/v1/organizations/${id}`);
  },

  sendVerificationEmail() {
    return request<{ message: string; dev_link?: string }>("/api/v1/auth/verify-email", {
      method: "POST",
    });
  },

  verifyEmail(token: string) {
    return request<{ message: string }>("/api/v1/auth/verify-email/confirm", {
      method: "POST",
      body: JSON.stringify({ token }),
    });
  },

  listMembers(orgId: string) {
    return request<{ members: Array<{ id: string; user_id: string; email: string; user_name: string; role: string; joined_at: string }> }>(`/api/v1/organizations/${orgId}/members`);
  },

  addMember(orgId: string, email: string, role: string) {
    return request<{ members: Array<{ id: string; user_id: string; email: string; user_name: string; role: string; joined_at: string }> }>(`/api/v1/organizations/${orgId}/members`, {
      method: "POST",
      body: JSON.stringify({ email, role }),
    });
  },

  updateMemberRole(orgId: string, memberId: string, role: string) {
    return request<{ members: Array<{ id: string; user_id: string; email: string; user_name: string; role: string; joined_at: string }> }>(`/api/v1/organizations/${orgId}/members/${memberId}`, {
      method: "PATCH",
      body: JSON.stringify({ role }),
    });
  },

  removeMember(orgId: string, memberId: string) {
    return request<{ message: string }>(`/api/v1/organizations/${orgId}/members/${memberId}`, {
      method: "DELETE",
    });
  },

  presignUpload(filename: string, contentType: string) {
    return request<{ upload_url: string; key: string }>("/api/v1/media/presign", {
      method: "POST",
      body: JSON.stringify({ filename, content_type: contentType }),
    });
  },

  getDownloadUrl(key: string) {
    return request<{ download_url: string }>("/api/v1/media/download", {
      method: "POST",
      body: JSON.stringify({ key }),
    });
  },

  adminListUsers(page = 1, perPage = 50) {
    return request<{ users: Array<{ id: string; email: string; user_name: string; status: string; verified: boolean; admin: boolean; created_at: string }>; total: number; page: number; per_page: number }>(`/api/v1/admin/users?page=${page}&per_page=${perPage}`);
  },

  adminShowUser(id: string) {
    return request<{ user: User & { admin: boolean; created_at: string } }>(`/api/v1/admin/users/${id}`);
  },

  adminApproveUser(id: string) {
    return request<{ user: User & { admin: boolean; created_at: string } }>(`/api/v1/admin/users/${id}/approve`, {
      method: "POST",
    });
  },

  adminListOrganizations(page = 1, perPage = 50) {
    return request<{ organizations: Array<{ id: string; slug: string; name: string; created_at: string }>; total: number; page: number; per_page: number }>(`/api/v1/admin/organizations?page=${page}&per_page=${perPage}`);
  },

  adminShowOrganization(id: string) {
    return request<{ organization: { id: string; slug: string; name: string; created_at: string }; members: Array<{ id: string; email: string; role: string }> }>(`/api/v1/admin/organizations/${id}`);
  },

  getFeatureFlags() {
    return request<{ features: string[] }>("/api/v1/config/features");
  },

  // ── Items (work tracking) ──────────────────────────────────────────────────
  listItems(orgId: string, params?: { project_id?: string; status?: string; item_type?: string; priority?: string; assignee?: string; queue_id?: string; stage_id?: string }) {
    const qs = new URLSearchParams(Object.entries(params || {}).filter(([, v]) => v != null && v !== "") as [string, string][]).toString();
    return request<{ items: Item[] }>(`/api/v1/organizations/${orgId}/items${qs ? `?${qs}` : ""}`);
  },
  getItem(orgId: string, id: string) {
    return request<{ item: Item; links: { outgoing: ItemLink[]; incoming: ItemLink[] } }>(`/api/v1/organizations/${orgId}/items/${id}`);
  },
  createItem(orgId: string, data: Partial<Item>) {
    return request<{ item: Item }>(`/api/v1/organizations/${orgId}/items`, {
      method: "POST",
      body: JSON.stringify({ item: data }),
    });
  },
  updateItem(orgId: string, id: string, data: Partial<Item>) {
    return request<{ item: Item }>(`/api/v1/organizations/${orgId}/items/${id}`, {
      method: "PATCH",
      body: JSON.stringify({ item: data }),
    });
  },

  // ── Boards (queues + stages + iterations) ─────────────────────────────────
  listQueues(orgId: string, projectId?: string) {
    const qs = projectId ? `?project_id=${projectId}` : "";
    return request<{ queues: ItemQueue[]; methodologies: string[] }>(`/api/v1/organizations/${orgId}/queues${qs}`);
  },
  getQueue(orgId: string, id: string) {
    return request<{ queue: ItemQueue }>(`/api/v1/organizations/${orgId}/queues/${id}`);
  },
  createQueue(orgId: string, data: { name: string; slug: string; methodology?: string; project_id?: string; description?: string }) {
    return request<{ queue: ItemQueue }>(`/api/v1/organizations/${orgId}/queues`, {
      method: "POST",
      body: JSON.stringify({ queue: data }),
    });
  },

  // ── Item type/field definitions (tri-scoped) ───────────────────────────────
  listFieldDefinitions(orgId: string, projectId?: string) {
    const qs = projectId ? `?project_id=${projectId}` : "";
    return request<{ fields: ItemFieldDefinition[] }>(`/api/v1/organizations/${orgId}/definitions/fields${qs}`);
  },
  listTypeDefinitions(orgId: string, projectId?: string) {
    const qs = projectId ? `?project_id=${projectId}` : "";
    return request<{ types: ItemTypeDefinition[] }>(`/api/v1/organizations/${orgId}/definitions/types${qs}`);
  },

  // ── Notifications inbox (recipient = authenticated user) ───────────────────
  listNotifications(orgId: string, cursor = 0) {
    return request<{ notifications: Notification[]; next_cursor?: number; throttled?: boolean; retry_after_ms?: number }>(`/api/v1/organizations/${orgId}/notifications?cursor=${cursor}`);
  },
  unreadCount(orgId: string) {
    return request<{ unread: number }>(`/api/v1/organizations/${orgId}/notifications/count`);
  },
  markNotificationsRead(orgId: string, ids?: string[]) {
    return request<{ marked_read: number }>(`/api/v1/organizations/${orgId}/notifications/mark_read`, {
      method: "POST",
      body: JSON.stringify(ids ? { ids } : {}),
    });
  },

  // ── OKRs (objectives + key results + check-ins) ────────────────────────────
  listObjectives(orgId: string, params?: { owner_id?: string; level?: string; status?: string; project_id?: string }) {
    const qs = new URLSearchParams(Object.entries(params || {}).filter(([, v]) => v != null && v !== "") as [string, string][]).toString();
    return request<{ objectives: Objective[] }>(`/api/v1/organizations/${orgId}/objectives${qs ? `?${qs}` : ""}`);
  },
  getObjective(orgId: string, id: string) {
    return request<{ objective: ObjectiveDetail }>(`/api/v1/organizations/${orgId}/objectives/${id}`);
  },
  createObjective(orgId: string, data: Partial<Objective>) {
    return request<{ objective: Objective }>(`/api/v1/organizations/${orgId}/objectives`, {
      method: "POST",
      body: JSON.stringify({ objective: data }),
    });
  },
  updateObjective(orgId: string, id: string, data: Partial<Objective>) {
    return request<{ objective: Objective }>(`/api/v1/organizations/${orgId}/objectives/${id}`, {
      method: "PATCH",
      body: JSON.stringify({ objective: data }),
    });
  },
  createKeyResult(orgId: string, objectiveId: string, data: Partial<KeyResult>) {
    return request<{ key_result: KeyResult }>(`/api/v1/organizations/${orgId}/objectives/${objectiveId}/key_results`, {
      method: "POST",
      body: JSON.stringify({ key_result: data }),
    });
  },
  createCheckin(orgId: string, objectiveId: string, data: { body: string; period?: string }) {
    return request<{ checkin: OkrCheckin }>(`/api/v1/organizations/${orgId}/objectives/${objectiveId}/checkins`, {
      method: "POST",
      body: JSON.stringify({ checkin: data }),
    });
  },

  // ── Today (unified daily plan for the authenticated user) ──────────────────
  today(orgId?: string, dueWindowDays?: number) {
    const qs = new URLSearchParams(
      Object.entries({ org_id: orgId, due_window_days: dueWindowDays?.toString() })
        .filter(([, v]) => v != null && v !== "")
        .map(([k, v]) => [k, String(v)]),
    ).toString();
    return request<{ plan: TodayPlan }>(`/api/v1/today${qs ? `?${qs}` : ""}`);
  },
};

// ── Domain types (mirror the backend schemas) ─────────────────────────────────
export interface Item {
  id: string;
  key?: string;
  number?: number;
  organization_id: string;
  project_id?: string;
  title: string;
  description?: string;
  item_type: string;
  status: string;
  priority?: string;
  assignee?: string;
  reporter?: string;
  queue_id?: string;
  parent_id?: string;
  stage_id?: string;
  iteration_id?: string;
  custom_fields?: Record<string, unknown>;
  inserted_at?: string;
  updated_at?: string;
}

export interface ItemLink {
  id: string;
  link_type: string;
  target_item_id?: string;
  source_item_id?: string;
}

export interface ItemQueue {
  id: string;
  name: string;
  slug: string;
  methodology?: string;
  description?: string;
  organization_id?: string;
  project_id?: string;
  config?: Record<string, unknown>;
  stages?: BoardStage[];
  iterations?: BoardIteration[];
}

export interface BoardStage {
  id: string;
  slug: string;
  name: string;
  kind?: string;
  position: number;
  wip_limit?: number;
}

export interface BoardIteration {
  id: string;
  name: string;
  sequence: number;
  status: string;
  starts_on?: string;
  ends_on?: string;
}

export interface ItemFieldDefinition {
  id: string;
  slug: string;
  label: string;
  field_type: string;
  organization_id?: string;
  project_id?: string;
  options?: Record<string, unknown>;
  default_value?: string;
  description?: string;
  disabled?: boolean;
}

export interface ItemTypeDefinition {
  id: string;
  slug: string;
  name: string;
  description?: string;
  organization_id?: string;
  project_id?: string;
  icon?: string;
  status_workflow?: Record<string, unknown>;
  disabled?: boolean;
  fields?: Array<{ id: string; slug: string; label: string; field_type: string; required: boolean; position: number }>;
}

export interface Notification {
  id: string;
  seq?: number;
  kind: string;
  sender?: string;
  subject_type?: string;
  subject_id?: string;
  body?: string;
  payload?: Record<string, unknown>;
  seen?: boolean;
  read?: boolean;
  inserted_at?: string;
}

export interface Objective {
  id: string;
  title: string;
  level: string;
  status: string;
  period?: string;
  owner_id?: string;
  organization_id?: string;
  project_id?: string;
  description?: string;
  progress?: string;
}

export interface ObjectiveDetail extends Objective {
  key_results?: KeyResult[];
  checkins?: OkrCheckin[];
}

export interface KeyResult {
  id: string;
  objective_id?: string;
  title: string;
  target_value?: string | number;
  current_value?: string | number;
  auto_progress?: boolean;
  status?: string;
  due_on?: string;
  unit?: string;
}

export interface OkrCheckin {
  id: string;
  body: string;
  period?: string;
  inserted_at?: string;
}

export interface TodayPlan {
  user_id: string;
  assigned?: Item[];
  due_soon?: Item[];
  objectives?: Objective[];
  key_results?: Array<{ kr_id: string; objective_id: string; title: string; target: string | number; current: string | number }>;
  unread_notifications?: number | null;
}
