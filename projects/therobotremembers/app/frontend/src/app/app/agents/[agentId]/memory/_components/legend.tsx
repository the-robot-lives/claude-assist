"use client";

import type { MemoryNode, MemoryEdge } from "@/lib/api";
import { contentTypeColor, edgeTypeColor } from "@/lib/memory-viz";

export default function Legend({
  nodes,
  edges,
}: {
  nodes: MemoryNode[];
  edges: MemoryEdge[];
}) {
  const contentTypes = Array.from(new Set(nodes.map((n) => n.content_type))).sort();
  const edgeTypes = Array.from(new Set(edges.map((e) => e.type))).sort();

  if (contentTypes.length === 0 && edgeTypes.length === 0) return null;

  return (
    <div className="mem-legend">
      {contentTypes.map((t) => (
        <span key={`n-${t}`} className="mem-legend-item">
          <span className="mem-swatch" style={{ background: contentTypeColor(t) }} />
          {t}
        </span>
      ))}
      {edgeTypes.map((t) => (
        <span key={`e-${t}`} className="mem-legend-item">
          <span
            className="mem-swatch"
            style={{ background: edgeTypeColor(t), height: "0.28em" }}
          />
          {t} edge
        </span>
      ))}
    </div>
  );
}
