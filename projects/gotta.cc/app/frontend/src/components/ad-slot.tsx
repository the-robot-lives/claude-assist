"use client";

import { useEffect, useRef, useState } from "react";
import { getRuntimeConfig } from "@/lib/runtime-config";
import { hasConsent, onConsentChange } from "@/lib/consent";

/**
 * gotta.cc runs exactly three ad units. Adding a fourth is a product decision,
 * not a config change — keep the list here so the placements stay auditable.
 *
 * Fill each entry with the `data-ad-slot` ID from the AdSense console
 * (Ads → By ad unit → the 10-digit number). A slot left empty renders nothing,
 * so an unconfigured placement is invisible rather than broken.
 */
export const AD_SLOTS = {
  /** Browse listing, between the 6th and 7th rows. */
  browseInFeed: "",
  /** Browse right rail, below the submit promo. */
  browseRail: "",
  /** Site detail, after "More in {Category}". */
  siteDetail: "",
} as const;

/**
 * `feed` and `detail` are constrained to horizontal shapes so an ad can never
 * grow tall enough to shove listings apart; `rail` is a fixed rectangle.
 */
export type AdFormat = "feed" | "rail" | "detail";

const AD_FORMAT_ATTR: Record<AdFormat, string> = {
  feed: "horizontal",
  rail: "rectangle",
  detail: "horizontal",
};

interface AdsByGoogleWindow {
  adsbygoogle?: unknown[];
}

/**
 * A single labeled ad frame. Renders nothing at all unless the publisher ID is
 * configured, a slot ID is supplied, and the visitor has accepted marketing
 * cookies — so dev, preview, and opted-out sessions stay clean.
 */
export function AdSlot({ slot, format }: { slot: string; format: AdFormat }) {
  const [client, setClient] = useState("");
  const [allowed, setAllowed] = useState(false);
  const pushed = useRef(false);

  // Resolved after mount: the publisher ID may arrive at runtime via
  // window.__ENV, and reading consent during render would desync hydration.
  useEffect(() => {
    setClient(getRuntimeConfig().ADSENSE_CLIENT ?? "");
    setAllowed(hasConsent("marketing"));
    return onConsentChange((state) => setAllowed(Boolean(state?.categories.marketing)));
  }, []);

  const active = Boolean(client) && Boolean(slot) && allowed;

  useEffect(() => {
    if (!active || pushed.current) return;
    try {
      const w = window as unknown as AdsByGoogleWindow;
      w.adsbygoogle = w.adsbygoogle ?? [];
      w.adsbygoogle.push({});
      pushed.current = true;
    } catch {
      // Script blocked or offline — leave the frame empty rather than throwing.
    }
  }, [active]);

  if (!active) return null;

  return (
    <aside className={`gc-ad gc-ad-${format}`}>
      <span className="gc-ad-tag">Advertisement</span>
      <ins
        className="adsbygoogle gc-ad-unit"
        style={{ display: "block" }}
        data-ad-client={client}
        data-ad-slot={slot}
        data-ad-format={AD_FORMAT_ATTR[format]}
        data-full-width-responsive={format === "rail" ? "false" : "true"}
      />
    </aside>
  );
}
