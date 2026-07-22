"use client";

import type { SignupView } from "./api";
import { StatusBadge } from "./StatusBadge";
import { formatDate, isPaused, prefsSummary } from "./prefs";
import styles from "./preference-center.module.css";

export interface RowHandlers {
  onManage: (s: SignupView) => void;
  onUnsubscribe: (s: SignupView) => void;
  onResubscribe: (s: SignupView) => void;
  onResume: (s: SignupView) => void;
}

export function SubscriptionRow({
  signup,
  handlers,
  busy,
}: {
  signup: SignupView;
  handlers: RowHandlers;
  busy: boolean;
}) {
  const paused = isPaused(signup);
  const listName = signup.list?.name ?? "Subscription";
  const canResubscribe = signup.can_resubscribe !== false;

  return (
    <div className={styles.row}>
      <div className={styles.rowMain}>
        <div className={styles.rowTitle}>
          <span>{listName}</span>
          <StatusBadge status={signup.status} paused={paused} />
        </div>
        <div className={styles.rowMeta}>
          {signup.email} · joined {formatDate(signup.inserted_at)}
        </div>
        {signup.status === "subscribed" && (
          <div className={styles.rowMeta}>{prefsSummary(signup)}</div>
        )}
        {signup.status === "pending_optin" && (
          <div className={styles.rowHint}>
            Check your inbox to confirm this subscription.
          </div>
        )}
      </div>

      <div className={styles.rowActions}>
        {signup.status === "subscribed" && (
          <>
            <button
              type="button"
              className="sg-btn sg-btn--outline sg-btn--sm"
              onClick={() => handlers.onManage(signup)}
              disabled={busy}
            >
              Manage
            </button>
            {paused ? (
              <button
                type="button"
                className="sg-btn sg-btn--black sg-btn--sm"
                onClick={() => handlers.onResume(signup)}
                disabled={busy}
              >
                Resume
              </button>
            ) : (
              <button
                type="button"
                className="sg-btn sg-btn--outline sg-btn--sm"
                onClick={() => handlers.onUnsubscribe(signup)}
                disabled={busy}
              >
                Unsubscribe
              </button>
            )}
          </>
        )}

        {signup.status === "unsubscribed" &&
          (canResubscribe ? (
            <button
              type="button"
              className="sg-btn sg-btn--black sg-btn--sm"
              onClick={() => handlers.onResubscribe(signup)}
              disabled={busy}
            >
              Re-subscribe
            </button>
          ) : (
            <button
              type="button"
              className="sg-btn sg-btn--outline sg-btn--sm"
              disabled
              title="This list is no longer accepting sign-ups."
            >
              Re-subscribe
            </button>
          ))}
      </div>
    </div>
  );
}
