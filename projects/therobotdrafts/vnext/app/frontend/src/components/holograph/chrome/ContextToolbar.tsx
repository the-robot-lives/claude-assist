"use client";

import { RELATIONSHIP_LABELS } from "./menu-data";
import type { UmlRelationship } from "@/lib/holograph/document-io";

export type ToolMode = "select" | "connect" | "place";

export interface BreadcrumbSegment {
  label: string;
  onClick?: () => void;
}

export interface ContextToolbarProps {
  browserCollapsed: boolean;
  onToggleBrowser: () => void;
  modelName: string;
  crumbs: BreadcrumbSegment[];
  mode: ToolMode;
  onModeChange: (mode: ToolMode) => void;
  relationshipType: UmlRelationship;
  onRelationshipChange: (value: UmlRelationship) => void;
  onCameraControls: () => void;
  onStartTrace: () => void;
  onCommandPalette: () => void;
  traceActive: boolean;
}

const MODES: Array<{ value: ToolMode; label: string }> = [
  { value: "select", label: "Select" },
  { value: "connect", label: "Connect" },
  { value: "place", label: "Place" },
];

export function ContextToolbar({
  browserCollapsed,
  onToggleBrowser,
  modelName,
  crumbs,
  mode,
  onModeChange,
  relationshipType,
  onRelationshipChange,
  onCameraControls,
  onStartTrace,
  onCommandPalette,
  traceActive,
}: ContextToolbarProps) {
  return (
    <div className="trd-ctxbar">
      <div className="trd-ctx-left">
        <button
          type="button"
          className="trd-icon-btn"
          id="trd-collapse-browser"
          title="Toggle Model Browser (⌥⌘1)"
          aria-label="Toggle Model Browser"
          onClick={onToggleBrowser}
        >
          {browserCollapsed ? "⟩" : "⟨"}
        </button>
        <span className="trd-crumb" aria-label="Model breadcrumb">
          <b>{modelName}</b>
          {crumbs.map((segment) => (
            <span key={segment.label}>
              <span className="trd-crumb-sep">▸</span>
              {segment.onClick ? (
                <button type="button" onClick={segment.onClick}>
                  {segment.label}
                </button>
              ) : (
                segment.label
              )}
            </span>
          ))}
        </span>
      </div>

      <div className="trd-ctx-center">
        <div className="trd-modes" role="group" aria-label="Tool mode">
          {MODES.map((entry) => (
            <button
              key={entry.value}
              type="button"
              className={mode === entry.value ? "trd-mode-btn is-active" : "trd-mode-btn"}
              aria-pressed={mode === entry.value}
              onClick={() => onModeChange(entry.value)}
            >
              {entry.label}
            </button>
          ))}
        </div>
        <div className={mode === "connect" ? "trd-rel-wrap is-open" : "trd-rel-wrap"}>
          <select
            className="trd-select"
            aria-label="Relationship type"
            value={relationshipType}
            onChange={(event) => onRelationshipChange(event.target.value as UmlRelationship)}
          >
            {(Object.keys(RELATIONSHIP_LABELS) as UmlRelationship[]).map((kind) => (
              <option key={kind} value={kind}>
                {RELATIONSHIP_LABELS[kind]}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="trd-ctx-right">
        <select className="trd-select" title="Layout algorithm — no layout engine in this build" disabled defaultValue="cluster">
          <option value="cluster">Cluster</option>
          <option value="hierarchy">Hierarchy</option>
          <option value="force">Force</option>
          <option value="grid">Grid</option>
          <option value="ai">AI Layout…</option>
        </select>
        <button type="button" className="trd-icon-btn" title="Camera Controls (⇧⌘C)" onClick={onCameraControls}>
          🎥
        </button>
        <button type="button" className="trd-icon-btn" title="Viewport Snapshot — not available in this build" disabled>
          📷
        </button>
        <button
          type="button"
          className={traceActive ? "trd-icon-btn is-active" : "trd-icon-btn"}
          title="Start Trace Here (⌘T)"
          onClick={onStartTrace}
        >
          ⟠
        </button>
        <button type="button" className="trd-icon-btn" title="Command Palette (⌘K)" onClick={onCommandPalette}>
          ⌘K
        </button>
      </div>
    </div>
  );
}
