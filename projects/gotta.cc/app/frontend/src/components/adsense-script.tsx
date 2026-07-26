"use client";

import Script from "next/script";
import { useEffect, useState } from "react";
import { getRuntimeConfig } from "@/lib/runtime-config";
import { hasConsent, onConsentChange } from "@/lib/consent";

/**
 * Loads the AdSense loader script once for the whole app. Mounted from the root
 * layout, but kept as a client component for two reasons: most routes are
 * statically prerendered (so a server component would only ever see the
 * build-time env), and the marketing-consent check has to run in the browser.
 */
export function AdSenseScript() {
  const [client, setClient] = useState("");
  const [allowed, setAllowed] = useState(false);

  useEffect(() => {
    setClient(getRuntimeConfig().ADSENSE_CLIENT ?? "");
    setAllowed(hasConsent("marketing"));
    return onConsentChange((state) => setAllowed(Boolean(state?.categories.marketing)));
  }, []);

  if (!client || !allowed) return null;

  return (
    <Script
      id="adsbygoogle-loader"
      strategy="afterInteractive"
      crossOrigin="anonymous"
      src={`https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${encodeURIComponent(client)}`}
    />
  );
}
