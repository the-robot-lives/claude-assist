"use client";

import { useState } from "react";
import { pcApi, PcApiError } from "./api";
import { InlineAlert } from "./InlineAlert";
import { ConfirmDialog } from "./ConfirmDialog";
import { useAnnounce } from "./Announcer";
import styles from "./preference-center.module.css";

/**
 * Export-my-data (FR-009) + request-deletion (FR-010). Deletion is an honest
 * "queued" stub per D11. Export downloads the JSON the endpoint returns.
 */
export function PrivacySection() {
  const announce = useAnnounce();
  const [exporting, setExporting] = useState(false);
  const [exportError, setExportError] = useState<string | null>(null);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deletionState, setDeletionState] = useState<
    "idle" | "queued" | "error"
  >("idle");
  const [deletionError, setDeletionError] = useState<string | null>(null);

  async function handleExport() {
    setExporting(true);
    setExportError(null);
    try {
      const data = await pcApi.exportMyData();
      const blob = new Blob([JSON.stringify(data, null, 2)], {
        type: "application/json",
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `foryou-export-${new Date().toISOString().slice(0, 10)}.json`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
      announce("Your data export has downloaded.");
    } catch (e) {
      setExportError(describe(e, "export"));
    } finally {
      setExporting(false);
    }
  }

  async function handleDeletion() {
    try {
      await pcApi.requestDeletion();
      setDeletionState("queued");
      announce("Your deletion request has been queued.");
    } catch (e) {
      setDeletionState("error");
      setDeletionError(describe(e, "deletion"));
      throw e; // keep the confirm dialog open on failure
    } finally {
      setConfirmDelete(false);
    }
  }

  return (
    <div className={styles.card}>
      <h3 style={{ margin: "0 0 0.25rem", fontSize: "1rem" }}>
        Privacy &amp; your data
      </h3>
      <p className={styles.muted} style={{ marginTop: 0, fontSize: "0.85rem" }}>
        Download everything we hold for your account, or request that it be
        removed.
      </p>

      <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap" }}>
        <button
          type="button"
          className="sg-btn sg-btn--outline sg-btn--sm"
          onClick={handleExport}
          disabled={exporting}
        >
          {exporting && <span className={styles.spinner} aria-hidden="true" />}{" "}
          {exporting ? "Preparing…" : "Export my data"}
        </button>
        <button
          type="button"
          className="sg-btn sg-btn--outline sg-btn--sm"
          onClick={() => setConfirmDelete(true)}
          disabled={deletionState === "queued"}
          style={{ color: "var(--pc-danger, #b42318)" }}
        >
          Request account deletion
        </button>
      </div>

      {exportError && (
        <div style={{ marginTop: "0.6rem" }}>
          <InlineAlert variant="error" onDismiss={() => setExportError(null)}>
            {exportError}
          </InlineAlert>
        </div>
      )}

      {deletionState === "queued" && (
        <div style={{ marginTop: "0.6rem" }}>
          <InlineAlert variant="success">
            Your deletion request is queued. We’ll process it per our data
            policy; some records may be retained where legally required. You’ll
            be contacted at your account email.
          </InlineAlert>
        </div>
      )}
      {deletionState === "error" && deletionError && (
        <div style={{ marginTop: "0.6rem" }}>
          <InlineAlert variant="error" onDismiss={() => setDeletionState("idle")}>
            {deletionError}
          </InlineAlert>
        </div>
      )}

      {confirmDelete && (
        <ConfirmDialog
          title="Request account deletion?"
          destructive
          confirmLabel="Request deletion"
          onCancel={() => setConfirmDelete(false)}
          onConfirm={handleDeletion}
          body={
            <div className={styles.stack}>
              <p style={{ margin: 0 }}>
                This queues a request to erase or anonymize your subscriptions,
                contact preferences, and inquiries across the DeRobot portfolio.
              </p>
              <p style={{ margin: 0 }} className={styles.muted}>
                It isn’t instant, and some records may be retained where the law
                requires. We’ll confirm by email.
              </p>
            </div>
          }
        />
      )}
    </div>
  );
}

function describe(e: unknown, kind: "export" | "deletion"): string {
  if (e instanceof PcApiError) {
    if (e.status === 429)
      return "Too many requests — please try again shortly.";
    if (e.status === 405 || e.status === 501 || e.status === 404)
      return `The ${kind} endpoint isn’t available yet — it’s still being finished on the backend.`;
  }
  return e instanceof Error ? e.message : `Could not complete ${kind}.`;
}
