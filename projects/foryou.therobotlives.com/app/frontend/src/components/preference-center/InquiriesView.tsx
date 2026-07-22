"use client";

import Link from "next/link";
import { InquiryList } from "./InquiryList";
import { PrivacySection } from "./PrivacySection";
import { InlineAlert } from "./InlineAlert";
import { usePreferenceData } from "./usePreferenceData";
import styles from "./preference-center.module.css";

/** Focused inquiries + privacy surface for /app/me/inquiries (SCR-16). */
export function InquiriesView() {
  const { inquiries, reloadInquiries } = usePreferenceData();

  return (
    <div className={styles.page}>
      <header className={styles.header}>
        <Link href="/app/me" className={styles.muted}>
          ← Back to my preferences
        </Link>
        <h1 className="sg-page-title" style={{ marginTop: "0.5rem" }}>
          My inquiries
        </h1>
        <p className={styles.subtitle}>
          Questions and contact requests you’ve submitted across the portfolio.
        </p>
      </header>

      <section className={styles.section}>
        {inquiries.loading ? (
          <div className={styles.skeleton} aria-hidden="true">
            <div className={styles.skelRow} />
            <div className={styles.skelRow} />
          </div>
        ) : inquiries.error ? (
          <InlineAlert variant="error" onRetry={reloadInquiries}>
            {inquiries.error}
          </InlineAlert>
        ) : (
          <InquiryList inquiries={inquiries.data} />
        )}
      </section>

      <section className={styles.section}>
        <PrivacySection />
      </section>
    </div>
  );
}
