import type { User } from "./api";
import { getRuntimeConfig } from "./runtime-config";

export function userNeedsProfile(user: User | null | undefined) {
  return Boolean(user && (user.requires_profile_completion || !user.profile_complete));
}

export function userPendingApproval(user: User | null | undefined) {
  return user?.status === "pending" || user?.status === "waitlist";
}

export function appUrl(path = "/app") {
  const configured = getRuntimeConfig().APP_URL;
  if (!configured) return path;

  try {
    return new URL(path, configured).toString();
  } catch {
    return path;
  }
}

export function postAuthPath(user: User) {
  if (userNeedsProfile(user)) return "/complete-registration";
  if (userPendingApproval(user)) return "/pending-approval";
  return appUrl("/app");
}

export function emailDomain(email: string) {
  const [, domain] = email.trim().toLowerCase().split("@");
  return domain || "";
}

export function matchingSsoProviders(email: string, domains: Record<string, string[]> = {}) {
  const domain = emailDomain(email);
  return domain ? domains[domain] ?? [] : [];
}
