"use client";

import { useState } from "react";
import { useThemeConfig } from "./ThemeConfigContext";
import type { ConfigWarning } from "@styleguide-engine/lib/types";

export function ConfigWarnings() {
  const { config, allConfigs, activeSlug } = useThemeConfig();
  const [collapsed, setCollapsed] = useState(false);

  const activeConfig = allConfigs[activeSlug] || config;
  const warnings = activeConfig.warnings;
  if (!warnings || warnings.length === 0) return null;

  const errors = warnings.filter((w) => w.level === "error");
  const warns = warnings.filter((w) => w.level === "warn");

  const grouped = new Map<string, ConfigWarning[]>();
  for (const w of warnings) {
    if (!grouped.has(w.section)) grouped.set(w.section, []);
    grouped.get(w.section)!.push(w);
  }

  return (
    <div style={{
      margin: "var(--space-3) 0",
      border: "1px solid",
      borderColor: errors.length > 0 ? "var(--semantic-danger-accent, #dc2626)" : "var(--semantic-warning-accent, #f59e0b)",
      borderRadius: "var(--radius, 6px)",
      overflow: "hidden",
      fontFamily: "var(--font-mono, monospace)",
      fontSize: "var(--font-size-xs, 12px)",
    }}>
      <div
        onClick={() => setCollapsed(!collapsed)}
        style={{
          display: "flex",
          alignItems: "center",
          gap: "var(--space-2, 8px)",
          padding: "var(--space-2, 8px) var(--space-3, 12px)",
          background: errors.length > 0
            ? "color-mix(in srgb, var(--semantic-danger-accent, #dc2626) 8%, var(--surface, #fff))"
            : "color-mix(in srgb, var(--semantic-warning-accent, #f59e0b) 8%, var(--surface, #fff))",
          cursor: "pointer",
          userSelect: "none" as const,
        }}
      >
        <span style={{
          fontWeight: 700,
          color: errors.length > 0 ? "var(--semantic-danger-accent, #dc2626)" : "var(--semantic-warning-accent, #f59e0b)",
        }}>
          {errors.length > 0 ? "!" : "⚠"}
        </span>
        <span style={{ flex: 1, fontWeight: 600 }}>
          Theme &quot;{activeSlug}&quot; — {warnings.length} config {warnings.length === 1 ? "issue" : "issues"}
          {errors.length > 0 && <span style={{ color: "var(--semantic-danger-accent, #dc2626)" }}> ({errors.length} {errors.length === 1 ? "error" : "errors"})</span>}
          {warns.length > 0 && <span style={{ color: "var(--semantic-warning-accent, #f59e0b)" }}> ({warns.length} {warns.length === 1 ? "warning" : "warnings"})</span>}
        </span>
        <span style={{
          transition: "transform 0.15s",
          transform: collapsed ? "rotate(0deg)" : "rotate(90deg)",
          opacity: 0.5,
        }}>&#9654;</span>
      </div>

      {!collapsed && (
        <div style={{ padding: "var(--space-2, 8px) var(--space-3, 12px)" }}>
          {[...grouped.entries()].map(([section, items]) => (
            <div key={section} style={{ marginBottom: "var(--space-2, 8px)" }}>
              <div style={{
                fontWeight: 700,
                marginBottom: "var(--space-half, 4px)",
                color: "var(--text-secondary, #555)",
                textTransform: "uppercase" as const,
                letterSpacing: "0.05em",
                fontSize: "var(--font-size-2xs, 10px)",
              }}>
                {section}
              </div>
              {items.map((w, i) => (
                <div key={i} style={{
                  display: "flex",
                  gap: "var(--space-1, 4px)",
                  padding: "2px 0",
                  lineHeight: 1.5,
                }}>
                  <span style={{
                    color: w.level === "error"
                      ? "var(--semantic-danger-accent, #dc2626)"
                      : "var(--semantic-warning-accent, #f59e0b)",
                    flexShrink: 0,
                  }}>
                    {w.level === "error" ? "✗" : "⚠"}
                  </span>
                  <span>
                    <span>{w.message}</span>
                    {(w.sourceFile || w.sourcePath || w.fix) && (
                      <span style={{
                        display: "block",
                        marginTop: "2px",
                        color: "var(--text-muted, #666)",
                      }}>
                        {w.sourceFile && (
                          <>
                            Populate: <code>{w.sourceFile}</code>
                            {w.sourcePath ? " -> " : ""}
                          </>
                        )}
                        {w.sourcePath && <code>{w.sourcePath}</code>}
                        {w.fix ? <span> | {w.fix}</span> : null}
                      </span>
                    )}
                  </span>
                </div>
              ))}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
