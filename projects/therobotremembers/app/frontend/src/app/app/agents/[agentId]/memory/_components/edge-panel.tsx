"use client";

import { useState } from "react";
import type { MemoryEdge } from "@/lib/api";
import { edgeTypeColor } from "@/lib/memory-viz";

export default function EdgePanel({
  edge,
  sourceLabel,
  targetLabel,
  onApply,
  onClose,
}: {
  edge: MemoryEdge;
  sourceLabel: string;
  targetLabel: string;
  onApply: (weight: number, reason: string) => Promise<void>;
  onClose: () => void;
}) {
  const [weight, setWeight] = useState<number>(edge.weight);
  const [reason, setReason] = useState<string>("");
  const [saving, setSaving] = useState(false);

  async function apply() {
    setSaving(true);
    try {
      await onApply(weight, reason.trim());
    } finally {
      setSaving(false);
    }
  }

  return (
    <aside className="mem-panel">
      <div className="mem-panel__head">
        <h2 className="mem-panel__title">Edge</h2>
        <button className="mem-panel__close" onClick={onClose} aria-label="Close">
          ×
        </button>
      </div>

      <div style={{ marginBottom: "0.5rem" }}>
        <span className="mem-badge">
          <span className="mem-badge__dot" style={{ background: edgeTypeColor(edge.type) }} />
          {edge.type}
        </span>
      </div>

      <p className="mem-panel__summary">
        <strong>{sourceLabel}</strong>
        <span style={{ color: "var(--text-muted)" }}> → </span>
        <strong>{targetLabel}</strong>
      </p>

      <div className="mem-panel__stats">
        <div className="mem-stat">
          <div className="mem-stat__value">{edge.reinforcement_count ?? 0}</div>
          <div className="mem-stat__label">Reinforcements</div>
        </div>
        <div className="mem-stat">
          <div className="mem-stat__value">{edge.weight?.toFixed(2)}</div>
          <div className="mem-stat__label">Current weight</div>
        </div>
      </div>

      <div className="mem-field">
        <label htmlFor="edge-weight">
          Weight: <span className="mem-control__value">{weight.toFixed(2)}</span>
        </label>
        <input
          id="edge-weight"
          type="range"
          min={0}
          max={1}
          step={0.01}
          value={weight}
          onChange={(e) => setWeight(parseFloat(e.target.value))}
        />
      </div>

      {weight < 0.2 && (
        <div className="mem-banner mem-banner--warning" style={{ marginBottom: "0.75rem" }}>
          Weights below 0.20 remove this edge from the graph projection.
        </div>
      )}

      <div className="mem-field">
        <label htmlFor="edge-reason">Reason (audited)</label>
        <input
          id="edge-reason"
          type="text"
          value={reason}
          placeholder="e.g. manual correction"
          onChange={(e) => setReason(e.target.value)}
        />
      </div>

      <div className="mem-panel__actions">
        <button
          className="sg-btn sg-btn--black sg-btn--sm"
          disabled={saving || weight === edge.weight}
          onClick={apply}
        >
          {saving ? "Saving…" : "Apply weight"}
        </button>
      </div>

      <div style={{ marginTop: "0.75rem", fontSize: "0.7rem", wordBreak: "break-all", color: "var(--text-muted)" }}>
        id: {edge.id}
      </div>
    </aside>
  );
}
