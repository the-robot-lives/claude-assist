"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import {
  acceptAllConsent,
  consentCategoryDetails,
  defaultConsentPreferences,
  getConsentState,
  hasConsent,
  onConsentChange,
  rejectOptionalConsent,
  setConsentPreferences,
  type ConsentCategory,
  type ConsentPreferences,
  type ConsentState,
  type OptionalConsentCategory,
} from "@/lib/consent";
import { api } from "@/lib/api";

// When a logged-in user makes a consent choice, persist it to their account so
// it is authoritative and crosses the apex → app.* subdomain boundary. Anonymous
// visitors just keep the local choice. Best-effort — never block the UI.
function persistConsentToAccount(state: ConsentState | null) {
  if (typeof window === "undefined") return;
  if (!state || !window.localStorage.getItem("access_token")) return;
  api.updateConsent(state.categories as unknown as Record<string, boolean>).catch(() => {});
}

interface CookieConsentContextValue {
  state: ConsentState | null;
  preferences: ConsentPreferences;
  hasDecision: boolean;
  isSettingsOpen: boolean;
  openSettings: () => void;
  closeSettings: () => void;
  acceptAll: () => void;
  rejectOptional: () => void;
  savePreferences: (preferences: Partial<Record<ConsentCategory, boolean>>) => void;
  hasCategoryConsent: (category: ConsentCategory) => boolean;
}

const CookieConsentContext = createContext<CookieConsentContextValue | null>(null);

function isOptionalCategory(category: ConsentCategory): category is OptionalConsentCategory {
  return category !== "necessary";
}

export function CookieConsentProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<ConsentState | null>(null);
  const [mounted, setMounted] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);

  useEffect(() => {
    setState(getConsentState());
    setMounted(true);
    return onConsentChange(setState);
  }, []);

  const openSettings = useCallback(() => setIsSettingsOpen(true), []);
  const closeSettings = useCallback(() => setIsSettingsOpen(false), []);

  const acceptAll = useCallback(() => {
    const next = acceptAllConsent();
    setState(next);
    persistConsentToAccount(next);
    setIsSettingsOpen(false);
  }, []);

  const rejectOptional = useCallback(() => {
    const next = rejectOptionalConsent();
    setState(next);
    persistConsentToAccount(next);
    setIsSettingsOpen(false);
  }, []);

  const savePreferences = useCallback(
    (preferences: Partial<Record<ConsentCategory, boolean>>) => {
      const next = setConsentPreferences(preferences);
      setState(next);
      persistConsentToAccount(next);
      setIsSettingsOpen(false);
    },
    []
  );

  const value = useMemo<CookieConsentContextValue>(
    () => ({
      state,
      preferences: state?.categories ?? defaultConsentPreferences,
      hasDecision: Boolean(state),
      isSettingsOpen,
      openSettings,
      closeSettings,
      acceptAll,
      rejectOptional,
      savePreferences,
      hasCategoryConsent: hasConsent,
    }),
    [
      acceptAll,
      closeSettings,
      isSettingsOpen,
      openSettings,
      rejectOptional,
      savePreferences,
      state,
    ]
  );

  return (
    <CookieConsentContext.Provider value={value}>
      {children}
      {mounted ? <CookieConsentBanner /> : null}
    </CookieConsentContext.Provider>
  );
}

export function useCookieConsent() {
  const context = useContext(CookieConsentContext);
  if (!context) {
    throw new Error("useCookieConsent must be used inside CookieConsentProvider");
  }
  return context;
}

export function CookieSettingsButton({ className }: { className?: string }) {
  const { openSettings } = useCookieConsent();

  return (
    <button
      type="button"
      className={className ?? "sg-btn sg-btn--outline sg-btn--sm"}
      onClick={openSettings}
    >
      Cookie Settings
    </button>
  );
}

export function CookieConsentBanner() {
  const {
    hasDecision,
    isSettingsOpen,
    openSettings,
    closeSettings,
    acceptAll,
    rejectOptional,
    savePreferences,
    preferences,
  } = useCookieConsent();
  const [draft, setDraft] = useState<ConsentPreferences>(preferences);

  useEffect(() => {
    if (!hasDecision || isSettingsOpen) {
      setDraft(preferences);
    }
  }, [hasDecision, isSettingsOpen, preferences]);

  if (hasDecision && !isSettingsOpen) return null;

  const updateDraft = (category: OptionalConsentCategory, value: boolean) => {
    setDraft((current) => ({ ...current, [category]: value }));
  };

  const toggleManage = () => {
    if (isSettingsOpen) {
      closeSettings();
    } else {
      openSettings();
    }
  };

  return (
    <>
    <style>{COOKIE_CSS}</style>
    <section
      className={`cookie-consent${isSettingsOpen ? " cookie-consent--open" : ""}`}
      role="dialog"
      aria-modal="false"
      aria-labelledby="cookie-consent-title"
    >
      <div className="cookie-consent__bar">
        <div className="cookie-consent__intro">
          <p id="cookie-consent-title" className="cookie-consent__title">
            Cookies
          </p>
          <p className="cookie-consent__copy">
            We use necessary storage to keep this app working. Optional categories stay off
            until you approve them.
          </p>
        </div>

        <div className="cookie-consent__actions">
          <button
            type="button"
            className="sg-btn sg-btn--link"
            aria-expanded={isSettingsOpen}
            onClick={toggleManage}
          >
            {isSettingsOpen ? "Hide choices" : "Manage choices"}
          </button>
          <button type="button" className="sg-btn sg-btn--outline" onClick={rejectOptional}>
            Reject optional
          </button>
          <button type="button" className="sg-btn sg-btn--black" onClick={acceptAll}>
            Accept all
          </button>
        </div>
      </div>

      {isSettingsOpen ? (
        <div className="cookie-consent__panel">
          <div className="cookie-consent__categories">
            {consentCategoryDetails.map((category) => (
              <label key={category.id} className="cookie-consent__category">
                <span>
                  <span className="cookie-consent__category-title">{category.label}</span>
                  <span className="cookie-consent__category-copy">{category.description}</span>
                </span>
                <input
                  type="checkbox"
                  checked={draft[category.id]}
                  disabled={category.required}
                  onChange={(event) => {
                    if (isOptionalCategory(category.id)) {
                      updateDraft(category.id, event.target.checked);
                    }
                  }}
                  aria-label={`${category.label} cookies`}
                />
              </label>
            ))}
          </div>
          <div className="cookie-consent__panel-actions">
            <button type="button" className="sg-btn sg-btn--black" onClick={() => savePreferences(draft)}>
              Save choices
            </button>
          </div>
        </div>
      ) : null}
    </section>
    </>
  );
}

/*
 * Consent banner styling — slim footer bar pinned to the bottom of the viewport.
 * The full per-category preferences live in a collapsible panel toggled by
 * "Manage choices", so the default footprint is a one-line strip. Theme CSS
 * variables with safe fallbacks; also styles the raw .sg-btn buttons.
 */
const COOKIE_CSS = `
.cookie-consent {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 60;
  background: var(--surface, #fbf7f0);
  color: var(--text, #211);
  border-top: 1px solid var(--border, rgba(0,0,0,0.14));
  box-shadow: 0 -6px 20px rgba(0,0,0,0.10);
  font-family: var(--font-sans, system-ui, -apple-system, sans-serif);
}
.cookie-consent__bar {
  padding: 8px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
.cookie-consent__intro { min-width: 0; }
.cookie-consent__title {
  display: none;
}
.cookie-consent__copy {
  font-size: 12.5px;
  line-height: 1.4;
  margin: 0;
  color: var(--text-muted, #5a544c);
}
.cookie-consent__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: center;
  justify-content: flex-end;
  flex-shrink: 0;
}
.cookie-consent__panel {
  padding: 4px 16px 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  border-top: 1px solid var(--border, rgba(0,0,0,0.10));
  max-height: 60vh;
  overflow-y: auto;
}
.cookie-consent__categories { display: flex; flex-direction: column; gap: 6px; }
.cookie-consent__category {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 10px;
  border: 1px solid var(--border, rgba(0,0,0,0.12));
  border-radius: 8px;
}
.cookie-consent__category-title { display: block; font-weight: 600; font-size: 12.5px; }
.cookie-consent__category-copy { display: block; font-size: 11.5px; color: var(--text-muted, #6a645c); margin-top: 2px; }
.cookie-consent__category input {
  margin-top: 3px;
  width: 16px;
  height: 16px;
  accent-color: var(--brand-blue, #2d5a2d);
  flex-shrink: 0;
}
.cookie-consent__panel-actions { display: flex; justify-content: flex-end; }
.cookie-consent .sg-btn {
  font-family: var(--font-sans, system-ui, sans-serif);
  font-weight: 600;
  font-size: 12.5px;
  padding: 6px 12px;
  border-radius: 8px;
  cursor: pointer;
  border: 1px solid var(--border-strong, var(--border, rgba(0,0,0,0.2)));
  background: transparent;
  color: var(--text, #211);
  transition: background 140ms ease, color 140ms ease, border-color 140ms ease;
}
.cookie-consent .sg-btn--link {
  border-color: transparent;
  padding: 6px 4px;
  text-decoration: underline;
}
.cookie-consent .sg-btn:hover { border-color: var(--brand-blue, #2d5a2d); color: var(--brand-blue, #2d5a2d); }
.cookie-consent .sg-btn--black { background: var(--brand-blue, #234e23); color: #fff; border-color: transparent; }
.cookie-consent .sg-btn--black:hover { background: #1c3f1c; color: #fff; }
@media (max-width: 560px) {
  .cookie-consent__bar { flex-direction: column; align-items: stretch; gap: 6px; padding: 8px 12px; }
  .cookie-consent__actions { justify-content: stretch; }
  .cookie-consent__actions > .sg-btn { flex: 1 1 auto; }
  .cookie-consent__copy { font-size: 12px; }
}
`;
