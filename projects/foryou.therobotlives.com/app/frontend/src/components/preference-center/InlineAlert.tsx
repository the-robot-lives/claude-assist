"use client";

import type { ReactNode } from "react";
import styles from "./preference-center.module.css";

type Variant = "info" | "error" | "success";

const VARIANT_CLASS: Record<Variant, string> = {
  info: styles.alertInfo,
  error: styles.alertError,
  success: styles.alertSuccess,
};

/**
 * Text-first alert (never color alone — FR-012). Errors use role="alert" so
 * assistive tech announces them; info/success are polite.
 */
export function InlineAlert({
  variant = "info",
  children,
  onRetry,
  onDismiss,
}: {
  variant?: Variant;
  children: ReactNode;
  onRetry?: () => void;
  onDismiss?: () => void;
}) {
  const prefix =
    variant === "error"
      ? "Error: "
      : variant === "success"
        ? "Done: "
        : "";
  return (
    <div
      className={`${styles.alert} ${VARIANT_CLASS[variant]}`}
      role={variant === "error" ? "alert" : "status"}
    >
      <span>
        {prefix}
        {children}
      </span>
      {(onRetry || onDismiss) && (
        <span className={styles.alertActions}>
          {onRetry && (
            <button
              type="button"
              className="sg-btn sg-btn--outline sg-btn--sm"
              onClick={onRetry}
            >
              Retry
            </button>
          )}
          {onDismiss && (
            <button
              type="button"
              className="sg-btn sg-btn--outline sg-btn--sm"
              onClick={onDismiss}
            >
              Dismiss
            </button>
          )}
        </span>
      )}
    </div>
  );
}
