"use client";

import type { SignupStatus } from "./api";
import styles from "./preference-center.module.css";

const STATUS_STYLE: Record<SignupStatus, string> = {
  subscribed: styles.badgeSubscribed,
  pending_optin: styles.badgePending,
  unsubscribed: styles.badgeUnsubscribed,
  bounced: styles.badgeBounced,
};

const STATUS_LABEL: Record<SignupStatus, string> = {
  subscribed: "Subscribed",
  pending_optin: "Pending confirmation",
  unsubscribed: "Unsubscribed",
  bounced: "Bounced",
};

export function StatusBadge({
  status,
  paused = false,
}: {
  status: SignupStatus;
  paused?: boolean;
}) {
  return (
    <span style={{ display: "inline-flex", gap: "0.35rem" }}>
      <span className={`${styles.badge} ${STATUS_STYLE[status]}`}>
        {STATUS_LABEL[status]}
      </span>
      {paused && (
        <span className={`${styles.badge} ${styles.badgePaused}`}>Paused</span>
      )}
    </span>
  );
}

export function LegacyBadge() {
  return <span className={`${styles.badge} ${styles.badgeLegacy}`}>Legacy</span>;
}
