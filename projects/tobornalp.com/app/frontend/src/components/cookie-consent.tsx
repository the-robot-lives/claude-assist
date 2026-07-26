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
import { btnClass } from "@/components/ui";

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

  // The old default leaned on `.sg-btn`, which has no rule in this app — the
  // button rendered raw. Fall back to the console pill instead.
  return (
    <button
      type="button"
      className={className ?? btnClass("default", "text-[11px]")}
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
 * "Manage choices", so the default footprint is a one-line strip.
 *
 * Dark-neon console skin: panel surface over the true-black ground, a hairline
 * --line top edge, mono voice, pill buttons. "Accept all" is the primary — a
 * solid mint field, and a solid mint field always carries #000 ink, never white.
 * Fallbacks are the literal dark-theme values so the bar never flashes a light
 * strip if it paints before the token sheet lands.
 */
const COOKIE_CSS = `
.cookie-consent {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 60;
  background: var(--panel, #0D0D10);
  color: var(--ink, #EDEDF2);
  border-top: 1px solid var(--line, #1F1F26);
  box-shadow: 0 -6px 20px rgba(0,0,0,0.55);
  font-family: var(--mono, ui-monospace, "SF Mono", Menlo, Consolas, monospace);
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
  font-size: 12px;
  line-height: 1.45;
  margin: 0;
  color: var(--mut, #9C9CA8);
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
  border-top: 1px solid var(--line, #1F1F26);
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
  background: var(--panel2, #16161B);
  border: 1px solid var(--line, #1F1F26);
  border-radius: var(--r-sm, 10px);
}
.cookie-consent__category-title {
  display: block;
  font-weight: 700;
  font-size: 12px;
  color: var(--ink, #EDEDF2);
}
.cookie-consent__category-copy {
  display: block;
  font-size: 11px;
  color: var(--faint, #64646F);
  margin-top: 2px;
}
.cookie-consent__category input {
  margin-top: 3px;
  width: 16px;
  height: 16px;
  accent-color: var(--acc, #3EF2A6);
  flex-shrink: 0;
}
.cookie-consent__category input:disabled { opacity: .6; }
.cookie-consent__panel-actions { display: flex; justify-content: flex-end; }
.cookie-consent .sg-btn {
  font-family: inherit;
  font-weight: 700;
  font-size: 12px;
  padding: 5px 14px;
  border-radius: var(--r-pill, 999px);
  cursor: pointer;
  border: 1px solid var(--line2, #31313B);
  background: var(--panel2, #16161B);
  color: var(--ink, #EDEDF2);
  transition: background 140ms ease, color 140ms ease, border-color 140ms ease;
}
.cookie-consent .sg-btn--link {
  border-color: transparent;
  background: transparent;
  padding: 5px 6px;
  color: var(--mut, #9C9CA8);
  text-decoration: underline;
  text-underline-offset: 3px;
}
.cookie-consent .sg-btn:hover { border-color: var(--acc-line, rgba(62,242,166,.45)); color: var(--acc, #3EF2A6); }
.cookie-consent .sg-btn--link:hover { border-color: transparent; color: var(--acc, #3EF2A6); }
/* Primary: solid mint field ⇒ black ink. */
.cookie-consent .sg-btn--black {
  background: var(--acc, #3EF2A6);
  color: #000;
  border-color: var(--acc, #3EF2A6);
}
.cookie-consent .sg-btn--black:hover {
  background: var(--acc-hi, #93FAD2);
  border-color: var(--acc-hi, #93FAD2);
  color: #000;
}
.cookie-consent .sg-btn:focus-visible {
  outline: 2px solid var(--acc, #3EF2A6);
  outline-offset: 2px;
}
@media (max-width: 560px) {
  .cookie-consent__bar { flex-direction: column; align-items: stretch; gap: 6px; padding: 8px 12px; }
  .cookie-consent__actions { justify-content: stretch; }
  .cookie-consent__actions > .sg-btn { flex: 1 1 auto; }
  .cookie-consent__copy { font-size: 11px; }
}
`;
