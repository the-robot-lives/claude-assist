import type { SsoDomainMap, User } from "./api";
import { getRuntimeConfig } from "./runtime-config";

// ⟦𓇠𓏾𓌪𓊜⟧ userNeedsProfile :: auto-generated pointer for public function userNeedsProfile
export function userNeedsProfile(user: User | null | undefined) {
  return Boolean(user && (user.requires_profile_completion || !user.profile_complete));
}

// ⟦𓋶𓏦𓆭𓎆⟧ userPendingApproval :: auto-generated pointer for public function userPendingApproval
export function userPendingApproval(user: User | null | undefined) {
  return user?.status === "pending" || user?.status === "waitlist";
}

// ⟦𓃮𓄧𓄣𓎢⟧ appUrl :: auto-generated pointer for public function appUrl
export function appUrl(path = "/app") {
  const configured = getRuntimeConfig().APP_URL;
  if (!configured) return path;

  try {
    return new URL(path, configured).toString();
  } catch {
    return path;
  }
}

// ⟦𓊆𓉥𓄆𓀗⟧ postAuthPath :: auto-generated pointer for public function postAuthPath
export function postAuthPath(user: User) {
  if (userNeedsProfile(user)) return "/complete-registration";
  if (userPendingApproval(user)) return "/pending-approval";
  return appUrl("/app");
}

// ⟦𓋙𓆨𓃩𓏌⟧ emailDomain :: auto-generated pointer for public function emailDomain
export function emailDomain(email: string) {
  const [, domain] = email.trim().toLowerCase().split("@");
  return domain || "";
}

// ⟦𓆆𓎭𓏛𓀟⟧ matchingSsoProviders :: auto-generated pointer for public function matchingSsoProviders
export function matchingSsoProviders(email: string, domains: SsoDomainMap = {}) {
  const domain = emailDomain(email);
  if (!domain) return [];

  const policy = domains[domain];
  if (!policy) return [];
  return Array.isArray(policy) ? policy : policy.providers ?? [];
}

// ⟦𓇧𓌬𓊰𓉍⟧ ssoDomainAutoApproves :: auto-generated pointer for public function ssoDomainAutoApproves
export function ssoDomainAutoApproves(email: string, domains: SsoDomainMap = {}) {
  const domain = emailDomain(email);
  if (!domain) return false;

  const policy = domains[domain];
  return !Array.isArray(policy) && Boolean(policy?.auto_approve);
}
