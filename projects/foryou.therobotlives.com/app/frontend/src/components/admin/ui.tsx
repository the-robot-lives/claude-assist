"use client";

// Small presentational primitives for the admin console. All styling lives in
// the chunk-scoped `sg-*` classes in ./admin.css (imported here, not globals.css,
// so the three concurrent frontend chunks never touch the same stylesheet).

import "./admin.css";
import Link from "next/link";
import type { ReactNode } from "react";
import type { SignupStatus } from "./admin-fetch";

// ---- Badge -----------------------------------------------------------------

type BadgeTone = "success" | "warning" | "danger" | "muted" | "neutral";

export function Badge({ tone = "neutral", children }: { tone?: BadgeTone; children: ReactNode }) {
  return <span className={`sg-badge sg-badge--${tone}`}>{children}</span>;
}

const SIGNUP_STATUS_TONE: Record<SignupStatus, BadgeTone> = {
  subscribed: "success",
  pending_optin: "warning",
  unsubscribed: "muted",
  bounced: "danger",
};

const SIGNUP_STATUS_LABEL: Record<SignupStatus, string> = {
  subscribed: "Subscribed",
  pending_optin: "Pending opt-in",
  unsubscribed: "Unsubscribed",
  bounced: "Bounced",
};

export function SignupStatusBadge({ status }: { status: SignupStatus }) {
  const tone = SIGNUP_STATUS_TONE[status] ?? "neutral";
  const label = SIGNUP_STATUS_LABEL[status] ?? status;
  return <Badge tone={tone}>{label}</Badge>;
}

export function OptInBadge({ mode }: { mode: "double" | "single" }) {
  return <Badge tone={mode === "double" ? "neutral" : "muted"}>{mode === "double" ? "Double opt-in" : "Single opt-in"}</Badge>;
}

// ---- Empty state -----------------------------------------------------------

export function EmptyState({
  title,
  message,
  cta,
}: {
  title: string;
  message?: string;
  cta?: { href: string; label: string };
}) {
  return (
    <div className="sg-empty-state">
      <p className="sg-empty-state__title">{title}</p>
      {message ? <p className="sg-empty-state__message">{message}</p> : null}
      {cta ? (
        <Link href={cta.href} className="sg-btn sg-btn--outline sg-btn--sm">
          {cta.label}
        </Link>
      ) : null}
    </div>
  );
}

// ---- Error panel -----------------------------------------------------------

export function ErrorPanel({ message, backLink }: { message: string; backLink?: { href: string; label: string } }) {
  return (
    <div className="sg-error">
      <p>{message}</p>
      {backLink ? (
        <Link href={backLink.href} className="sg-back-link">
          &larr; {backLink.label}
        </Link>
      ) : null}
    </div>
  );
}

// ---- Stat tiles ------------------------------------------------------------

export function StatGrid({ children }: { children: ReactNode }) {
  return <div className="sg-stat-grid">{children}</div>;
}

export function StatTile({ label, value, hint }: { label: string; value: ReactNode; hint?: string }) {
  return (
    <div className="sg-stat-tile">
      <p className="sg-stat-tile__label">{label}</p>
      <p className="sg-stat-tile__value">{value}</p>
      {hint ? <p className="sg-stat-tile__hint">{hint}</p> : null}
    </div>
  );
}

// ---- Back link -------------------------------------------------------------

export function BackLink({ href, label }: { href: string; label: string }) {
  return (
    <Link href={href} className="sg-back-link">
      &larr; {label}
    </Link>
  );
}

// ---- Skeleton --------------------------------------------------------------

export function SkeletonTiles({ count = 4 }: { count?: number }) {
  return (
    <div className="sg-stat-grid">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="sg-stat-tile">
          <span className="sg-skeleton sg-skeleton--label" />
          <span className="sg-skeleton sg-skeleton--value" />
        </div>
      ))}
    </div>
  );
}

export function SkeletonRows({ count = 6 }: { count?: number }) {
  return (
    <div className="sg-skeleton-rows">
      {Array.from({ length: count }).map((_, i) => (
        <span key={i} className="sg-skeleton sg-skeleton--row" />
      ))}
    </div>
  );
}
