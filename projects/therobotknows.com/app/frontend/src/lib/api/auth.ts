import { request } from "./client";
import { getBackendOrigin, isMockMode } from "./config";

export interface AuthUser {
  id: string;
  email: string;
  user_name?: string;
  handle?: string;
  verified?: boolean;
  profile_complete?: boolean;
}

interface AuthResponse {
  user: AuthUser;
  access_token: string;
  refresh_token: string;
}

function storeTokens(access: string, refresh?: string) {
  if (typeof window === "undefined") return;
  localStorage.setItem("access_token", access);
  if (refresh) localStorage.setItem("refresh_token", refresh);
}

export function clearTokens() {
  if (typeof window === "undefined") return;
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
  localStorage.removeItem("id_token");
}

export const authApi = {
  async register(opts: {
    email: string;
    password: string;
    userName?: string;
    inviteToken: string;
  }) {
    if (isMockMode()) {
      const user: AuthUser = {
        id: crypto.randomUUID(),
        email: opts.email,
        user_name: opts.userName || opts.email.split("@")[0],
        verified: false,
      };
      storeTokens("mock-access", "mock-refresh");
      return {
        user,
        access_token: "mock-access",
        refresh_token: "mock-refresh",
      };
    }
    const data = await request<AuthResponse>("/api/v1/auth/register", {
      method: "POST",
      skipAuth: true,
      body: JSON.stringify({
        invite_token: opts.inviteToken,
        user: {
          email: opts.email,
          password: opts.password,
          user_name: opts.userName || opts.email.split("@")[0],
        },
      }),
    });
    storeTokens(data.access_token, data.refresh_token);
    return data;
  },

  async login(email: string, password: string) {
    if (isMockMode()) {
      const user: AuthUser = {
        id: crypto.randomUUID(),
        email,
        user_name: email.split("@")[0],
        verified: true,
      };
      storeTokens("mock-access", "mock-refresh");
      return {
        user,
        access_token: "mock-access",
        refresh_token: "mock-refresh",
      };
    }
    const data = await request<AuthResponse>("/api/v1/auth/login", {
      method: "POST",
      skipAuth: true,
      body: JSON.stringify({ email, password }),
    });
    storeTokens(data.access_token, data.refresh_token);
    return data;
  },

  async me() {
    if (isMockMode()) {
      const token =
        typeof window !== "undefined"
          ? localStorage.getItem("access_token")
          : null;
      if (!token) return null;
      return {
        user: {
          id: "mock-user",
          email: "demo@therobotknows.com",
          user_name: "demo",
          verified: true,
        } satisfies AuthUser,
      };
    }
    return request<{ user: AuthUser }>("/api/v1/auth/me");
  },

  async ssoProviders() {
    if (isMockMode()) {
      return { providers: ["oidc"] as string[] };
    }
    try {
      return await request<{ providers: string[] }>(
        "/api/v1/auth/sso/providers",
        { skipAuth: true },
      );
    } catch {
      return { providers: [] as string[] };
    }
  },

  /** Start Authentik / OIDC via backend (never hit IdP from the browser). */
  startOidcLogin() {
    const origin = getBackendOrigin();
    window.location.href = `${origin}/auth/oidc`;
  },

  async exchangeSsoCode(code: string) {
    if (isMockMode()) {
      storeTokens("mock-access", "mock-refresh");
      return {
        user: {
          id: "mock-user",
          email: "sso@therobotknows.com",
          user_name: "sso-user",
          verified: true,
        } satisfies AuthUser,
        access_token: "mock-access",
        refresh_token: "mock-refresh",
      };
    }
    const data = await request<AuthResponse>("/api/v1/auth/sso/exchange", {
      method: "POST",
      skipAuth: true,
      body: JSON.stringify({ code }),
    });
    storeTokens(data.access_token, data.refresh_token);
    return data;
  },

  async requestPasswordReset(email: string): Promise<{
    message: string;
    dev_code?: string;
  }> {
    if (isMockMode()) {
      return {
        message: "If an account exists, a reset code has been sent.",
        dev_code: "000000",
      };
    }
    return request<{ message: string; dev_code?: string }>(
      "/api/v1/auth/password-reset",
      {
        method: "POST",
        skipAuth: true,
        body: JSON.stringify({ email }),
      },
    );
  },

  async verifyPasswordReset(email: string, code: string, newPassword: string) {
    if (isMockMode()) {
      return { message: "Password has been reset." };
    }
    return request<{ message: string }>("/api/v1/auth/password-reset/verify", {
      method: "POST",
      skipAuth: true,
      body: JSON.stringify({
        email,
        code,
        new_password: newPassword,
      }),
    });
  },

  logout() {
    clearTokens();
  },

  isLoggedIn(): boolean {
    if (typeof window === "undefined") return false;
    return !!localStorage.getItem("access_token");
  },
};
