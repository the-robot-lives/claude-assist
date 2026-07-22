// Pure helpers for the Preference Center: effective-pref resolution,
// cross-service grouping, and small formatting utilities. No React here so
// these stay trivially testable.

import {
  CHANNEL_KEYS,
  type ChannelKey,
  type ContactPrefs,
  type Frequency,
  type QuietPeriod,
  type SignupView,
} from "./api";

export const FREQUENCIES: Frequency[] = [
  "immediate",
  "daily",
  "weekly",
  "monthly",
];

export const FREQUENCY_LABELS: Record<Frequency, string> = {
  immediate: "Immediately",
  daily: "Daily digest",
  weekly: "Weekly digest",
  monthly: "Monthly digest",
};

export const CHANNEL_LABELS: Record<ChannelKey, string> = {
  email: "Email",
  sms: "SMS",
  push: "Push",
  webhook: "Webhook",
  physical_mail: "Physical mail",
};

// Only email delivers this phase; the rest are stored-but-not-sent (post-M5).
export const DELIVERABLE_CHANNELS: ChannelKey[] = ["email"];

/** Fully-populated effective prefs (every channel key present). */
export interface EffectivePrefs {
  frequency: Frequency;
  channels: Record<ChannelKey, boolean>;
  quiet_periods: QuietPeriod[];
}

/** Baseline used when neither the subscriber nor the list specifies a value. */
export const DEFAULT_PREFS: EffectivePrefs = {
  frequency: "immediate",
  channels: { email: true, sms: false, push: false, webhook: false, physical_mail: false },
  quiet_periods: [],
};

function isEmpty(p?: ContactPrefs | null): boolean {
  if (!p) return true;
  return (
    p.frequency == null &&
    (p.channels == null || Object.keys(p.channels).length === 0) &&
    (p.quiet_periods == null || p.quiet_periods.length === 0)
  );
}

/**
 * Resolve effective preferences: subscriber override, then list default, then
 * the hardcoded baseline. Works today (list defaults absent) and upgrades
 * automatically once Chunk B joins `list.settings.contact_prefs`.
 */
export function effectivePrefs(signup: SignupView): EffectivePrefs {
  const override = signup.contact_prefs ?? undefined;
  const listDefault = signup.list?.settings?.contact_prefs ?? undefined;

  const frequency =
    override?.frequency ?? listDefault?.frequency ?? DEFAULT_PREFS.frequency;

  const channels: Record<ChannelKey, boolean> = { ...DEFAULT_PREFS.channels };
  for (const k of CHANNEL_KEYS) {
    channels[k] =
      override?.channels?.[k] ??
      listDefault?.channels?.[k] ??
      DEFAULT_PREFS.channels[k];
  }

  const quiet_periods =
    override?.quiet_periods ??
    listDefault?.quiet_periods ??
    DEFAULT_PREFS.quiet_periods;

  return { frequency, channels, quiet_periods };
}

/** Channels the subscriber may choose among (list-declared, else email only). */
export function availableChannels(signup: SignupView): ChannelKey[] {
  const declared = signup.list?.settings?.available_channels;
  if (declared && declared.length > 0) return declared;
  return ["email"];
}

/** True when the subscriber has any explicit override (vs. pure inheritance). */
export function hasOverride(signup: SignupView): boolean {
  return !isEmpty(signup.contact_prefs);
}

export function isPaused(signup: SignupView): boolean {
  if (!signup.pause_until) return false;
  const t = Date.parse(signup.pause_until);
  return Number.isFinite(t) && t > Date.now();
}

// ---------------------------------------------------------------------------
// Cross-service grouping.
// ---------------------------------------------------------------------------

export interface ServiceGroup {
  key: string;
  name: string;
  signups: SignupView[];
}

/** Best available display name for the originating Service/site. */
export function serviceName(signup: SignupView): string {
  const svc = signup.service;
  const branded = svc?.branding?.name || svc?.name;
  if (branded) return branded;
  // No joined service yet: fall back to the signup's provenance `source`, then
  // to a leading segment of the list's public slug, else "Other".
  // (Identical display names are disambiguated in groupByService.)
  if (signup.source && signup.source.trim()) return humanize(signup.source);
  const slug = signup.list?.public_slug || signup.list?.slug;
  if (slug && slug.includes("-")) return humanize(slug.split("-")[0]);
  return "Other";
}

function serviceKey(signup: SignupView): string {
  return (
    signup.service?.id ||
    signup.service?.slug ||
    (signup.source && signup.source.trim()) ||
    signup.list?.public_slug?.split("-")[0] ||
    "other"
  ).toLowerCase();
}

/** Group signups by Service, stable-ordered by service name then list name. */
export function groupByService(signups: SignupView[]): ServiceGroup[] {
  const map = new Map<string, ServiceGroup>();
  for (const s of signups) {
    const key = serviceKey(s);
    let g = map.get(key);
    if (!g) {
      g = { key, name: serviceName(s), signups: [] };
      map.set(key, g);
    }
    g.signups.push(s);
  }

  const groups = Array.from(map.values());

  // Disambiguate identical display names by appending the group key.
  const nameCounts = new Map<string, number>();
  for (const g of groups)
    nameCounts.set(g.name, (nameCounts.get(g.name) ?? 0) + 1);
  for (const g of groups) {
    if ((nameCounts.get(g.name) ?? 0) > 1) g.name = `${g.name} (${g.key})`;
    g.signups.sort((a, b) =>
      (a.list?.name ?? "").localeCompare(b.list?.name ?? ""),
    );
  }

  groups.sort((a, b) => a.name.localeCompare(b.name));
  return groups;
}

export function humanize(raw: string): string {
  return raw
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

export function formatDate(iso?: string | null): string {
  if (!iso) return "—";
  const t = Date.parse(iso);
  if (!Number.isFinite(t)) return "—";
  return new Date(t).toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

/** Compact one-line summary of effective prefs for a subscription row. */
export function prefsSummary(signup: SignupView): string {
  const eff = effectivePrefs(signup);
  const on = CHANNEL_KEYS.filter((k) => eff.channels[k]).map(
    (k) => CHANNEL_LABELS[k],
  );
  const freq = FREQUENCY_LABELS[eff.frequency];
  const chans = on.length ? on.join(", ") : "No channels";
  return `${freq} · ${chans}`;
}
