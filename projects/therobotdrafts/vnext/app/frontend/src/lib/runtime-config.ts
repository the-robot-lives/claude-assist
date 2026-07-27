export interface RuntimeConfig {
  GA_MEASUREMENT_ID?: string;
  POSTHOG_KEY?: string;
  POSTHOG_HOST?: string;
  API_URL?: string;
  APP_URL?: string;
  COOKIE_DOMAIN?: string;
  OTEL_COLLECTOR_URL?: string;
}

export function getRuntimeConfig(): RuntimeConfig {
  if (typeof window !== "undefined" && (window as unknown as { __ENV: RuntimeConfig }).__ENV) {
    return (window as unknown as { __ENV: RuntimeConfig }).__ENV;
  }
  return {
    GA_MEASUREMENT_ID: process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID,
    POSTHOG_KEY: process.env.NEXT_PUBLIC_POSTHOG_KEY,
    POSTHOG_HOST: process.env.NEXT_PUBLIC_POSTHOG_HOST,
    API_URL: process.env.NEXT_PUBLIC_API_URL,
    APP_URL: process.env.NEXT_PUBLIC_APP_URL,
    COOKIE_DOMAIN: process.env.NEXT_PUBLIC_COOKIE_DOMAIN,
    OTEL_COLLECTOR_URL: process.env.NEXT_PUBLIC_OTEL_COLLECTOR_URL,
  };
}

export function runtimeCookieDomainAttribute() {
  const cookieDomain = getRuntimeConfig().COOKIE_DOMAIN?.trim();
  if (!cookieDomain || typeof window === "undefined") return "";

  const normalizedDomain = cookieDomain.replace(/^\./, "").toLowerCase();
  const hostname = window.location.hostname.toLowerCase();
  const isLocalDomain =
    normalizedDomain === "localhost" ||
    normalizedDomain.includes(":") ||
    /^[0-9.]+$/.test(normalizedDomain);

  if (isLocalDomain) return "";
  if (hostname !== normalizedDomain && !hostname.endsWith(`.${normalizedDomain}`)) {
    return "";
  }

  return `; Domain=${cookieDomain}`;
}

export function runtimeAuthCookieClearAttributes() {
  if (typeof window === "undefined") return [""];

  const candidates = new Set<string>([""]);
  const configured = getRuntimeConfig().COOKIE_DOMAIN?.trim();
  const hostname = window.location.hostname.toLowerCase();
  const names = [configured, hostname].filter((value): value is string => Boolean(value));

  for (const name of names) {
    const normalized = name.replace(/^\./, "").toLowerCase();
    const isLocalDomain =
      normalized === "localhost" ||
      normalized.includes(":") ||
      /^[0-9.]+$/.test(normalized);

    if (isLocalDomain) continue;
    if (hostname !== normalized && !hostname.endsWith(`.${normalized}`)) continue;

    candidates.add(`; Domain=${normalized}`);
    candidates.add(`; Domain=.${normalized}`);

    const labels = normalized.split(".");
    if (labels.length > 2) {
      const parent = labels.slice(1).join(".");
      candidates.add(`; Domain=${parent}`);
      candidates.add(`; Domain=.${parent}`);
    }
  }

  return [...candidates];
}
