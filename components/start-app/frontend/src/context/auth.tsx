"use client";

import { createContext, useContext, useEffect, useState, useCallback } from "react";
import { api, type Organization, type RegisterPayload, type User } from "@/lib/api";
import { analytics } from "@/lib/analytics";
import { getRuntimeConfig } from "@/lib/runtime-config";

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

const AuthContext = createContext<AuthContextType | null>(null);

function setAuthCookie(token: string | null) {
  if (typeof document === "undefined") return;
  const cookieDomain = getRuntimeConfig().COOKIE_DOMAIN;
  const domain = cookieDomain ? `; Domain=${cookieDomain}` : "";
  if (token) {
    document.cookie = `access_token=${token}; path=/; max-age=${60 * 60}; SameSite=Lax${domain}`;
  } else {
    document.cookie = `access_token=; path=/; max-age=0; SameSite=Lax${domain}`;
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

  async function login(email: string, password: string) {
    const res = await api.login(email, password);
    localStorage.setItem("access_token", res.access_token);
    localStorage.setItem("refresh_token", res.refresh_token);
    setAuthCookie(res.access_token);
    setUser(res.user);
    setOrganizations(res.organizations ?? []);
    analytics.identify({ id: res.user.id, email: res.user.email });
    analytics.trackEvent({ name: "login", properties: { method: "password" } });
    return res.user;
  }

  async function register(payload: RegisterPayload) {
    const res = await api.register(payload);
    localStorage.setItem("access_token", res.access_token);
    localStorage.setItem("refresh_token", res.refresh_token);
    setAuthCookie(res.access_token);
    setUser(res.user);
    setOrganizations(res.organizations ?? []);
    return res.user;
  }

  async function requestMagicLink(email: string) {
    return api.requestMagicLink(email);
  }

  async function loginWithMagicLink(token: string) {
    const res = await api.verifyMagicLink(token);
    localStorage.setItem("access_token", res.access_token);
    localStorage.setItem("refresh_token", res.refresh_token);
    setAuthCookie(res.access_token);
    setUser(res.user);
    setOrganizations(res.organizations ?? []);
    analytics.identify({ id: res.user.id, email: res.user.email });
    analytics.trackEvent({ name: "login", properties: { method: "magic_link" } });
    return res.user;
  }

  async function requestOtpLogin(email: string) {
    return api.requestOtpLogin(email);
  }

  async function verifyOtpLogin(email: string, code: string) {
    const res = await api.verifyOtpLogin(email, code);
    localStorage.setItem("access_token", res.access_token);
    localStorage.setItem("refresh_token", res.refresh_token);
    setAuthCookie(res.access_token);
    setUser(res.user);
    setOrganizations(res.organizations ?? []);
    analytics.identify({ id: res.user.id, email: res.user.email });
    analytics.trackEvent({ name: "login", properties: { method: "otp" } });
    return res.user;
  }

  async function ssoExchange(code: string) {
    const res = await api.ssoExchange(code);
    localStorage.setItem("access_token", res.access_token);
    localStorage.setItem("refresh_token", res.refresh_token);
    setAuthCookie(res.access_token);
    setUser(res.user);
    setOrganizations(res.organizations ?? []);
    analytics.identify({ id: res.user.id, email: res.user.email });
    analytics.trackEvent({ name: "login", properties: { method: "sso" } });
    return res.user;
  }

  function logout() {
    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    setAuthCookie(null);
    setUser(null);
    setOrganizations([]);
    analytics.reset();
  }

  return (
    <AuthContext.Provider value={{ user, loading, organizations, login, register, requestMagicLink, loginWithMagicLink, requestOtpLogin, verifyOtpLogin, ssoExchange, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
