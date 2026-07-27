"use client";

import { createContext, useContext, useEffect, useMemo, useState, useCallback } from "react";
import { api, type Organization, type RegisterPayload, type User } from "@/lib/api";
import { analytics } from "@/lib/analytics";
import { runtimeAuthCookieClearAttributes, runtimeCookieDomainAttribute } from "@/lib/runtime-config";

interface AuthContextType {
  user: User | null;
  loading: boolean;
  organizations: Organization[];
  login: (email: string, password: string) => Promise<User>;
  register: (payload: RegisterPayload) => Promise<User>;
  requestMagicLink: (email: string) => Promise<{ message: string; dev_link?: string }>;
  loginWithMagicLink: (token: string) => Promise<User>;
  requestOtpLogin: (email: string) => Promise<{ message: string; dev_code?: string }>;
  verifyOtpLogin: (email: string, code: string) => Promise<User>;
  ssoExchange: (code: string) => Promise<User>;
  logout: () => void;
}

type AuthResponsePayload = {
  user: User;
  access_token: string;
  refresh_token: string;
  organizations?: Organization[];
};

const AuthContext = createContext<AuthContextType | null>(null);

function setAuthCookie(token: string | null) {
  if (typeof document === "undefined") return;
  const domain = runtimeCookieDomainAttribute();
  try {
    if (token) {
      document.cookie = `access_token=${token}; path=/; max-age=${60 * 60}; SameSite=Lax${domain}`;
    } else {
      for (const clearDomain of runtimeAuthCookieClearAttributes()) {
        document.cookie = `access_token=; path=/; max-age=0; SameSite=Lax${clearDomain}`;
      }
    }
  } catch {
    // Localhost or strict browser policies can reject Domain cookies; localStorage remains canonical.
  }
}

function getCookie(name: string) {
  if (typeof document === "undefined") return null;
  const prefix = `${name}=`;
  return document.cookie
    .split(";")
    .map((part) => part.trim())
    .find((part) => part.startsWith(prefix))
    ?.slice(prefix.length) ?? null;
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [organizations, setOrganizations] = useState<Organization[]>([]);

  const loadUser = useCallback(async () => {
    let token = localStorage.getItem("access_token");
    if (!token) {
      token = getCookie("access_token");
      if (token) localStorage.setItem("access_token", token);
    }
    if (!token) {
      setLoading(false);
      return;
    }

    try {
      const { user, organizations } = await api.me();
      setUser(user);
      setOrganizations(organizations ?? []);
      analytics.identify({ id: user.id, email: user.email });
    } catch {
      localStorage.removeItem("access_token");
      localStorage.removeItem("refresh_token");
      setAuthCookie(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadUser();
  }, [loadUser]);

  const applyAuthResponse = useCallback(
    (
      res: AuthResponsePayload,
      options: { identify?: boolean; trackMethod?: string } = {}
    ) => {
      const identify = options.identify ?? true;
      localStorage.setItem("access_token", res.access_token);
      localStorage.setItem("refresh_token", res.refresh_token);
      setAuthCookie(res.access_token);
      setUser(res.user);
      setOrganizations(res.organizations ?? []);
      if (identify) analytics.identify({ id: res.user.id, email: res.user.email });
      if (options.trackMethod) {
        analytics.trackEvent({ name: "login", properties: { method: options.trackMethod } });
      }
      return res.user;
    },
    []
  );

  const login = useCallback(async (email: string, password: string) => {
    const res = await api.login(email, password);
    return applyAuthResponse(res, { trackMethod: "password" });
  }, [applyAuthResponse]);

  const register = useCallback(async (payload: RegisterPayload) => {
    const res = await api.register(payload);
    return applyAuthResponse(res, { identify: false });
  }, [applyAuthResponse]);

  const requestMagicLink = useCallback(async (email: string) => {
    return api.requestMagicLink(email);
  }, []);

  const loginWithMagicLink = useCallback(async (token: string) => {
    const res = await api.verifyMagicLink(token);
    return applyAuthResponse(res, { trackMethod: "magic_link" });
  }, [applyAuthResponse]);

  const requestOtpLogin = useCallback(async (email: string) => {
    return api.requestOtpLogin(email);
  }, []);

  const verifyOtpLogin = useCallback(async (email: string, code: string) => {
    const res = await api.verifyOtpLogin(email, code);
    return applyAuthResponse(res, { trackMethod: "otp" });
  }, [applyAuthResponse]);

  const ssoExchange = useCallback(async (code: string) => {
    const res = await api.ssoExchange(code);
    return applyAuthResponse(res, { trackMethod: "sso" });
  }, [applyAuthResponse]);

  const logout = useCallback(() => {
    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    setAuthCookie(null);
    setUser(null);
    setOrganizations([]);
    analytics.reset();
  }, []);

  const value = useMemo<AuthContextType>(() => ({
    user,
    loading,
    organizations,
    login,
    register,
    requestMagicLink,
    loginWithMagicLink,
    requestOtpLogin,
    verifyOtpLogin,
    ssoExchange,
    logout,
  }), [
    user,
    loading,
    organizations,
    login,
    register,
    requestMagicLink,
    loginWithMagicLink,
    requestOtpLogin,
    verifyOtpLogin,
    ssoExchange,
    logout,
  ]);

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
