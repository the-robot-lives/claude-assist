"use client";

import { useMemo, useState } from "react";
import type { MemoryNode } from "@/lib/api";
import { contentTypeColor } from "@/lib/memory-viz";

type SortKey =
  | "summary"
  | "content_type"
  | "compartment"
  | "salience"
  | "decay_weight"
  | "recall_count";

const COLUMNS: { key: SortKey; label: string; numeric?: boolean }[] = [
  { key: "summary", label: "Summary" },
  { key: "content_type", label: "Type" },
  { key: "compartment", label: "Compartment" },
  { key: "salience", label: "Salience", numeric: true },
  { key: "decay_weight", label: "Decay", numeric: true },
  { key: "recall_count", label: "Recalls", numeric: true },
];

export default function NodeList({
  nodes,
  selectedId,
  onSelect,
}: {
  nodes: MemoryNode[];
  selectedId: string | null;
  onSelect: (id: string) => void;
}) {
  const [sortKey, setSortKey] = useState<SortKey>("salience");
  const [asc, setAsc] = useState(false);

  const sorted = useMemo(() => {
    const copy = [...nodes];
    copy.sort((a, b) => {
      const av = a[sortKey];
      const bv = b[sortKey];
      let cmp: number;
      if (typeof av === "number" && typeof bv === "number") cmp = av - bv;
      else cmp = String(av ?? "").localeCompare(String(bv ?? ""));
      return asc ? cmp : -cmp;
    });
    return copy;
  }, [nodes, sortKey, asc]);

  function toggleSort(key: SortKey) {
    if (key === sortKey) setAsc((v) => !v);
    else {
      setSortKey(key);
      setAsc(false);
    }
  }

  if (nodes.length === 0) {
    return <div className="mem-empty">No memories match the current filters.</div>;
  }

  return (
    <div className="mem-table-wrap">
      <table className="mem-table">
        <thead>
          <tr>
            <th style={{ width: "1.5rem" }} />
            {COLUMNS.map((c) => (
              <th
                key={c.key}
                onClick={() => toggleSort(c.key)}
                title="Click to sort"
              >
                {c.label}
                {sortKey === c.key ? (asc ? " ▲" : " ▼") : ""}
              </th>
            ))}
            <th>Pinned</th>
          </tr>
        </thead>
        <tbody>
          {sorted.map((n) => (
            <tr
              key={n.id}
              aria-selected={n.id === selectedId}
              onClick={() => onSelect(n.id)}
            >
              <td>
                <span
                  className="mem-swatch"
                  style={{ background: contentTypeColor(n.content_type) }}
                />
              </td>
              <td className="mem-table__summary">{n.summary || "—"}</td>
              <td>{n.content_type}</td>
              <td>{n.compartment}</td>
              <td>{n.salience?.toFixed(2)}</td>
              <td>{n.decay_weight?.toFixed(2)}</td>
              <td>{n.recall_count}</td>
              <td>{n.pinned ? "📌" : ""}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
