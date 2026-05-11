import React from "react";
import { Outlet, NavLink } from "react-router-dom";

const navItems = [
  { to: "/", label: "Dashboard", icon: "⊞" },
  { to: "/search", label: "Search", icon: "⊘" },
  { to: "/browse", label: "Browse", icon: "≡" },
  { to: "/datasets", label: "Datasets", icon: "◈" },
];

export function Layout() {
  return (
    <div className="flex h-screen flex-col bg-canvas">
      {/* Navbar */}
      <header className="flex h-14 items-center border-b border-border-subtle px-4">
        <span className="font-mono text-sm font-medium text-glow">claude-assist</span>
        <div className="ml-auto flex items-center gap-3">
          <div className="flex h-8 w-64 items-center rounded-md border border-border-subtle bg-surface px-3">
            <span className="text-xs text-text-dim">Search conversations...</span>
          </div>
          <span className="flex items-center gap-1.5 text-xs text-text-dim">
            <span className="h-2 w-2 rounded-full bg-emerald-500" />
            Indexed
          </span>
        </div>
      </header>

      <div className="flex flex-1 overflow-hidden">
        {/* Sidebar */}
        <nav className="flex w-[220px] flex-col border-r border-border-subtle bg-surface py-3">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === "/"}
              className={({ isActive }) =>
                `flex items-center gap-2 px-4 py-2 text-sm transition-colors ${
                  isActive
                    ? "border-l-[3px] border-glow bg-glow-bg text-text-bright"
                    : "border-l-[3px] border-transparent text-text-muted hover:text-text-primary"
                }`
              }
            >
              <span className="w-4 text-center text-xs">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
          <div className="my-2 border-t border-border-subtle" />
          <NavLink
            to="/settings"
            className={({ isActive }) =>
              `flex items-center gap-2 px-4 py-2 text-sm transition-colors ${
                isActive
                  ? "border-l-[3px] border-glow bg-glow-bg text-text-bright"
                  : "border-l-[3px] border-transparent text-text-muted hover:text-text-primary"
              }`
            }
          >
            <span className="w-4 text-center text-xs">{"⚙"}</span>
            Settings
          </NavLink>
        </nav>

        {/* Main content */}
        <main className="flex-1 overflow-y-auto p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
