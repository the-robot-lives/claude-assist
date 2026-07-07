"use client";

import { useState } from "react";
import type { MemoryNode } from "@/lib/api";
import { contentTypeColor } from "@/lib/memory-viz";

type Action = "reinforce" | "denforce" | "pin" | null;

export default function NodePanel({
  node,
  onReinforce,
  onDenforce,
  onTogglePin,
  onClose,
}: {
  node: MemoryNode;
  onReinforce: () => Promise<void>;
  onDenforce: () => Promise<void>;
  onTogglePin: () => Promise<void>;
  onClose: () => void;
}) {
  const [pending, setPending] = useState<Action>(null);

  async function run(action: Action, fn: () => Promise<void>) {
    setPending(action);
    try {
      await fn();
    } finally {
      setPending(null);
    }
  }

  const stats: [string, string][] = [
    ["Salience", node.salience?.toFixed(2) ?? "—"],
    ["Decay weight", node.decay_weight?.toFixed(2) ?? "—"],
    ["Recalls", String(node.recall_count ?? 0)],
    ["State", node.state ?? "—"],
    ["Valence", node.valence?.toFixed(2) ?? "—"],
    ["Arousal", node.arousal?.toFixed(2) ?? "—"],
  ];

  return (
    <aside className="mem-panel">
      <div className="mem-panel__head">
        <h2 className="mem-panel__title">Memory</h2>
        <button className="mem-panel__close" onClick={onClose} aria-label="Close">
          ×
        </button>
      </div>

      <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap", marginBottom: "0.5rem" }}>
        <span className="mem-badge">
          <span className="mem-badge__dot" style={{ background: contentTypeColor(node.content_type) }} />
          {node.content_type}
        </span>
        <span className="mem-badge">{node.compartment}</span>
        {node.pinned && <span className="mem-badge mem-badge--pinned">📌 pinned</span>}
      </div>

      <p className="mem-panel__summary">{node.summary || "No summary."}</p>

      <div className="mem-panel__stats">
        {stats.map(([label, value]) => (
          <div className="mem-stat" key={label}>
            <div className="mem-stat__value">{value}</div>
            <div className="mem-stat__label">{label}</div>
          </div>
        ))}
      </div>

      <div className="mem-panel__actions">
        <button
          className="sg-btn sg-btn--outline sg-btn--sm"
          disabled={pending !== null}
          onClick={() => run("reinforce", onReinforce)}
        >
          {pending === "reinforce" ? "…" : "Reinforce"}
        </button>
        <button
          className="sg-btn sg-btn--outline sg-btn--sm"
          disabled={pending !== null}
          onClick={() => run("denforce", onDenforce)}
        >
          {pending === "denforce" ? "…" : "Denforce"}
        </button>
        <button
          className="sg-btn sg-btn--black sg-btn--sm"
          disabled={pending !== null}
          onClick={() => run("pin", onTogglePin)}
        >
          {pending === "pin" ? "…" : node.pinned ? "Unpin" : "Pin"}
        </button>
      </div>

      <div style={{ marginTop: "0.75rem", fontSize: "0.7rem", wordBreak: "break-all", color: "var(--text-muted)" }}>
        id: {node.id}
      </div>
    </aside>
  );
}
