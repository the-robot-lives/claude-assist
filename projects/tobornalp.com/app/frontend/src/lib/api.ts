import { getRuntimeConfig, runtimeCookieDomainAttribute } from "@/lib/runtime-config";

function apiUrl() {
  return getRuntimeConfig().API_URL || process.env.NEXT_PUBLIC_API_URL || "";
}

// Array-aware query serializer. Serializes scalar params as `key=value` and
// array params as repeated `key[]=v1&key[]=v2` brackets — the form Plug's
// `fetch_query_params` parses into a list, which the tobornalp item_controller
// forwards verbatim to `Items.maybe_filter/2` (list ⇒ SQL `IN`, scalar ⇒ `=`).
// Empty strings, empty arrays, and null/undefined are omitted so they stay
// no-ops on the backend. Centralized so every list method serializes
// multi-select facets identically (no per-method drift).
function buildQuery(params: Record<string, string | string[] | number | undefined | null>): string {
  const qs = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value == null) continue;
    if (Array.isArray(value)) {
      for (const v of value) if (v != null && v !== "") qs.append(`${key}[]`, String(v));
    } else if (value !== "") {
      qs.set(key, String(value));
    }
  }
  const s = qs.toString();
  return s ? `?${s}` : "";
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
  listItems(
    orgId: string,
    params?: {
      project_id?: string;
      // Facetable filters accept a single value OR an array (multi-select → BE
      // `in` filter via Plug's `key[]=v` parsing; see Items.maybe_filter/2).
      status?: string | string[];
      item_type?: string | string[];
      priority?: string | string[];
      assignee?: string | string[];
      queue_id?: string;
      // "root" sentinel selects top-level (parent_id IS NULL) items.
      parent_id?: string;
      stage_id?: string;
      iteration_id?: string;
    },
  ) {
    const suffix = buildQuery({
      project_id: params?.project_id,
      status: params?.status,
      item_type: params?.item_type,
      priority: params?.priority,
      assignee: params?.assignee,
      queue_id: params?.queue_id,
      parent_id: params?.parent_id,
      stage_id: params?.stage_id,
      iteration_id: params?.iteration_id,
    });
    return request<{ items: Item[] }>(`/api/v1/organizations/${orgId}/items${suffix}`);
  },
  getItem(orgId: string, id: string) {
    return request<{ item: Item; links: { outgoing: ItemLink[]; incoming: ItemLink[] } }>(`/api/v1/organizations/${orgId}/items/${id}`);
  },
  createItem(orgId: string, data: ItemInput) {
    return request<{ item: Item }>(`/api/v1/organizations/${orgId}/items`, {
      method: "POST",
      body: JSON.stringify({ item: data }),
    });
  },
  updateItem(orgId: string, id: string, data: ItemInput) {
    return request<{ item: Item }>(`/api/v1/organizations/${orgId}/items/${id}`, {
      method: "PATCH",
      body: JSON.stringify({ item: data }),
    });
  },
  deleteItem(orgId: string, id: string) {
    return request<void>(`/api/v1/organizations/${orgId}/items/${id}`, { method: "DELETE" });
  },

  // Item comments (polymorphic trp_comments, entity_type = "item").
  listItemComments(orgId: string, id: string) {
    return request<{ comments: ItemComment[] }>(`/api/v1/organizations/${orgId}/items/${id}/comments`);
  },
  addItemComment(orgId: string, id: string, comment: { content: string; author?: string; reply_to_id?: string | null }) {
    return request<{ comment: ItemComment }>(`/api/v1/organizations/${orgId}/items/${id}/comments`, {
      method: "POST",
      body: JSON.stringify({ comment }),
    });
  },
  deleteItemComment(orgId: string, commentId: string) {
    return request<void>(`/api/v1/organizations/${orgId}/items/comments/${commentId}`, { method: "DELETE" });
  },

  // Item activity feed (item_events append-only audit).
  listItemActivity(orgId: string, id: string) {
    return request<{ activity: ItemEvent[] }>(`/api/v1/organizations/${orgId}/items/${id}/activity`);
  },

  // Item ↔ item links. Note: delete + list operate off the flat /items/links/:id
  // and /items/:id/links surfaces respectively (see router.ex).
  listItemLinks(orgId: string, id: string) {
    return request<{ links: { outgoing: ItemLink[]; incoming: ItemLink[] } }>(
      `/api/v1/organizations/${orgId}/items/${id}/links`,
    );
  },
  addItemLink(orgId: string, id: string, link: { target_item_id: string; link_type: string }) {
    return request<{ link: ItemLink }>(`/api/v1/organizations/${orgId}/items/${id}/links`, {
      method: "POST",
      body: JSON.stringify({ link }),
    });
  },
  deleteItemLink(orgId: string, linkId: string) {
    return request<void>(`/api/v1/organizations/${orgId}/items/links/${linkId}`, { method: "DELETE" });
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
  updateQueue(orgId: string, id: string, data: Partial<{ name: string; slug: string; description: string; methodology: string; config: Record<string, unknown> }>) {
    return request<{ queue: ItemQueue }>(`/api/v1/organizations/${orgId}/queues/${id}`, {
      method: "PATCH",
      body: JSON.stringify({ queue: data }),
    });
  },
  deleteQueue(orgId: string, id: string) {
    return request<void>(`/api/v1/organizations/${orgId}/queues/${id}`, { method: "DELETE" });
  },

  // Stages (columns) under a board.
  listStages(orgId: string, queueId: string) {
    return request<{ stages: BoardStage[] }>(`/api/v1/organizations/${orgId}/queues/${queueId}/stages`);
  },
  createStage(orgId: string, queueId: string, stage: StageInput) {
    return request<{ stage: BoardStage }>(`/api/v1/organizations/${orgId}/queues/${queueId}/stages`, {
      method: "POST",
      body: JSON.stringify({ stage }),
    });
  },
  updateStage(orgId: string, queueId: string, stageId: string, stage: StageInput) {
    return request<{ stage: BoardStage }>(`/api/v1/organizations/${orgId}/queues/${queueId}/stages/${stageId}`, {
      method: "PUT",
      body: JSON.stringify({ stage }),
    });
  },
  deleteStage(orgId: string, queueId: string, stageId: string) {
    return request<void>(`/api/v1/organizations/${orgId}/queues/${queueId}/stages/${stageId}`, { method: "DELETE" });
  },

  // Iterations (sprints/cycles) under a board.
  listIterations(orgId: string, queueId: string) {
    return request<{ iterations: BoardIteration[] }>(`/api/v1/organizations/${orgId}/queues/${queueId}/iterations`);
  },
  createIteration(orgId: string, queueId: string, iteration: IterationInput) {
    return request<{ iteration: BoardIteration }>(`/api/v1/organizations/${orgId}/queues/${queueId}/iterations`, {
      method: "POST",
      body: JSON.stringify({ iteration }),
    });
  },
  updateIteration(orgId: string, queueId: string, iterationId: string, iteration: IterationInput) {
    return request<{ iteration: BoardIteration }>(
      `/api/v1/organizations/${orgId}/queues/${queueId}/iterations/${iterationId}`,
      { method: "PUT", body: JSON.stringify({ iteration }) },
    );
  },
  deleteIteration(orgId: string, queueId: string, iterationId: string) {
    return request<void>(`/api/v1/organizations/${orgId}/queues/${queueId}/iterations/${iterationId}`, {
      method: "DELETE",
    });
  },

  // ── Projects (methodology-provisioned boards) ─────────────────────────────
  listProjects(orgId: string) {
    return request<{ projects: Project[] }>(`/api/v1/organizations/${orgId}/projects`);
  },
  getProject(orgId: string, id: string) {
    return request<{ project: Project }>(`/api/v1/organizations/${orgId}/projects/${id}`);
  },
  createProject(
    orgId: string,
    data: { name: string; slug: string; methodology: string; key_prefix?: string; description?: string },
  ) {
    return request<{ project: Project }>(`/api/v1/organizations/${orgId}/projects`, {
      method: "POST",
      body: JSON.stringify({ project: data }),
    });
  },
  updateProject(
    orgId: string,
    id: string,
    data: Partial<{ name: string; slug: string; description: string; key_prefix: string; settings: Record<string, unknown> }>,
  ) {
    return request<{ project: Project }>(`/api/v1/organizations/${orgId}/projects/${id}`, {
      method: "PATCH",
      body: JSON.stringify({ project: data }),
    });
  },
  archiveProject(orgId: string, id: string) {
    return request<{ project: Project }>(`/api/v1/organizations/${orgId}/projects/${id}/archive`, {
      method: "POST",
    });
  },
  unarchiveProject(orgId: string, id: string) {
    return request<{ project: Project }>(`/api/v1/organizations/${orgId}/projects/${id}/unarchive`, {
      method: "POST",
    });
  },
  provisionProject(orgId: string, id: string, methodology: string) {
    return request<{
      default_queue: ProjectBoardRef | null;
      migration_required: boolean;
      stage_map: Record<string, string | null>;
    }>(`/api/v1/organizations/${orgId}/projects/${id}/provision`, {
      method: "POST",
      body: JSON.stringify({ methodology }),
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
  // Create/update bodies use the controller's `{field}` / `{type}` envelope. The
  // server merges organization_id from the URL; project_id is passed to convey
  // project scope (nil/omit ⇒ org scope).
  createFieldDefinition(orgId: string, field: FieldDefinitionInput) {
    return request<{ field: ItemFieldDefinition }>(
      `/api/v1/organizations/${orgId}/definitions/fields`,
      { method: "POST", body: JSON.stringify({ field }) },
    );
  },
  // NOTE: get/update/delete target RESTful :id routes. The Definitions domain
  // already implements get_field/update_field/delete_field, but the controller
  // and router only expose index+create today — these will 404 until those
  // routes are wired (reported as a backend gap for this wave).
  getFieldDefinition(orgId: string, id: string) {
    return request<{ field: ItemFieldDefinition }>(
      `/api/v1/organizations/${orgId}/definitions/fields/${id}`,
    );
  },
  updateFieldDefinition(orgId: string, id: string, field: FieldDefinitionInput) {
    return request<{ field: ItemFieldDefinition }>(
      `/api/v1/organizations/${orgId}/definitions/fields/${id}`,
      { method: "PUT", body: JSON.stringify({ field }) },
    );
  },
  deleteFieldDefinition(orgId: string, id: string) {
    return request<{ message: string }>(
      `/api/v1/organizations/${orgId}/definitions/fields/${id}`,
      { method: "DELETE" },
    );
  },
  createTypeDefinition(orgId: string, type: TypeDefinitionInput) {
    return request<{ type: ItemTypeDefinition }>(
      `/api/v1/organizations/${orgId}/definitions/types`,
      { method: "POST", body: JSON.stringify({ type }) },
    );
  },
  getTypeDefinition(orgId: string, id: string) {
    return request<{ type: ItemTypeDefinition }>(
      `/api/v1/organizations/${orgId}/definitions/types/${id}`,
    );
  },
  updateTypeDefinition(orgId: string, id: string, type: TypeDefinitionInput) {
    return request<{ type: ItemTypeDefinition }>(
      `/api/v1/organizations/${orgId}/definitions/types/${id}`,
      { method: "PUT", body: JSON.stringify({ type }) },
    );
  },
  deleteTypeDefinition(orgId: string, id: string) {
    return request<{ message: string }>(
      `/api/v1/organizations/${orgId}/definitions/types/${id}`,
      { method: "DELETE" },
    );
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
  // Nested forest with rolled-up progress (US-069 tree endpoint).
  getObjectiveTree(orgId: string) {
    return request<{ tree: ObjectiveTreeNode[] }>(`/api/v1/organizations/${orgId}/objectives/tree`);
  },
  createObjective(orgId: string, data: Partial<Objective>) {
    return request<{ objective: Objective }>(`/api/v1/organizations/${orgId}/objectives`, {
      method: "POST",
      body: JSON.stringify({ objective: data }),
    });
  },
  createChildObjective(orgId: string, parentId: string, data: Partial<Objective>) {
    return request<{ objective: Objective }>(`/api/v1/organizations/${orgId}/objectives/${parentId}/children`, {
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
  deleteObjective(orgId: string, id: string) {
    return request<void>(`/api/v1/organizations/${orgId}/objectives/${id}`, { method: "DELETE" });
  },
  createKeyResult(orgId: string, objectiveId: string, data: Partial<KeyResult>) {
    return request<{ key_result: KeyResult }>(`/api/v1/organizations/${orgId}/objectives/${objectiveId}/key_results`, {
      method: "POST",
      body: JSON.stringify({ key_result: data }),
    });
  },
  updateKeyResult(orgId: string, krId: string, data: Partial<KeyResult>) {
    return request<{ key_result: KeyResult }>(`/api/v1/organizations/${orgId}/key_results/${krId}`, {
      method: "PATCH",
      body: JSON.stringify({ key_result: data }),
    });
  },
  deleteKeyResult(orgId: string, krId: string) {
    return request<void>(`/api/v1/organizations/${orgId}/key_results/${krId}`, { method: "DELETE" });
  },
  linkKrItem(orgId: string, krId: string, itemId: string, weight?: number | string) {
    return request<{ link: KrItemLink }>(`/api/v1/organizations/${orgId}/key_results/${krId}/items`, {
      method: "POST",
      body: JSON.stringify({ item_id: itemId, weight }),
    });
  },
  unlinkKrItem(orgId: string, krId: string, itemId: string) {
    return request<void>(`/api/v1/organizations/${orgId}/key_results/${krId}/items/${itemId}`, { method: "DELETE" });
  },
  createCheckin(orgId: string, objectiveId: string, data: { body: string; period?: string }) {
    return request<{ checkin: OkrCheckin }>(`/api/v1/organizations/${orgId}/objectives/${objectiveId}/checkins`, {
      method: "POST",
      body: JSON.stringify({ checkin: data }),
    });
  },
  listCheckins(orgId: string, objectiveId: string) {
    return request<{ checkins: OkrCheckin[] }>(`/api/v1/organizations/${orgId}/objectives/${objectiveId}/checkins`);
  },
  deleteCheckin(orgId: string, checkinId: string) {
    return request<void>(`/api/v1/organizations/${orgId}/checkins/${checkinId}`, { method: "DELETE" });
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

  // ── Personal todos (WS-A US-011 — owner-scoped, project-less items) ─────────
  listPersonalItems(orgId: string, params?: { group?: "grouped" | "all"; tag?: string; status?: string; q?: string; tz?: string }) {
    const qs = new URLSearchParams(
      Object.entries(params || {}).filter(([, v]) => v != null && v !== "") as [string, string][],
    ).toString();
    return request<PersonalListResponse>(`/api/v1/organizations/${orgId}/personal/items${qs ? `?${qs}` : ""}`);
  },
  personalTags(orgId: string) {
    return request<{ tags: string[] }>(`/api/v1/organizations/${orgId}/personal/tags`);
  },
  createPersonalItem(orgId: string, data: PersonalItemInput) {
    return request<{ item: PersonalItem }>(`/api/v1/organizations/${orgId}/personal/items`, {
      method: "POST",
      body: JSON.stringify({ item: data }),
    });
  },
  updatePersonalItem(orgId: string, id: string, data: Partial<PersonalItemInput>) {
    return request<{ item: PersonalItem }>(`/api/v1/organizations/${orgId}/personal/items/${id}`, {
      method: "PATCH",
      body: JSON.stringify({ item: data }),
    });
  },
  completePersonalItem(orgId: string, id: string, tz?: string) {
    return request<{ completed: PersonalItem; next: PersonalItem | null }>(
      `/api/v1/organizations/${orgId}/personal/items/${id}/complete`,
      { method: "POST", body: JSON.stringify({ tz }) },
    );
  },
  setRecurrence(orgId: string, id: string, recurrence: RecurrenceInput) {
    return request<{ item: PersonalItem }>(`/api/v1/organizations/${orgId}/personal/items/${id}/recurrence`, {
      method: "POST",
      body: JSON.stringify({ recurrence }),
    });
  },
  clearRecurrence(orgId: string, id: string) {
    return request<{ item: PersonalItem }>(`/api/v1/organizations/${orgId}/personal/items/${id}/recurrence`, {
      method: "DELETE",
    });
  },

  // ── Saved views (per-user/project persisted list/board filters) ──────────────
  listSavedViews(orgId: string, opts?: { project_id?: string; view_type?: string; entity_type?: string }) {
    const suffix = buildQuery({ project_id: opts?.project_id, view_type: opts?.view_type, entity_type: opts?.entity_type });
    return request<{ saved_views: SavedView[] }>(`/api/v1/organizations/${orgId}/saved-views${suffix}`);
  },
  getSavedView(orgId: string, id: string) {
    return request<{ saved_view: SavedView }>(`/api/v1/organizations/${orgId}/saved-views/${id}`);
  },
  createSavedView(orgId: string, data: SavedViewInput) {
    return request<{ saved_view: SavedView }>(`/api/v1/organizations/${orgId}/saved-views`, {
      method: "POST",
      body: JSON.stringify({ saved_view: data }),
    });
  },
  updateSavedView(orgId: string, id: string, data: Partial<SavedViewInput>) {
    return request<{ saved_view: SavedView }>(`/api/v1/organizations/${orgId}/saved-views/${id}`, {
      method: "PUT",
      body: JSON.stringify({ saved_view: data }),
    });
  },
  deleteSavedView(orgId: string, id: string) {
    return request<{ ok: boolean }>(`/api/v1/organizations/${orgId}/saved-views/${id}`, { method: "DELETE" });
  },

  // ── Artifacts (versioned typed content) ─────────────────────────────────────
  listArtifacts(orgId: string, opts?: { project_id?: string; kind?: string | string[]; search?: string }) {
    const suffix = buildQuery({ project_id: opts?.project_id, kind: opts?.kind, search: opts?.search });
    return request<{ artifacts: Artifact[] }>(`/api/v1/organizations/${orgId}/artifacts${suffix}`);
  },
  getArtifact(orgId: string, id: string, revisionId?: string) {
    const suffix = buildQuery({ revision_id: revisionId });
    return request<{ artifact: ArtifactDetail }>(`/api/v1/organizations/${orgId}/artifacts/${id}${suffix}`);
  },
  createArtifact(orgId: string, data: ArtifactInput) {
    return request<{ artifact: ArtifactDetail }>(`/api/v1/organizations/${orgId}/artifacts`, {
      method: "POST",
      body: JSON.stringify({ artifact: data }),
    });
  },
  listArtifactRevisions(orgId: string, artifactId: string) {
    return request<{ revisions: ArtifactRevision[] }>(
      `/api/v1/organizations/${orgId}/artifacts/${artifactId}/revisions`,
    );
  },
  // Edit = append a new revision (history-preserving). Returns the artifact with
  // its new current revision so the editor reconciles in one round-trip.
  createArtifactRevision(orgId: string, artifactId: string, body: { content: string; note?: string }) {
    return request<{ artifact: ArtifactDetail }>(
      `/api/v1/organizations/${orgId}/artifacts/${artifactId}/revisions`,
      { method: "POST", body: JSON.stringify(body) },
    );
  },

  // ── Wiki (spaces, pages, comments, attachments, reactions) ──────────────────
  listWikiSpaces(orgId: string, opts?: { project_id?: string; search?: string }) {
    const suffix = buildQuery({ project_id: opts?.project_id, search: opts?.search });
    return request<{ spaces: WikiSpace[] }>(`/api/v1/organizations/${orgId}/wiki/spaces${suffix}`);
  },
  getWikiSpace(orgId: string, id: string) {
    return request<{ space: WikiSpace; pages: WikiPageSummary[] }>(
      `/api/v1/organizations/${orgId}/wiki/spaces/${id}`,
    );
  },
  createWikiSpace(orgId: string, data: WikiSpaceInput) {
    return request<{ space: WikiSpace }>(`/api/v1/organizations/${orgId}/wiki/spaces`, {
      method: "POST",
      body: JSON.stringify({ space: data }),
    });
  },
  updateWikiSpace(orgId: string, id: string, data: Partial<WikiSpaceInput>) {
    return request<{ space: WikiSpace }>(`/api/v1/organizations/${orgId}/wiki/spaces/${id}`, {
      method: "PUT",
      body: JSON.stringify({ space: data }),
    });
  },
  deleteWikiSpace(orgId: string, id: string) {
    return request<{ message: string }>(`/api/v1/organizations/${orgId}/wiki/spaces/${id}`, { method: "DELETE" });
  },
  listWikiPages(orgId: string, spaceId: string, opts?: { search?: string }) {
    const suffix = buildQuery({ search: opts?.search });
    return request<{ pages: WikiPageSummary[] }>(
      `/api/v1/organizations/${orgId}/wiki/spaces/${spaceId}/pages${suffix}`,
    );
  },
  getWikiPage(orgId: string, id: string) {
    return request<{ page: WikiPageDetail }>(`/api/v1/organizations/${orgId}/wiki/pages/${id}`);
  },
  createWikiPage(orgId: string, spaceId: string, data: WikiPageInput) {
    return request<{ page: WikiPage }>(`/api/v1/organizations/${orgId}/wiki/spaces/${spaceId}/pages`, {
      method: "POST",
      body: JSON.stringify({ page: data }),
    });
  },
  updateWikiPage(orgId: string, id: string, data: Partial<WikiPageInput>) {
    return request<{ page: WikiPage }>(`/api/v1/organizations/${orgId}/wiki/pages/${id}`, {
      method: "PUT",
      body: JSON.stringify({ page: data }),
    });
  },
  deleteWikiPage(orgId: string, id: string) {
    return request<{ message: string }>(`/api/v1/organizations/${orgId}/wiki/pages/${id}`, { method: "DELETE" });
  },
  // Wiki comments use polymorphic trp_comments: content + reply_to_id (NOT body/parent_id).
  listWikiComments(orgId: string, pageId: string) {
    return request<{ comments: WikiComment[] }>(
      `/api/v1/organizations/${orgId}/wiki/pages/${pageId}/comments`,
    );
  },
  createWikiComment(orgId: string, pageId: string, comment: { content: string; reply_to_id?: string | null; author?: string }) {
    return request<{ comment: WikiComment }>(`/api/v1/organizations/${orgId}/wiki/pages/${pageId}/comments`, {
      method: "POST",
      body: JSON.stringify({ comment }),
    });
  },
  deleteWikiComment(orgId: string, commentId: string) {
    return request<{ message: string }>(`/api/v1/organizations/${orgId}/wiki/comments/${commentId}`, {
      method: "DELETE",
    });
  },
  listWikiAttachments(orgId: string, pageId: string) {
    return request<{ attachments: WikiAttachment[] }>(
      `/api/v1/organizations/${orgId}/wiki/pages/${pageId}/attachments`,
    );
  },
  createWikiAttachment(
    orgId: string,
    pageId: string,
    attachment: { artifact_type?: string; url?: string; git_branch?: string; description?: string; filename?: string; created_by?: string },
  ) {
    return request<{ attachment: WikiAttachment }>(
      `/api/v1/organizations/${orgId}/wiki/pages/${pageId}/attachments`,
      { method: "POST", body: JSON.stringify({ attachment }) },
    );
  },
  deleteWikiAttachment(orgId: string, attachmentId: string) {
    return request<{ message: string }>(`/api/v1/organizations/${orgId}/wiki/attachments/${attachmentId}`, {
      method: "DELETE",
    });
  },
  // Reactions: page + comment scoped; emoji passed in the JSON body.
  listWikiPageReactions(orgId: string, pageId: string) {
    return request<{ reactions: WikiReaction[] }>(
      `/api/v1/organizations/${orgId}/wiki/pages/${pageId}/reactions`,
    );
  },
  addWikiPageReaction(orgId: string, pageId: string, emoji: string) {
    return request<{ reaction: WikiReaction }>(`/api/v1/organizations/${orgId}/wiki/pages/${pageId}/reactions`, {
      method: "POST",
      body: JSON.stringify({ emoji }),
    });
  },
  removeWikiPageReaction(orgId: string, pageId: string, emoji: string) {
    return request<{ message: string }>(`/api/v1/organizations/${orgId}/wiki/pages/${pageId}/reactions`, {
      method: "DELETE",
      body: JSON.stringify({ emoji }),
    });
  },
  listWikiCommentReactions(orgId: string, commentId: string) {
    return request<{ reactions: WikiReaction[] }>(
      `/api/v1/organizations/${orgId}/wiki/comments/${commentId}/reactions`,
    );
  },
  addWikiCommentReaction(orgId: string, commentId: string, emoji: string) {
    return request<{ reaction: WikiReaction }>(
      `/api/v1/organizations/${orgId}/wiki/comments/${commentId}/reactions`,
      { method: "POST", body: JSON.stringify({ emoji }) },
    );
  },
  removeWikiCommentReaction(orgId: string, commentId: string, emoji: string) {
    return request<{ message: string }>(
      `/api/v1/organizations/${orgId}/wiki/comments/${commentId}/reactions`,
      { method: "DELETE", body: JSON.stringify({ emoji }) },
    );
  },

  // ── Reviews (code/content reviews over an artifact revision) ────────────────
  listReviews(orgId: string, opts?: { project_id?: string; artifact_id?: string; status?: string | string[] }) {
    const suffix = buildQuery({ project_id: opts?.project_id, artifact_id: opts?.artifact_id, status: opts?.status });
    return request<{ reviews: Review[] }>(`/api/v1/organizations/${orgId}/reviews${suffix}`);
  },
  getReview(orgId: string, id: string) {
    return request<{ review: Review; comments: unknown[]; overlays: ReviewOverlay[] }>(
      `/api/v1/organizations/${orgId}/reviews/${id}`,
    );
  },
  createReview(orgId: string, data: ReviewInput) {
    return request<{ review: Review }>(`/api/v1/organizations/${orgId}/reviews`, {
      method: "POST",
      body: JSON.stringify({ review: data }),
    });
  },
  // Update a non-completed review's mutable metadata. A completed review is
  // frozen (BE 409); finalize via completeReview.
  updateReview(orgId: string, id: string, data: Partial<{ title: string; reviewer_persona: string; summary: string; verdict: string | null; status: string }>) {
    return request<{ review: Review }>(`/api/v1/organizations/${orgId}/reviews/${id}`, {
      method: "PUT",
      body: JSON.stringify({ review: data }),
    });
  },
  completeReview(orgId: string, id: string, body?: { summary?: string; verdict?: string }) {
    return request<{ review: Review }>(`/api/v1/organizations/${orgId}/reviews/${id}/complete`, {
      method: "POST",
      body: JSON.stringify(body ?? {}),
    });
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
  rank?: string;
  start_date?: string | null;
  due_date?: string | null;
  estimate?: number | string | null;
  custom_fields?: Record<string, unknown>;
  inserted_at?: string;
  updated_at?: string;
}

// Create/update payload shape (distinct from the read model). The backend's
// item_controller accepts these fields under `{ item: {...} }`; `reporter` and
// `organization_id`/`project_id` are set server-side from the route + actor but
// may be supplied. Update (PATCH) ignores identity fields and only applies
// `Map.take(~w(title description status priority assignee queue_id parent_id
// custom_fields stage_id iteration_id rank start_date due_date estimate))`.
export interface ItemInput {
  title?: string;
  description?: string;
  item_type?: string;
  status?: string;
  priority?: string;
  assignee?: string;
  reporter?: string;
  queue_id?: string;
  parent_id?: string;
  stage_id?: string;
  iteration_id?: string;
  rank?: string;
  start_date?: string | null;
  due_date?: string | null;
  estimate?: number | string | null;
  custom_fields?: Record<string, unknown>;
  project_id?: string;
  organization_id?: string;
}

// Comment on an item (polymorphic trp_comments, entity_type = "item").
export interface ItemComment {
  id: string;
  item_id: string;
  content: string;
  author?: string;
  reply_to_id?: string | null;
  inserted_at?: string;
}

// Activity feed entry (item_events append-only audit).
export interface ItemEvent {
  id: string;
  item_id: string;
  actor?: string;
  field?: string;
  old_value?: string | null;
  new_value?: string | null;
  occurred_at?: string;
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

// Compact ref to a project's provisioned default board (methodology + stage count).
export interface ProjectBoardRef {
  id: string;
  slug: string;
  methodology: string;
  stage_count: number;
}

export type Methodology = "kanban" | "scrum" | "waterfall" | "spiral" | "custom";

export interface Project {
  id: string;
  organization_id?: string;
  name: string;
  slug: string;
  description?: string;
  status?: string;
  key_prefix?: string;
  default_methodology?: string;
  default_queue?: ProjectBoardRef | null;
  archived_at?: string | null;
  inserted_at?: string;
  updated_at?: string;
}

export interface BoardStage {
  id: string;
  queue_id?: string;
  slug: string;
  name: string;
  kind?: string;
  position: number;
  wip_limit?: number;
  config?: Record<string, unknown>;
}

// Create/update payload for a stage (queue_id is taken from the URL).
export interface StageInput {
  slug?: string;
  name?: string;
  kind?: string;
  position?: number;
  wip_limit?: number;
  config?: Record<string, unknown>;
}

export interface BoardIteration {
  id: string;
  queue_id?: string;
  name: string;
  sequence: number;
  status: string;
  goal?: string;
  starts_on?: string | null;
  ends_on?: string | null;
  config?: Record<string, unknown>;
}

// Create/update payload for an iteration (queue_id is taken from the URL).
export interface IterationInput {
  name?: string;
  sequence?: number;
  status?: string;
  goal?: string;
  starts_on?: string | null;
  ends_on?: string | null;
  config?: Record<string, unknown>;
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

// Field type whitelist — mirrors Therobotplans.Schema.ItemFieldDefinition @field_types.
export const FIELD_TYPES = [
  "text",
  "rich_text",
  "markdown",
  "radio",
  "select",
  "multi_select",
  "number",
  "date",
  "persona",
  "url",
] as const;
export type FieldType = (typeof FIELD_TYPES)[number];

// Scope is not stored on a definition row — it is DERIVED from which owner
// columns are set (global = both null, org = organization_id only, project =
// both). Matches Definitions.scope_of/1 on the backend.
export type DefinitionScope = "global" | "org" | "project";

export function definitionScope(d: {
  organization_id?: string | null;
  project_id?: string | null;
}): DefinitionScope {
  if (d.project_id) return "project";
  if (d.organization_id) return "org";
  return "global";
}

// Create/update payloads. project_id conveys project scope on create
// (organization_id is set by the server from the URL); omit/nil for org scope.
export interface FieldDefinitionInput {
  slug?: string;
  label?: string;
  field_type?: string;
  options?: Record<string, unknown> | null;
  default_value?: string | null;
  description?: string | null;
  disabled?: boolean;
  project_id?: string | null;
}

export interface TypeDefinitionInput {
  slug?: string;
  name?: string;
  description?: string | null;
  icon?: string | null;
  status_workflow?: Record<string, unknown> | null;
  disabled?: boolean;
  project_id?: string | null;
  // Field assignments reference field-definition ids. The backend does not yet
  // persist these through create/update (add_field_to_type is unwired); Ecto
  // silently drops the key, so sending it is forward-compatible and harmless.
  fields?: { id: string; required: boolean }[];
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

export type RollupStrategy = "weighted_avg" | "min_children" | "custom";

export interface Objective {
  id: string;
  title: string;
  level: string;
  status: string;
  period?: string;
  owner_id?: string;
  organization_id?: string;
  project_id?: string;
  parent_id?: string | null;
  description?: string;
  progress?: string;
  // ── US-069 hierarchy / rollup ──
  rollup_strategy?: RollupStrategy;
  weight?: string | number;
  sort_order?: number;
}

export interface ObjectiveDetail extends Objective {
  key_results?: KeyResult[];
  checkins?: OkrCheckin[];
}

// A node in the objective forest (US-069 tree endpoint): objective fields + rolled-up
// progress + nested children.
export interface ObjectiveTreeNode extends Objective {
  children: ObjectiveTreeNode[];
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
  direction?: "higher_better" | "lower_better";
  weight?: string | number;
}

export interface KrItemLink {
  id: string;
  key_result_id: string;
  item_id: string;
  weight?: string | number;
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

// ── Personal todos (WS-A US-011) ──────────────────────────────────────────────
export type PersonalBucket = "overdue" | "today" | "upcoming" | "someday";

export interface RecurrenceRuleSummary {
  rule_id: string;
  freq: string;
  interval: number;
  by_day: string[];
  by_month_day: number[];
  until?: string | null;
  count?: number | null;
  timezone: string;
  roll_on_skip: boolean;
  recurrence_parent_id?: string | null;
}

export interface RecurrenceInput {
  // Either a named preset (daily/weekdays/weekly/biweekly/monthly) or raw fields.
  preset?: "daily" | "weekdays" | "weekly" | "biweekly" | "monthly" | "custom";
  freq?: "daily" | "weekly" | "monthly";
  interval?: number;
  by_day?: string[];
  by_month_day?: number[];
  until?: string | null;
  count?: number | null;
  timezone?: string;
}

export interface PersonalItem {
  id: string;
  key?: string;
  number?: number;
  organization_id: string;
  owner_user_id?: string;
  project_id?: string | null;
  title: string;
  description?: string;
  item_type: string;
  status: string;
  priority?: string;
  rank?: string;
  due_date?: string | null;
  start_date?: string | null;
  tags: string[];
  recurrence?: RecurrenceRuleSummary | null;
  overdue: boolean;
  bucket: PersonalBucket;
  inserted_at?: string;
  updated_at?: string;
}

export interface PersonalItemInput {
  title?: string;
  description?: string;
  item_type?: string;
  status?: string;
  priority?: string;
  due_date?: string | null;
  tags?: string[];
  rank?: string;
  recurrence?: RecurrenceInput;
  tz?: string;
}

export type PersonalListResponse =
  | { groups: Record<PersonalBucket, PersonalItem[]> }
  | { items: PersonalItem[] };

// ── Saved views ────────────────────────────────────────────────────────────────
export interface SavedView {
  id: string;
  organization_id: string;
  project_id?: string | null;
  owner_user_id?: string | null;
  name: string;
  entity_type?: string;
  view_type?: string;
  config?: Record<string, unknown>;
  is_shared?: boolean;
  inserted_at?: string;
  updated_at?: string;
}

export interface SavedViewInput {
  name: string;
  project_id?: string;
  owner_user_id?: string;
  entity_type?: string;
  view_type?: string;
  config?: Record<string, unknown>;
  is_shared?: boolean;
}

// ── Artifacts (versioned typed content) ─────────────────────────────────────────
export type ArtifactKind = "code" | "document" | "image" | "wiki" | "config" | "binary";

export interface Artifact {
  id: string;
  organization_id: string;
  project_id?: string | null;
  kind: ArtifactKind | string;
  title: string;
  mime_type?: string;
  inserted_at?: string;
  updated_at?: string;
}

// Artifact read shape with a pinned revision: show/create/createRevision responses
// include content + the revision pointer; list shape omits them.
export interface ArtifactDetail extends Artifact {
  content?: string | null;
  revision_id?: string;
  revision_number?: number;
}

export interface ArtifactInput {
  kind: ArtifactKind | string;
  title: string;
  project_id?: string;
  mime_type?: string;
  content?: string;
}

// Revision list entry (metadata only — content is NOT included; fetch via
// getArtifact with revision_id). Note: the BE maps inserted_at → created_at here.
export interface ArtifactRevision {
  id: string;
  revision_number: number;
  note?: string | null;
  created_at?: string;
}

// ── Wiki ────────────────────────────────────────────────────────────────────────
export interface WikiSpace {
  id: string;
  organization_id: string;
  project_id?: string | null;
  slug: string;
  name: string;
  description?: string;
  inserted_at?: string;
  updated_at?: string;
}

export interface WikiSpaceInput {
  slug: string;
  name: string;
  project_id?: string;
  description?: string;
}

// Compact page ref returned by space show + page index.
export interface WikiPageSummary {
  id: string;
  space_id: string;
  parent_id?: string | null;
  slug: string;
  title: string;
  position?: number;
  updated_at?: string;
}

export interface WikiPage {
  id: string;
  space_id: string;
  parent_id?: string | null;
  slug: string;
  title: string;
  content?: string;
  position?: number;
  inserted_at?: string;
  updated_at?: string;
}

// Page show response also embeds comments/attachments/reactions.
export interface WikiPageDetail extends WikiPage {
  comments?: WikiComment[];
  attachments?: WikiAttachment[];
  reactions?: WikiReaction[];
}

export interface WikiPageInput {
  slug: string;
  title: string;
  content?: string;
  parent_id?: string | null;
  position?: number;
}

// Polymorphic trp_comments shape: content / reply_to_id (not body / parent_id).
export interface WikiComment {
  id: string;
  page_id: string;
  author?: string;
  content: string;
  reply_to_id?: string | null;
  inserted_at?: string;
}

// Polymorphic trp_attachments shape.
export interface WikiAttachment {
  id: string;
  page_id: string;
  artifact_type?: string;
  url?: string;
  description?: string;
  created_by?: string;
  inserted_at?: string;
}

// Polymorphic trp_reactions shape (persona, not actor).
export interface WikiReaction {
  id: string;
  target_type?: string;
  target_id?: string;
  emoji: string;
  persona?: string;
  inserted_at?: string;
}

// ── Reviews ─────────────────────────────────────────────────────────────────────
export interface Review {
  id: string;
  organization_id: string;
  project_id?: string | null;
  artifact_id?: string;
  revision_id?: string;
  reviewer_persona?: string;
  title?: string;
  status: string;
  summary?: string | null;
  verdict?: string | null;
  inserted_at?: string;
  updated_at?: string;
}

export interface ReviewInput {
  artifact_id?: string;
  revision_id?: string;
  project_id?: string;
  reviewer_persona?: string;
  title?: string;
}

// A positioned overlay comment on the artifact under review.
export interface ReviewOverlay {
  id: string;
  x?: number | string;
  y?: number | string;
  width?: number | string;
  height?: number | string;
  comment?: string;
  persona?: string;
}
