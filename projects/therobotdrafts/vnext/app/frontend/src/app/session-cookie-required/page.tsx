"use client";

import { useCookieConsent } from "@/components/cookie-consent";

export default function SessionCookieRequiredPage() {
  const { openSettings } = useCookieConsent();

  return (
    <div className="content">
      <main>
        <h1 className="sg-page-title">Session Cookie Required</h1>
        <p className="sg-page-intro">
          This app requires necessary session storage for sign-in, security, and core app behavior.
        </p>
        <button type="button" className="sg-btn sg-btn--black" onClick={openSettings}>
          Cookie Settings
        </button>
      </main>
    </div>
  );
}
