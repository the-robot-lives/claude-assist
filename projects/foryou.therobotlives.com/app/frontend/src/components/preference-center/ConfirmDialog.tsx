"use client";

import { useState, type ReactNode } from "react";
import { Modal } from "./Modal";
import { InlineAlert } from "./InlineAlert";
import styles from "./preference-center.module.css";

/**
 * Confirm dialog for destructive/irreversible actions (unsubscribe, deletion).
 * Runs the async `onConfirm`, surfaces errors in-dialog, and only closes on
 * success.
 */
export function ConfirmDialog({
  title,
  body,
  confirmLabel = "Confirm",
  destructive = false,
  onConfirm,
  onCancel,
}: {
  title: string;
  body: ReactNode;
  confirmLabel?: string;
  destructive?: boolean;
  onConfirm: () => Promise<void>;
  onCancel: () => void;
}) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleConfirm() {
    setBusy(true);
    setError(null);
    try {
      await onConfirm();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Something went wrong");
      setBusy(false);
    }
  }

  return (
    <Modal
      title={title}
      onClose={busy ? () => {} : onCancel}
      footer={
        <>
          <button
            type="button"
            className="sg-btn sg-btn--outline sg-btn--sm"
            onClick={onCancel}
            disabled={busy}
          >
            Cancel
          </button>
          <button
            type="button"
            className={`sg-btn sg-btn--sm ${destructive ? "sg-btn--outline" : "sg-btn--black"}`}
            onClick={handleConfirm}
            disabled={busy}
            style={destructive ? { color: "var(--pc-danger, #b42318)" } : undefined}
          >
            {busy && <span className={styles.spinner} aria-hidden="true" />}{" "}
            {busy ? "Working…" : confirmLabel}
          </button>
        </>
      }
    >
      <div>{body}</div>
      {error && (
        <div style={{ marginTop: "0.75rem" }}>
          <InlineAlert variant="error">{error}</InlineAlert>
        </div>
      )}
    </Modal>
  );
}
