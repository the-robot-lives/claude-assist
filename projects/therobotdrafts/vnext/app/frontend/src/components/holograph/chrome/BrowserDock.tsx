"use client";

import { type RefObject, useMemo, useState } from "react";
import "./docks.css";
import type { GraphDocument, GraphNode, NodeKind } from "@/lib/holograph/types";

export type BrowserTab = "files" | "outline" | "recents";

export interface DocumentSummary {
  id: string;
  slug: string;
  title: string;
  version: number;
  nodeCount: number;
  edgeCount: number;
}

export interface RecentEntry {
  id: string;
  slug: string;
  title: string;
  nodeCount: number;
  savedAt: string;
}

export interface BrowserDockProps {
  collapsed: boolean;
  tab: BrowserTab;
  onTabChange: (tab: BrowserTab) => void;
  document: GraphDocument;
  selectedId: string | null;
  onSelectNode: (id: string) => void;
  documents: DocumentSummary[];
  onOpenDocument: (id: string) => void;
  /** Spec §5A: the Outline tab supports click-to-frame — bound to double-click so a
   * single click keeps its plain "select" meaning. */
  onFrameNode: (id: string) => void;
  recents: RecentEntry[];
  onOpenRecent: (index: number) => void;
  query: string;
  onQueryChange: (value: string) => void;
  matchingNodes: GraphNode[];
  filterRef: RefObject<HTMLInputElement | null>;
}

/** Spec §5A: 3-letter kind badges, so the column aligns. */
const KIND_BADGE: Record<NodeKind, string> = {
  system: "sys",
  package: "pkg",
  service: "svc",
  class: "cls",
  interface: "ifc",
  function: "fun",
  database: "dbs",
  agent: "agt",
};

const WARM_KINDS = new Set<NodeKind>(["database", "agent"]);

const TABS: Array<{ value: BrowserTab; label: string }> = [
  { value: "files", label: "Files" },
  { value: "outline", label: "Outline" },
  { value: "recents", label: "Recents" },
];

export function BrowserDock({
  collapsed,
  tab,
  onTabChange,
  document,
  selectedId,
  onSelectNode,
  documents,
  onOpenDocument,
  onFrameNode,
  recents,
  onOpenRecent,
  query,
  onQueryChange,
  matchingNodes,
  filterRef,
}: BrowserDockProps) {
  // Files tab: the open model expands into its container nodes, sibling models stay collapsed.
  const containers = useMemo(
    () => document.nodes.filter((node) => node.kind === "package" || node.kind === "system"),
    [document.nodes],
  );
  const childrenByParent = useMemo(() => {
    const map = new Map<string, GraphNode[]>();
    for (const node of document.nodes) {
      if (!node.parentId) continue;
      const bucket = map.get(node.parentId);
      if (bucket) bucket.push(node);
      else map.set(node.parentId, [node]);
    }
    return map;
  }, [document.nodes]);

  const otherDocuments = documents.filter((entry) => entry.id !== document.id);

  // Disclosure is local: it is view state with no meaning outside this dock, and the
  // spec's ▾/▸ triangles are live toggles (BrowseNavPanel.cs behaves the same way).
  // Collapsed-by-default would hide the open model on first paint, so the root and its
  // containers start expanded and `collapsedIds` records what the user has shut.
  const [collapsedIds, setCollapsedIds] = useState<ReadonlySet<string>>(new Set());
  const isExpanded = (id: string) => !collapsedIds.has(id);
  const toggleExpanded = (id: string) =>
    setCollapsedIds((current) => {
      const next = new Set(current);
      if (!next.delete(id)) next.add(id);
      return next;
    });

  const rootExpanded = isExpanded(document.id);

  return (
    <aside
      className={collapsed ? "trd-browser is-collapsed" : "trd-browser"}
      aria-label="Model browser"
      inert={collapsed}
    >
      <div className="trd-tabs" role="tablist" aria-label="Model browser tabs">
        {TABS.map((entry) => (
          <button
            key={entry.value}
            type="button"
            role="tab"
            aria-selected={tab === entry.value}
            className={tab === entry.value ? "trd-tab is-active" : "trd-tab"}
            onClick={() => onTabChange(entry.value)}
          >
            {entry.label}
          </button>
        ))}
      </div>

      {tab === "files" ? (
        <div className="trd-pane" role="tabpanel" aria-label="Files">
          <button
            type="button"
            className="trd-tree-row is-selected"
            aria-expanded={rootExpanded}
            onClick={() => toggleExpanded(document.id)}
          >
            {rootExpanded ? "▾" : "▸"} {document.slug}
          </button>
          {rootExpanded && containers.length === 0 ? (
            <p className="trd-empty-note">No packages in this model.</p>
          ) : null}
          {rootExpanded
            ? containers.map((container) => {
                const open = isExpanded(container.id);
                return (
                  <div key={container.id}>
                    <button
                      type="button"
                      className={
                        container.id === selectedId ? "trd-tree-row lvl1 is-selected" : "trd-tree-row lvl1"
                      }
                      aria-expanded={open}
                      title={`${container.label} — click to select and expand, double-click to frame`}
                      // A container row does both jobs: selecting it and opening it are
                      // the same intent, and both are non-destructive.
                      onClick={() => {
                        onSelectNode(container.id);
                        toggleExpanded(container.id);
                      }}
                      onDoubleClick={() => onFrameNode(container.id)}
                    >
                      {open ? "▾" : "▸"} {container.label}
                    </button>
                    {open
                      ? (childrenByParent.get(container.id) ?? []).map((child) => (
                          <button
                            key={child.id}
                            type="button"
                            className={
                              child.id === selectedId ? "trd-tree-row lvl2 is-selected" : "trd-tree-row lvl2"
                            }
                            onClick={() => onSelectNode(child.id)}
                            onDoubleClick={() => onFrameNode(child.id)}
                          >
                            {child.label}
                          </button>
                        ))
                      : null}
                  </div>
                );
              })
            : null}
          {otherDocuments.length ? <h4>Other models</h4> : null}
          {otherDocuments.map((entry) => (
            <button
              key={entry.id}
              type="button"
              className="trd-tree-row"
              // Expanding a model that is not loaded means loading it, so the ▸ row's
              // disclosure and its open action are the same click.
              aria-expanded={false}
              title={`${entry.title} — ${entry.nodeCount} elements. Opens this model.`}
              onClick={() => onOpenDocument(entry.id)}
            >
              ▸ {entry.slug}
            </button>
          ))}
        </div>
      ) : null}

      {tab === "outline" ? (
        <div className="trd-pane" role="tabpanel" aria-label="Outline">
          <input
            ref={filterRef}
            className="trd-filter"
            placeholder="Filter elements…"
            aria-label="Filter elements"
            value={query}
            onChange={(event) => onQueryChange(event.target.value)}
          />
          <h4>This model</h4>
          {matchingNodes.length === 0 ? (
            <p className="trd-empty-note">{document.nodes.length ? "No matches." : "Model is empty."}</p>
          ) : (
            matchingNodes.map((node) => (
              <button
                key={node.id}
                type="button"
                className={node.id === selectedId ? "trd-tree-row is-selected" : "trd-tree-row"}
                title={`${node.label} — double-click to frame`}
                onClick={() => onSelectNode(node.id)}
                onDoubleClick={() => onFrameNode(node.id)}
              >
                <span className={WARM_KINDS.has(node.kind) ? "trd-badge is-warm" : "trd-badge"}>
                  {KIND_BADGE[node.kind]}
                </span>
                {node.label}
              </button>
            ))
          )}
          <h4>Kinds</h4>
          <p className="trd-empty-note">Class · Interface · Package · Service · System · Datastore · Agent · Function</p>
        </div>
      ) : null}

      {tab === "recents" ? (
        <div className="trd-pane" role="tabpanel" aria-label="Recents">
          {recents.length === 0 ? (
            <p className="trd-empty-note">No recent models yet.</p>
          ) : (
            recents.map((entry, index) => (
              <button
                key={`${entry.id}:${entry.savedAt}`}
                type="button"
                className="trd-tree-row"
                title={`${entry.title} — opened ${entry.savedAt}`}
                onClick={() => onOpenRecent(index)}
              >
                <span className="trd-badge">{entry.nodeCount}</span>
                {entry.slug}
              </button>
            ))
          )}
        </div>
      ) : null}
    </aside>
  );
}
