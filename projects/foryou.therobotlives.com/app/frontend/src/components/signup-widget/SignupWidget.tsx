"use client";

/**
 * Thin React wrapper around the shared `public/widget.js` core (Chunk C / M2).
 *
 * Renders the same declarative placeholder the script-variant embed uses and ensures
 * `widget.js` is loaded once. The core's MutationObserver upgrades the placeholder in
 * place (Shadow DOM), so this stays a ~SSR-safe shell with no rendering logic of its own —
 * this is the "thin React wrapper" the listmonk migration keeps in place of a bespoke form
 * (replaces `waitlist-form.tsx` / `ContactModal.tsx`).
 *
 * Usage:
 *   <SignupWidget service="therobotlives" list="beta-access" />
 *   <SignupWidget slug="beta-access" theme={{ accent: "#4aedc4", mode: "dark" }} />
 */

import { useEffect, useRef } from "react";
import type { SignupWidgetProps } from "./types";

function ensureScript(src: string) {
  if (typeof document === "undefined") return;
  const existing = document.querySelector<HTMLScriptElement>(
    `script[data-foryou-widget]`,
  );
  if (existing) {
    // Already present — the core's MutationObserver will catch our placeholder,
    // but scan explicitly in case it already finished booting.
    window.__foryouWidget?.scan();
    return;
  }
  const s = document.createElement("script");
  s.src = src;
  s.async = true;
  s.defer = true;
  s.setAttribute("data-foryou-widget", "");
  document.body.appendChild(s);
}

export function SignupWidget({
  service,
  list,
  slug,
  theme,
  apiBase,
  source,
  scriptSrc = "/widget.js",
  className,
}: SignupWidgetProps) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    ensureScript(scriptSrc);
    // If the core is already loaded, mount this specific placeholder immediately.
    if (ref.current && window.__foryouWidget) {
      window.__foryouWidget.mount(ref.current);
    }
  }, [scriptSrc]);

  // Attribute set mirrors the raw script-variant snippet exactly.
  const attrs: Record<string, string> = {};
  if (slug) attrs["data-foryou-slug"] = slug;
  if (service) attrs["data-foryou-service"] = service;
  if (list) attrs["data-foryou-list"] = list;
  if (apiBase) attrs["data-foryou-api"] = apiBase;
  if (source) attrs["data-foryou-source"] = source;
  if (theme) attrs["data-foryou-theme"] = JSON.stringify(theme);

  return <div ref={ref} className={className} {...attrs} />;
}

export default SignupWidget;
