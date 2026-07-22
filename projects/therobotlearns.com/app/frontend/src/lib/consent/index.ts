export const CONSENT_VERSION = 1;
export const CONSENT_STORAGE_KEY = `start-app.cookie-consent.v${CONSENT_VERSION}`;
export const BROWSER_SESSION_STORAGE_KEY = "start-app.browser-session-id";

const CONSENT_EVENT_NAME = "start-app:cookie-consent-change";

export interface ConsentPreferences {
  necessary: true;
  analytics: boolean;
  marketing: boolean;
  preferences: boolean;
}

export type ConsentCategory = keyof ConsentPreferences;
export type OptionalConsentCategory = Exclude<ConsentCategory, "necessary">;

export interface ConsentState {
  version: number;
  categories: ConsentPreferences;
  acceptedAt?: string;
  updatedAt?: string;
}

export type ConsentChangeHandler = (state: ConsentState | null) => void;

export const consentCategoryDetails: ReadonlyArray<{
  id: ConsentCategory;
  label: string;
  description: string;
  required: boolean;
}> = [
  {
    id: "necessary",
    label: "Necessary",
    description: "Required for sign-in, security, and core app behavior.",
    required: true,
  },
  {
    id: "analytics",
    label: "Analytics",
    description: "Helps us understand page usage and improve the product.",
    required: false,
  },
  {
    id: "marketing",
    label: "Marketing",
    description: "Reserved for optional campaign attribution or advertising tools.",
    required: false,
  },
  {
    id: "preferences",
    label: "Preferences",
    description: "Stores optional display and personalization choices.",
    required: false,
  },
];

export const defaultConsentPreferences: ConsentPreferences = {
  necessary: true,
  analytics: false,
  marketing: false,
  preferences: false,
};

const listeners = new Set<ConsentChangeHandler>();
let inMemoryConsentState: ConsentState | null = null;
let useInMemoryConsentState = false;
let storageListenerAttached = false;

function isBrowser() {
  return typeof window !== "undefined";
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function normalizePreferences(
  preferences?: Partial<Record<ConsentCategory, boolean>>
): ConsentPreferences {
  return {
    necessary: true,
    analytics: Boolean(preferences?.analytics),
    marketing: Boolean(preferences?.marketing),
    preferences: Boolean(preferences?.preferences),
  };
}

function emitConsentChange(state: ConsentState | null) {
  listeners.forEach((listener) => listener(state));

  if (isBrowser()) {
    window.dispatchEvent(
      new CustomEvent<ConsentState | null>(CONSENT_EVENT_NAME, { detail: state })
    );
  }
}

function ensureStorageListener() {
  if (!isBrowser() || storageListenerAttached) return;

  window.addEventListener("storage", (event) => {
    if (event.key === CONSENT_STORAGE_KEY) {
      emitConsentChange(getConsentState());
    }
  });
  storageListenerAttached = true;
}

export function getConsentState(): ConsentState | null {
  if (!isBrowser()) return null;
  if (useInMemoryConsentState) return inMemoryConsentState;

  try {
    const raw = window.localStorage.getItem(CONSENT_STORAGE_KEY);
    if (!raw) return null;

    const parsed: unknown = JSON.parse(raw);
    if (!isObject(parsed) || parsed.version !== CONSENT_VERSION) return null;
    if (!isObject(parsed.categories)) return null;

    const state = {
      version: CONSENT_VERSION,
      categories: normalizePreferences(
        parsed.categories as Partial<Record<ConsentCategory, boolean>>
      ),
      acceptedAt: typeof parsed.acceptedAt === "string" ? parsed.acceptedAt : undefined,
      updatedAt: typeof parsed.updatedAt === "string" ? parsed.updatedAt : undefined,
    };
    inMemoryConsentState = state;
    return state;
  } catch {
    return inMemoryConsentState;
  }
}

export function getConsentPreferences(): ConsentPreferences {
  return getConsentState()?.categories ?? defaultConsentPreferences;
}

export function hydrateConsentState(state: ConsentState | null) {
  inMemoryConsentState = state;
  if (isBrowser()) {
    try {
      if (state) {
        window.localStorage.setItem(CONSENT_STORAGE_KEY, JSON.stringify(state));
      } else {
        window.localStorage.removeItem(CONSENT_STORAGE_KEY);
      }
      useInMemoryConsentState = false;
    } catch {
      useInMemoryConsentState = true;
    }
  }
  emitConsentChange(state);
}

export function setConsentPreferences(
  preferences: Partial<Record<ConsentCategory, boolean>>
): ConsentState {
  const timestamp = new Date().toISOString();
  const existing = getConsentState();
  const state: ConsentState = {
    version: CONSENT_VERSION,
    categories: normalizePreferences(preferences),
    acceptedAt: existing?.acceptedAt ?? timestamp,
    updatedAt: timestamp,
  };
  inMemoryConsentState = state;

  if (isBrowser()) {
    try {
      window.localStorage.setItem(CONSENT_STORAGE_KEY, JSON.stringify(state));
      useInMemoryConsentState = false;
    } catch {
      useInMemoryConsentState = true;
      // Keep the in-memory choice for this page view when storage is unavailable.
    }
  }

  emitConsentChange(state);
  return state;
}

export function clearConsentPreferences() {
  inMemoryConsentState = null;
  if (isBrowser()) {
    try {
      window.localStorage.removeItem(CONSENT_STORAGE_KEY);
      useInMemoryConsentState = false;
    } catch {
      useInMemoryConsentState = true;
      // Ignore storage failures; listeners still receive the cleared state.
    }
  }
  emitConsentChange(null);
}

export function hasConsent(category: ConsentCategory): boolean {
  if (category === "necessary") return true;
  return Boolean(getConsentState()?.categories[category]);
}

export function getBrowserSessionId() {
  if (!isBrowser()) return "";

  try {
    const existing = window.sessionStorage.getItem(BROWSER_SESSION_STORAGE_KEY);
    if (existing) return existing;

    const id = window.crypto?.randomUUID?.() ?? fallbackUuid();
    window.sessionStorage.setItem(BROWSER_SESSION_STORAGE_KEY, id);
    return id;
  } catch {
    return inMemoryBrowserSessionId();
  }
}

let fallbackBrowserSessionId: string | null = null;

function inMemoryBrowserSessionId() {
  fallbackBrowserSessionId ||= fallbackUuid();
  return fallbackBrowserSessionId;
}

function fallbackUuid() {
  const randomByte = () => {
    const browserCrypto = isBrowser() ? window.crypto : undefined;
    if (browserCrypto?.getRandomValues) {
      return browserCrypto.getRandomValues(new Uint8Array(1))[0];
    }
    return Math.floor(Math.random() * 256);
  };

  return "10000000-1000-4000-8000-100000000000".replace(/[018]/g, (c) =>
    (Number(c) ^ (randomByte() & (15 >> (Number(c) / 4)))).toString(16)
  );
}

export function onConsentChange(handler: ConsentChangeHandler) {
  ensureStorageListener();
  listeners.add(handler);
  return () => {
    listeners.delete(handler);
  };
}

export function acceptAllConsent(): ConsentState {
  return setConsentPreferences({
    necessary: true,
    analytics: true,
    marketing: true,
    preferences: true,
  });
}

export function rejectOptionalConsent(): ConsentState {
  return setConsentPreferences(defaultConsentPreferences);
}
