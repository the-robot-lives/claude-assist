"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { pcApi, PcApiError, type SignupView } from "./api";
import { isPaused } from "./prefs";
import { SubscriptionList } from "./SubscriptionList";
import { InquiryList } from "./InquiryList";
import { PreferenceEditor } from "./PreferenceEditor";
import { PrivacySection } from "./PrivacySection";
import { ConfirmDialog } from "./ConfirmDialog";
import { InlineAlert } from "./InlineAlert";
import { EmptyState } from "./EmptyState";
import { useAnnounce } from "./Announcer";
import { usePreferenceData } from "./usePreferenceData";
import type { RowHandlers } from "./SubscriptionRow";
import styles from "./preference-center.module.css";

function SkeletonList() {
  return (
    <div className={styles.skeleton} aria-hidden="true">
      <div className={styles.skelRow} />
      <div className={styles.skelRow} />
      <div className={styles.skelRow} />
    </div>
  );
}

function SummaryCards({ signups }: { signups: SignupView[] }) {
  const active = signups.filter((s) => s.status === "subscribed").length;
  const services = new Set(
    signups.map(
      (s) => s.service?.id || s.service?.slug || s.source || s.list?.public_slug,
    ),
  ).size;
  const paused = signups.filter(isPaused).length;
  return (
    <div className={styles.summaryRow}>
      <div className={styles.card}>
        <div className={styles.cardValue}>{active}</div>
        <div className={styles.cardLabel}>Active subscriptions</div>
      </div>
      <div className={styles.card}>
        <div className={styles.cardValue}>{services || 0}</div>
        <div className={styles.cardLabel}>Sites</div>
      </div>
      {paused > 0 && (
        <div className={styles.card}>
          <div className={styles.cardValue}>{paused}</div>
          <div className={styles.cardLabel}>Paused</div>
        </div>
      )}
    </div>
  );
}

export function PreferenceCenter() {
  const announce = useAnnounce();
  const {
    signups,
    inquiries,
    reloadSignups,
    reloadInquiries,
    patchSignup,
    removeSignup,
  } = usePreferenceData();

  const [editing, setEditing] = useState<SignupView | null>(null);
  const [unsubTarget, setUnsubTarget] = useState<SignupView | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  async function confirmUnsubscribe() {
    if (!unsubTarget) return;
    const id = unsubTarget.id;
    try {
      await pcApi.unsubscribeMySignup(id);
      patchSignup(id, { status: "unsubscribed" });
      announce(`Unsubscribed from ${unsubTarget.list?.name ?? "the list"}.`);
      setUnsubTarget(null);
    } catch (e) {
      if (e instanceof PcApiError && e.status === 404) {
        removeSignup(id);
        announce("That subscription was already removed.");
        setUnsubTarget(null);
        return;
      }
      throw e; // ConfirmDialog surfaces the message and stays open
    }
  }

  async function resubscribe(s: SignupView) {
    setBusyId(s.id);
    setActionError(null);
    try {
      const { signup } = await pcApi.resubscribeMySignup(s.id);
      patchSignup(s.id, signup ?? { status: "pending_optin" });
      announce(`Re-subscribe requested for ${s.list?.name ?? "the list"}.`);
    } catch (e) {
      const msg = describeAction(e, "re-subscribe");
      setActionError(msg);
      announce(msg);
    } finally {
      setBusyId(null);
    }
  }

  async function resume(s: SignupView) {
    setBusyId(s.id);
    setActionError(null);
    try {
      const { signup } = await pcApi.resumeMySignup(s.id);
      patchSignup(s.id, signup ?? { pause_until: null });
      announce(`Contact resumed for ${s.list?.name ?? "the list"}.`);
    } catch (e) {
      const msg = describeAction(e, "resume");
      setActionError(msg);
      announce(msg);
    } finally {
      setBusyId(null);
    }
  }

  const handlers: RowHandlers = {
    onManage: setEditing,
    onUnsubscribe: setUnsubTarget,
    onResubscribe: resubscribe,
    onResume: resume,
  };

  const nothingAtAll =
    !signups.loading &&
    !inquiries.loading &&
    signups.data.length === 0 &&
    inquiries.data.length === 0 &&
    !signups.error &&
    !inquiries.error;

  const inquiriesPreview = useMemo(
    () => inquiries.data.slice(0, 5),
    [inquiries.data],
  );

  return (
    <div className={styles.page}>
      <header className={styles.header}>
        <h1 className="sg-page-title">My preferences</h1>
        <p className={styles.subtitle}>
          Everything you’ve subscribed to across the DeRobot portfolio, in one
          place.
        </p>
      </header>

      {nothingAtAll ? (
        <EmptyState
          title="Nothing here yet"
          action={
            <Link href="/" className="sg-btn sg-btn--black sg-btn--sm">
              Explore the sites
            </Link>
          }
        >
          Your subscriptions and inquiries will appear here after you sign up or
          get in touch on any DeRobot site.
        </EmptyState>
      ) : (
        <>
          {!signups.loading && !signups.error && (
            <SummaryCards signups={signups.data} />
          )}

          {/* Subscriptions ------------------------------------------------ */}
          <section className={styles.section} aria-labelledby="pc-subs-heading">
            <h2 id="pc-subs-heading" className="sg-section-heading">
              Subscriptions
            </h2>
            {actionError && (
              <InlineAlert
                variant="error"
                onDismiss={() => setActionError(null)}
              >
                {actionError}
              </InlineAlert>
            )}
            {signups.loading ? (
              <SkeletonList />
            ) : signups.error ? (
              <InlineAlert variant="error" onRetry={reloadSignups}>
                {signups.error}
              </InlineAlert>
            ) : (
              <SubscriptionList
                signups={signups.data}
                handlers={handlers}
                busyId={busyId}
              />
            )}
          </section>

          {/* Inquiries --------------------------------------------------- */}
          <section
            className={styles.section}
            aria-labelledby="pc-inq-heading"
          >
            <div
              style={{
                display: "flex",
                alignItems: "baseline",
                justifyContent: "space-between",
                gap: "0.5rem",
              }}
            >
              <h2 id="pc-inq-heading" className="sg-section-heading">
                Inquiries
              </h2>
              {inquiries.data.length > inquiriesPreview.length && (
                <Link href="/app/me/inquiries" className={styles.muted}>
                  View all ({inquiries.data.length})
                </Link>
              )}
            </div>
            {inquiries.loading ? (
              <SkeletonList />
            ) : inquiries.error ? (
              <InlineAlert variant="error" onRetry={reloadInquiries}>
                {inquiries.error}
              </InlineAlert>
            ) : (
              <InquiryList inquiries={inquiriesPreview} />
            )}
          </section>

          {/* Privacy ----------------------------------------------------- */}
          <section className={styles.section}>
            <PrivacySection />
          </section>
        </>
      )}

      {editing && (
        <PreferenceEditor
          signup={editing}
          onClose={() => setEditing(null)}
          onSaved={(updated) => {
            patchSignup(updated.id, updated);
            setEditing(null);
          }}
        />
      )}

      {unsubTarget && (
        <ConfirmDialog
          title="Unsubscribe?"
          destructive
          confirmLabel="Unsubscribe"
          onCancel={() => setUnsubTarget(null)}
          onConfirm={confirmUnsubscribe}
          body={
            <p style={{ margin: 0 }}>
              You’ll stop receiving messages from{" "}
              <strong>{unsubTarget.list?.name ?? "this list"}</strong>. You can
              re-subscribe here later.
            </p>
          }
        />
      )}
    </div>
  );
}

function describeAction(e: unknown, verb: string): string {
  if (e instanceof PcApiError) {
    if (e.status === 409) return "This list is no longer available.";
    if (e.status === 404) return "This subscription is no longer available.";
    if (e.status === 405 || e.status === 501)
      return `Can’t ${verb} yet — the backend endpoint is still being finished.`;
  }
  return e instanceof Error ? e.message : `Could not ${verb}.`;
}
