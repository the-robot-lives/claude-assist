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
}

export interface Organization {
  id: string;
  slug: string;
  name: string;
  /** Auto-created per-user "Personal" org, distinct from real orgs. */
  personal?: boolean;
  role?: string;
}

export interface Project {
  id: string;
  organization_id: string;
  name: string;
  slug: string;
  description?: string | null;
  settings?: Record<string, unknown>;
  status: "active" | "archived" | "deleted" | string;
  archived_at?: string | null;
  inserted_at?: string;
  updated_at?: string;
}

/** Generic learning-content record (lesson plan, wiki page, quiz, reference, deck, …). */
export interface ContentItem {
  id: string;
  inserted_at?: string;
  updated_at?: string;
  [key: string]: unknown;
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

  listProjects(orgId: string) {
    return request<{ projects: Project[] }>(`/api/v1/organizations/${orgId}/projects`);
  },

  createProject(orgId: string, data: { name: string; slug: string; description?: string }) {
    return request<{ project: Project }>(`/api/v1/organizations/${orgId}/projects`, {
      method: "POST",
      body: JSON.stringify({ project: data }),
    });
  },

  getProject(orgId: string, projectId: string) {
    return request<{ project: Project }>(`/api/v1/organizations/${orgId}/projects/${projectId}`);
  },

  updateProject(orgId: string, projectId: string, data: Partial<Pick<Project, "name" | "description" | "settings">>) {
    return request<{ project: Project }>(`/api/v1/organizations/${orgId}/projects/${projectId}`, {
      method: "PATCH",
      body: JSON.stringify({ project: data }),
    });
  },

  listContent(orgId: string, projectId: string, type: string, parentId?: string) {
    const qs = parentId ? `?parent_id=${encodeURIComponent(parentId)}` : "";
    return request<{ items: ContentItem[] }>(
      `/api/v1/organizations/${orgId}/projects/${projectId}/content/${type}${qs}`,
    );
  },

  createContent(orgId: string, projectId: string, type: string, item: Record<string, unknown>) {
    return request<{ item: ContentItem }>(
      `/api/v1/organizations/${orgId}/projects/${projectId}/content/${type}`,
      { method: "POST", body: JSON.stringify({ item }) },
    );
  },

  updateContent(orgId: string, projectId: string, type: string, id: string, item: Record<string, unknown>) {
    return request<{ item: ContentItem }>(
      `/api/v1/organizations/${orgId}/projects/${projectId}/content/${type}/${id}`,
      { method: "PATCH", body: JSON.stringify({ item }) },
    );
  },

  deleteContent(orgId: string, projectId: string, type: string, id: string) {
    return request<{ ok: boolean }>(
      `/api/v1/organizations/${orgId}/projects/${projectId}/content/${type}/${id}`,
      { method: "DELETE" },
    );
  },

  archiveProject(orgId: string, projectId: string) {
    return request<{ project: Project }>(`/api/v1/organizations/${orgId}/projects/${projectId}/archive`, { method: "POST" });
  },

  unarchiveProject(orgId: string, projectId: string) {
    return request<{ project: Project }>(`/api/v1/organizations/${orgId}/projects/${projectId}/unarchive`, { method: "POST" });
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

  getCookieConsent(browserSessionId: string) {
    return request<{ consent: null | {
      version: number;
      categories: Record<string, boolean>;
      accepted_at?: string;
      updated_at?: string;
      requires_session_tracking?: boolean;
    } }>("/api/v1/consent/cookies", {
      headers: { "X-Browser-Session-Id": browserSessionId },
    });
  },

  saveCookieConsent(browserSessionId: string, consent: { version: number; categories: Record<string, boolean> }) {
    return request<{ consent: {
      version: number;
      categories: Record<string, boolean>;
      accepted_at?: string;
      updated_at?: string;
      requires_session_tracking?: boolean;
    }; requires_session_tracking?: boolean }>("/api/v1/consent/cookies", {
      method: "PUT",
      headers: { "X-Browser-Session-Id": browserSessionId },
      body: JSON.stringify({ consent }),
    });
  },
};
