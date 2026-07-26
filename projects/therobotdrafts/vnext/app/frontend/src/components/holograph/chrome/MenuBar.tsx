"use client";

import { useEffect } from "react";
import {
  isSeparator,
  MENUS,
  type MenuEntry,
  type MenuNode,
  type TrdCommandId,
} from "./menu-data";

export interface MenuBarProps {
  openMenu: string | null;
  onOpenMenu: (label: string | null) => void;
  /** A command is enabled iff the workspace registered a handler for it. */
  isEnabled: (command: TrdCommandId) => boolean;
  onRun: (command: TrdCommandId) => void;
  checks: Record<string, boolean>;
  dynamicItems: Record<"recents" | "windows", MenuEntry[]>;
  appTitle: string;
}

export function MenuBar({
  openMenu,
  onOpenMenu,
  isEnabled,
  onRun,
  checks,
  dynamicItems,
  appTitle,
}: MenuBarProps) {
  useEffect(() => {
    if (!openMenu) return;
    function close() {
      onOpenMenu(null);
    }
    window.addEventListener("click", close);
    return () => window.removeEventListener("click", close);
  }, [openMenu, onOpenMenu]);

  function renderEntries(entries: MenuEntry[], keyPrefix: string) {
    return entries.map((entry, index) => {
      const key = `${keyPrefix}:${index}`;
      if (isSeparator(entry)) return <div key={key} className="trd-sep" />;
      return renderItem(entry, key);
    });
  }

  function renderItem(node: MenuNode, key: string) {
    const children = node.dynamic ? dynamicItems[node.dynamic] : node.children;
    const checked = node.check ? Boolean(checks[node.check]) : false;

    if (children && children.length > 0) {
      return (
        <div key={key} className="trd-mi trd-mi--sub" role="menuitem" aria-haspopup="true" tabIndex={0}>
          <span className="trd-mi__label">
            {checked ? <span className="trd-mi__check">✓</span> : null}
            {node.label}
          </span>
          <div className="trd-submenu" role="menu">
            {renderEntries(children, key)}
          </div>
        </div>
      );
    }

    // A submenu parent whose dynamic children are empty still renders, but inert.
    const enabled = Boolean(node.command && isEnabled(node.command));
    return (
      <button
        key={key}
        type="button"
        role="menuitem"
        className={enabled ? "trd-mi" : "trd-mi is-disabled"}
        disabled={!enabled}
        onClick={() => {
          if (!node.command || !enabled) return;
          onOpenMenu(null);
          onRun(node.command);
        }}
      >
        <span className="trd-mi__label">
          {checked ? <span className="trd-mi__check">✓</span> : null}
          {node.label}
        </span>
        {node.kbd ? <span className="trd-kbd">{node.kbd}</span> : null}
      </button>
    );
  }

  return (
    <div className="trd-menubar-band">
      <nav className="trd-menubar" aria-label="Application menu bar" onClick={(event) => event.stopPropagation()}>
        {MENUS.map((menu) => {
          const isOpen = openMenu === menu.label;
          return (
            <div
              key={menu.label}
              className={isOpen ? "trd-menu is-open" : "trd-menu"}
              // macOS chase behaviour: with a menu already open, hovering a sibling opens it.
              onMouseEnter={() => {
                if (openMenu && !isOpen) onOpenMenu(menu.label);
              }}
            >
              <button
                type="button"
                aria-haspopup="menu"
                aria-expanded={isOpen}
                onClick={() => onOpenMenu(isOpen ? null : menu.label)}
              >
                {menu.label}
              </button>
              {isOpen ? (
                <div className="trd-dropdown" role="menu" aria-label={`${menu.label} menu`}>
                  {renderEntries(menu.items, menu.label)}
                </div>
              ) : null}
            </div>
          );
        })}
      </nav>
      <span className="trd-title-app">{appTitle}</span>
    </div>
  );
}
