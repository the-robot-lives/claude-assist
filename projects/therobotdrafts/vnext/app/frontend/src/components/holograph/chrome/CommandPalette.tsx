"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import "./command-palette.css";

export interface PaletteCommand {
  /** Stable id handed back to `onRun`. */
  id: string;
  /** Menu the command lives under, e.g. "File" — rendered dim before the label. */
  category: string;
  label: string;
  /** Display-only shortcut hint, e.g. "⇧⌘N". */
  kbd?: string;
}

export interface CommandPaletteProps {
  open: boolean;
  commands: PaletteCommand[];
  onRun: (id: string) => void;
  onClose: () => void;
  /** Defaults to the demo's "Type a command…". */
  placeholder?: string;
  /** Shown when the filter matches nothing. */
  emptyLabel?: string;
  /** Extra class on the scrim, for shell-level hooks. */
  className?: string;
}

/** Plain case-insensitive substring match over "<category> <label>".
 *  Both the demo JS and the C# `Refresh()` do `.includes()`, not weighted fuzzy
 *  scoring, despite IA.md calling the palette "fuzzy". */
function matches(command: PaletteCommand, query: string): boolean {
  if (!query) return true;
  return `${command.category} ${command.label}`.toLowerCase().includes(query);
}

export function CommandPalette({
  open,
  commands,
  onRun,
  onClose,
  placeholder = "Type a command…",
  emptyLabel = "No matching commands",
  className,
}: CommandPaletteProps) {
  const [query, setQuery] = useState("");
  const [hot, setHot] = useState(0);
  const inputRef = useRef<HTMLInputElement | null>(null);
  const listRef = useRef<HTMLUListElement | null>(null);

  const results = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return commands.filter((command) => matches(command, needle));
  }, [commands, query]);

  // Every open starts clean: empty filter, first row hot.
  useEffect(() => {
    if (!open) return;
    setQuery("");
    setHot(0);
    inputRef.current?.focus();
  }, [open]);

  // Typing always re-arms the first match ("hit Enter to run").
  useEffect(() => {
    setHot(0);
  }, [query]);

  // Keep the hot row inside the 260px scroll well while arrowing.
  useEffect(() => {
    if (!open) return;
    listRef.current?.children[hot]?.scrollIntoView({ block: "nearest" });
  }, [hot, open, results.length]);

  const runAt = useCallback(
    (index: number) => {
      const command = results[index];
      if (!command) return;
      onClose();
      onRun(command.id);
    },
    [results, onClose, onRun],
  );

  function onKeyDown(event: React.KeyboardEvent<HTMLDivElement>) {
    if (event.key === "Escape") {
      event.preventDefault();
      event.stopPropagation();
      onClose();
      return;
    }
    if (event.key === "Enter") {
      event.preventDefault();
      runAt(hot);
      return;
    }
    // Arrow navigation is a design-fresh addition: neither the demo nor the C#
    // palette moves the hot row, both only run the first match.
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      const count = results.length;
      if (count === 0) return;
      const step = event.key === "ArrowDown" ? 1 : -1;
      setHot((current) => (current + step + count) % count);
    }
  }

  if (!open) return null;

  return (
    <div
      className={className ? `cd-palette-scrim ${className}` : "cd-palette-scrim"}
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <div
        className="cd-palette"
        role="dialog"
        aria-modal="true"
        aria-label="Command palette"
        onKeyDown={onKeyDown}
      >
        <input
          ref={inputRef}
          className="cd-palette-input"
          type="text"
          value={query}
          placeholder={placeholder}
          autoComplete="off"
          autoCorrect="off"
          spellCheck={false}
          aria-label="Command"
          aria-controls="cd-palette-list"
          aria-activedescendant={results[hot] ? `cd-palette-row-${results[hot].id}` : undefined}
          onChange={(event) => setQuery(event.target.value)}
        />
        {results.length === 0 ? (
          <div className="cd-palette-empty">{emptyLabel}</div>
        ) : (
          <ul id="cd-palette-list" className="cd-palette-list" ref={listRef} role="listbox">
            {results.map((command, index) => (
              <li
                key={command.id}
                id={`cd-palette-row-${command.id}`}
                role="option"
                aria-selected={index === hot}
                className={index === hot ? "cd-palette-row is-hot" : "cd-palette-row"}
                // mousemove, not mouseenter: arrow-key scrolling slides rows under a
                // stationary cursor and would otherwise steal the hot row back.
                onMouseMove={() => {
                  if (index !== hot) setHot(index);
                }}
                onMouseDown={(event) => event.preventDefault()}
                onClick={() => runAt(index)}
              >
                <span className="cd-palette-label">
                  <em className="cd-palette-cat">{command.category}</em>
                  {command.label}
                </span>
                {command.kbd ? <span className="cd-palette-kbd">{command.kbd}</span> : null}
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
