"use client";

import { useEffect } from "react";
import { SignupStatusBadge } from "./ui";
import type { AdminSignup } from "./admin-fetch";

function formatValue(v: unknown): string {
  if (v === null || v === undefined || v === "") return "—";
  if (Array.isArray(v)) return v.join(", ");
  if (typeof v === "object") return JSON.stringify(v);
  return String(v);
}

function formatDate(iso?: string): string {
  if (!iso) return "—";
  const d = new Date(iso);
  return isNaN(d.getTime()) ? iso : d.toLocaleString();
}

/**
 * Slide-over detail for a single signup. Renders from row data already loaded
 * (the shipped backend has no single-signup / history endpoint, so there is no
 * extra fetch — status history is deferred per PRD FR-009).
 */
export function SignupDetailPanel({
  signup,
  attributeKeys,
  onClose,
}: {
  signup: AdminSignup;
  attributeKeys: string[];
  onClose: () => void;
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  // Attribute keys that carry values on this row but weren't in the table union.
  const extraKeys = Object.keys(signup.attribs ?? {}).filter(
    (k) => k !== "listmonk" && !attributeKeys.includes(k)
  );
  const allAttrKeys = [...attributeKeys, ...extraKeys];

  return (
    <>
      <div className="sg-detail-overlay" onClick={onClose} aria-hidden="true" />
      <aside className="sg-detail-panel" role="dialog" aria-modal="true" aria-label="Signup detail">
        <div className="sg-detail-panel__header">
          <h2 className="sg-detail-panel__title">{signup.email}</h2>
          <button className="sg-detail-panel__close" onClick={onClose} aria-label="Close detail">
            &times;
          </button>
        </div>

        <dl className="sg-detail-list">
          <dt>Status</dt>
          <dd>
            <SignupStatusBadge status={signup.status} />
          </dd>
          <dt>Source</dt>
          <dd>{formatValue(signup.source)}</dd>
          <dt>Created</dt>
          <dd>{formatDate(signup.inserted_at)}</dd>
          <dt>Account</dt>
          <dd>{signup.user_id ? signup.user_id : "Not linked to an account"}</dd>
          <dt>Signup ID</dt>
          <dd>{signup.id}</dd>
        </dl>

        {allAttrKeys.length > 0 ? (
          <>
            <p className="sg-detail-section-title">Attributes</p>
            <dl className="sg-detail-list">
              {allAttrKeys.map((k) => (
                <div key={k} style={{ display: "contents" }}>
                  <dt>{k}</dt>
                  <dd>{formatValue(signup.attribs?.[k])}</dd>
                </div>
              ))}
            </dl>
          </>
        ) : null}
      </aside>
    </>
  );
}
