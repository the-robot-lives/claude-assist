import { getAccessToken, getRefreshToken } from "./session";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "";

export interface User {
  id: string;
  email: string;
  user_name?: string;
  handle?: string;
  status?: string;
  verified?: boolean;
}

// Native-auth user is structurally the same as User. Aliased so the
// native-auth surface (session store, auth methods) reads intentionally.
export type AuthUser = User;

export interface DirectorySubmission {
  id: string;
  name: string;
  url: string;
  domain: string;
  summary: string;
  proposed_category_slug: string;
  tags: string[];
  status: "pending" | "in_review" | "approved" | "rejected" | "published";
  reviewer_notes: string | null;
  published_site_slug: string | null;
  inserted_at: string;
  // Present only on the admin moderation queue.
  submitter_email?: string;
  // True when the suggestion came in without an account; `contact_email` is
  // whatever the visitor volunteered, and is often null.
  anonymous?: boolean;
  contact_email?: string | null;
}

export interface SiteClaim {
  id: string;
  site_slug?: string;
  method: "meta_tag" | "dns_txt";
  status?: "pending" | "verified" | "failed";
  token: string;
  // Copy-paste guidance returned when a claim is started.
  instructions?: string;
  verified_at?: string | null;
}

export interface SubmissionScores {
  originality: number;
  human_authorship: number;
  depth: number;
  freshness: number;
  design_quality: number;
}

export interface Organization {
  id: string;
  slug: string;
  name: string;
  role?: string;
}

export interface DirectoryCategory {
  id: string;
  slug: string;
  name: string;
  display_order: number;
  site_count: number;
}

export interface DirectorySite {
  id: string;
  slug: string;
  name: string;
  url: string;
  domain: string;
  summary: string;
  category: { slug: string; name: string };
  tags: string[];
  scores: {
    originality: number;
    human_authorship: number;
    depth: number;
    freshness: number;
    design_quality: number;
    overall: number;
  };
  featured: boolean;
}

export interface AuthResponse {
  user: AuthUser;
  access_token: string;
  refresh_token: string;
  organizations?: Organization[];
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

let refreshPromise: Promise<string | null> | null = null;

async function attemptRefresh(): Promise<string | null> {
  const refreshToken = getRefreshToken();
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
      // Sync cookie for middleware
      document.cookie = `access_token=${data.access_token}; path=/; max-age=${60 * 60}; SameSite=Lax`;
      return data.access_token;
    }
    return null;
  } catch {
    return null;
  }
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getAccessToken();

  const res = await fetch(`${API_URL}${path}`, {
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
      const retryRes = await fetch(`${API_URL}${path}`, {
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
    document.cookie = "access_token=; path=/; max-age=0; SameSite=Lax";
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
  directoryCategories() {
    return request<{ categories: DirectoryCategory[] }>("/api/v1/directory/categories");
  },

  directorySites(params?: {
    category?: string;
    tag?: string;
    sort?: "featured" | "top" | "newest" | "random";
    q?: string;
    limit?: number;
    offset?: number;
  }) {
    const qs = new URLSearchParams(
      Object.entries(params || {})
        .filter(([, v]) => v != null && v !== "")
        .map(([k, v]) => [k, String(v)])
    ).toString();
    return request<{ sites: DirectorySite[] }>(`/api/v1/directory/sites${qs ? `?${qs}` : ""}`);
  },

  directorySite(slug: string) {
    return request<{ site: DirectorySite }>(`/api/v1/directory/sites/${encodeURIComponent(slug)}`);
  },

  directorySearch(q: string) {
    return request<{ sites: DirectorySite[] }>(`/api/v1/directory/search?q=${encodeURIComponent(q)}`);
  },

  register(email: string, password: string, inviteToken: string) {
    return request<AuthResponse>("/api/v1/auth/register", {
      method: "POST",
      body: JSON.stringify({ user: { email, password }, invite_token: inviteToken }),
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
    return request<{ providers: string[] }>("/api/v1/auth/sso/providers");
  },

  ssoExchange(code: string) {
    return request<AuthResponse>("/api/v1/auth/sso/exchange", {
      method: "POST",
      body: JSON.stringify({ code }),
    });
  },

  me() {
    return request<{ user: User }>("/api/v1/auth/me");
  },

  getProfile() {
    return request<{ user: User }>("/api/v1/users/me");
  },

  updateProfile(data: { user_name?: string; email?: string; current_password?: string; new_password?: string }) {
    return request<{ user: User }>("/api/v1/users/me", {
      method: "PATCH",
      body: JSON.stringify({ user: data }),
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

  adminListOrganizations(page = 1, perPage = 50) {
    return request<{ organizations: Array<{ id: string; slug: string; name: string; created_at: string }>; total: number; page: number; per_page: number }>(`/api/v1/admin/organizations?page=${page}&per_page=${perPage}`);
  },

  adminShowOrganization(id: string) {
    return request<{ organization: { id: string; slug: string; name: string; created_at: string }; members: Array<{ id: string; email: string; role: string }> }>(`/api/v1/admin/organizations/${id}`);
  },

  getFeatureFlags() {
    return request<{ features: string[] }>("/api/v1/config/features");
  },

  // ── Native auth (parallel to the Authentik OIDC client) ──────────────────

  authRegister(email: string, password: string, userName: string) {
    return request<AuthResponse>("/api/v1/auth/register", {
      method: "POST",
      body: JSON.stringify({ email, password, user_name: userName }),
    });
  },

  authLogin(email: string, password: string) {
    return request<AuthResponse>("/api/v1/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });
  },

  authRefresh(refreshToken: string) {
    return request<{ access_token: string; refresh_token: string }>("/api/v1/auth/refresh", {
      method: "POST",
      body: JSON.stringify({ refresh_token: refreshToken }),
    });
  },

  authMe() {
    return request<{ user: AuthUser; organizations?: Organization[] }>("/api/v1/auth/me");
  },

  // ── Site submissions ─────────────────────────────────────────────────────

  /**
   * Open to anonymous callers — the backend accepts a nil submitter and stores
   * `contact_email` instead. A session token is attached when one exists, which
   * attributes the submission to the signed-in user.
   */
  submitSite(input: {
    name: string;
    url: string;
    summary: string;
    category_slug: string;
    tags: string[];
    contact_email?: string;
  }) {
    return request<{ submission: DirectorySubmission }>("/api/v1/directory/submissions", {
      method: "POST",
      body: JSON.stringify(input),
    });
  },

  mySubmissions() {
    return request<{ submissions: DirectorySubmission[] }>("/api/v1/directory/submissions");
  },

  getSubmission(id: string) {
    return request<{ submission: DirectorySubmission }>(
      `/api/v1/directory/submissions/${encodeURIComponent(id)}`,
    );
  },

  // ── Ownership claims ─────────────────────────────────────────────────────

  claimSite(slug: string, method: "meta_tag" | "dns_txt") {
    return request<{ claim: SiteClaim }>(
      `/api/v1/directory/sites/${encodeURIComponent(slug)}/claim`,
      {
        method: "POST",
        body: JSON.stringify({ method }),
      },
    );
  },

  verifyClaim(id: string) {
    return request<{ claim: SiteClaim }>(
      `/api/v1/directory/claims/${encodeURIComponent(id)}/verify`,
      { method: "POST" },
    );
  },

  myClaims() {
    return request<{ claims: SiteClaim[] }>("/api/v1/directory/claims");
  },

  // ── Admin moderation (admin only; 403 for non-admins) ────────────────────

  modSubmissions(status: DirectorySubmission["status"] = "pending") {
    return request<{ submissions: DirectorySubmission[] }>(
      `/api/v1/admin/directory/submissions?status=${encodeURIComponent(status)}`,
    );
  },

  approveSubmission(
    id: string,
    input: {
      scores: SubmissionScores;
      category_slug: string;
      summary: string;
      featured: boolean;
    },
  ) {
    return request<{ submission: DirectorySubmission; site: DirectorySite }>(
      `/api/v1/admin/directory/submissions/${encodeURIComponent(id)}/approve`,
      {
        method: "POST",
        body: JSON.stringify(input),
      },
    );
  },

  rejectSubmission(id: string, reason: string) {
    return request<{ submission: DirectorySubmission }>(
      `/api/v1/admin/directory/submissions/${encodeURIComponent(id)}/reject`,
      {
        method: "POST",
        body: JSON.stringify({ reason }),
      },
    );
  },
};
