"use client";

import type { InquiryView } from "./api";
import { StatusBadge, LegacyBadge } from "./StatusBadge";
import { EmptyState } from "./EmptyState";
import { formatDate, humanize } from "./prefs";
import styles from "./preference-center.module.css";

function summaryText(inq: InquiryView): string {
  const raw =
    inq.message ||
    (typeof inq.attribs?.message === "string"
      ? (inq.attribs.message as string)
      : "") ||
    (typeof inq.attribs?.body === "string" ? (inq.attribs.body as string) : "");
  return raw.trim();
}

function truncate(s: string, n = 140): string {
  return s.length > n ? `${s.slice(0, n - 1)}…` : s;
}

function siteLabel(inq: InquiryView): string {
  if (inq.source === "legacy") {
    return inq.legacy_source ? humanize(inq.legacy_source) : "Legacy";
  }
  if (inq.list?.name) return inq.list.name;
  if (inq.source) return humanize(inq.source);
  return "Other";
}

export function InquiryList({ inquiries }: { inquiries: InquiryView[] }) {
  if (inquiries.length === 0) {
    return (
      <EmptyState title="No inquiries">
        Questions and contact requests you submit on DeRobot sites will show up
        here.
      </EmptyState>
    );
  }

  return (
    <div className={styles.group}>
      {inquiries.map((inq) => {
        const summary = summaryText(inq);
        const legacy = inq.source === "legacy";
        return (
          <div key={`${legacy ? "legacy-" : ""}${inq.id}`} className={styles.row}>
            <div className={styles.rowMain}>
              <div className={styles.rowTitle}>
                <span>{siteLabel(inq)}</span>
                {legacy ? (
                  <LegacyBadge />
                ) : inq.status ? (
                  <StatusBadge status={inq.status} />
                ) : null}
              </div>
              <div className={styles.rowMeta}>
                {inq.email ? `${inq.email} · ` : ""}
                {formatDate(inq.inserted_at)}
              </div>
              {summary && (
                <div className={styles.rowHint} title={summary}>
                  {truncate(summary)}
                </div>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}
