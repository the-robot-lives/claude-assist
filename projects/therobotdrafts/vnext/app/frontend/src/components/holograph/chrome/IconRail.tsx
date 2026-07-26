"use client";

import "./docks.css";

export interface IconRailProps {
  browserOpen: boolean;
  onToggleBrowser: () => void;
  onSearch: () => void;
  onAddElement: () => void;
  onImportExport: () => void;
}

export function IconRail({
  browserOpen,
  onToggleBrowser,
  onSearch,
  onAddElement,
  onImportExport,
}: IconRailProps) {
  return (
    <div className="trd-rail" role="toolbar" aria-label="Workspace rail">
      <button
        type="button"
        className={browserOpen ? "trd-icon-btn is-active" : "trd-icon-btn"}
        title="Model Browser"
        aria-label="Model Browser"
        onClick={onToggleBrowser}
      >
        ▤
      </button>
      <button type="button" className="trd-icon-btn" title="Search (⌘F)" aria-label="Search" onClick={onSearch}>
        ⌕
      </button>
      <button type="button" className="trd-icon-btn" title="Add Element" aria-label="Add Element" onClick={onAddElement}>
        ＋
      </button>
      <button
        type="button"
        className="trd-icon-btn"
        title="Aspects — not available in this build"
        aria-label="Aspects"
        disabled
      >
        ◈
      </button>
      <button
        type="button"
        className="trd-icon-btn"
        title="Import / Export"
        aria-label="Import and Export"
        onClick={onImportExport}
      >
        ⇅
      </button>
    </div>
  );
}
