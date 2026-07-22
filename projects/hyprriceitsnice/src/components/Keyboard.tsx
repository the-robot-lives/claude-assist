"use client";

import type { KeyId } from "@/lib/bindings";
import { keyLabel } from "./Keycap";

type KeyDef = {
  id?: KeyId;
  label?: string;
  wide?: "sm" | "md" | "lg" | "xl";
  ghost?: boolean;
  spacer?: boolean;
};

const ROWS: KeyDef[][] = [
  [
    { id: "escape", label: "Esc", wide: "sm" },
    { spacer: true },
    { id: "1" },
    { id: "2" },
    { id: "3" },
    { id: "4" },
    { id: "5" },
    { id: "6" },
    { id: "7" },
    { id: "8" },
    { id: "9" },
    { id: "0" },
    { spacer: true },
    { id: "print", label: "PrtSc", wide: "md" },
  ],
  [
    { id: "tab", label: "Tab", wide: "md" },
    { id: "q" },
    { id: "w" },
    { id: "e" },
    { label: "R", ghost: true },
    { id: "t" },
    { label: "Y", ghost: true },
    { label: "U", ghost: true },
    { label: "I", ghost: true },
    { label: "O", ghost: true },
    { id: "p" },
    { spacer: true },
    { id: "up", label: "↑" },
  ],
  [
    { label: "Caps", wide: "md", ghost: true },
    { id: "a" },
    { id: "s" },
    { label: "D", ghost: true },
    { id: "f" },
    { label: "G", ghost: true },
    { id: "h" },
    { id: "j" },
    { id: "k" },
    { id: "l" },
    { spacer: true },
    { id: "left", label: "←" },
    { id: "down", label: "↓" },
    { id: "right", label: "→" },
  ],
  [
    { id: "shift", label: "SHIFT", wide: "lg" },
    { label: "Z", ghost: true },
    { label: "X", ghost: true },
    { id: "c" },
    { id: "v" },
    { id: "b" },
    { label: "N", ghost: true },
    { id: "m" },
    { spacer: true },
    { id: "shift", label: "SHIFT", wide: "lg" },
  ],
  [
    { id: "ctrl", label: "CTRL", wide: "md" },
    { id: "super", label: "SUPER", wide: "md" },
    { id: "alt", label: "ALT", wide: "md" },
    { id: "space", label: "Space", wide: "xl" },
    { id: "alt", label: "ALT", wide: "sm" },
    { id: "rctrl", label: "RCTRL", wide: "md" },
    { id: "return", label: "↵ Enter", wide: "lg" },
  ],
];

function widthClass(wide?: KeyDef["wide"]): string {
  switch (wide) {
    case "xl":
      return "min-w-[8.5rem] flex-1";
    case "lg":
      return "min-w-[4.5rem]";
    case "md":
      return "min-w-[3.25rem]";
    case "sm":
      return "min-w-[2.5rem]";
    default:
      return "min-w-[1.85rem] w-8";
  }
}

export function Keyboard({
  active,
  className = "",
}: {
  active: Set<KeyId>;
  className?: string;
}) {
  return (
    <div
      className={`rounded-xl border border-tn-border bg-tn-bg-dark/80 p-3 backdrop-blur ${className}`}
      aria-hidden
    >
      <div className="mb-2 flex items-center justify-between px-1">
        <span className="text-[10px] font-medium uppercase tracking-[0.2em] text-muted">
          Virtual board
        </span>
        <span className="text-[10px] text-muted">
          hover a bind · or enable listen mode
        </span>
      </div>
      <div className="flex flex-col gap-1.5">
        {ROWS.map((row, ri) => (
          <div key={ri} className="flex flex-wrap justify-center gap-1">
            {row.map((key, ki) => {
              if (key.spacer) {
                return (
                  <span
                    key={`${ri}-${ki}-sp`}
                    className="h-8 w-3 rounded-md border border-transparent opacity-30 sm:w-4"
                  />
                );
              }

              const id = key.id;
              const lit =
                !!id &&
                (active.has(id) ||
                  (id === "ctrl" && active.has("rctrl")) ||
                  (id === "rctrl" && active.has("ctrl")));
              const label = key.label ?? (id ? keyLabel(id) : "");
              const w = widthClass(key.wide);

              return (
                <span
                  key={`${ri}-${ki}-${label}`}
                  className={`keycap inline-flex h-8 items-center justify-center rounded-md border px-1.5 text-[10px] font-medium ${w} ${
                    key.ghost && !lit
                      ? "border-tn-border/40 bg-transparent text-muted/50"
                      : "border-tn-border bg-background/60 text-foreground/85"
                  } ${lit ? "active" : ""}`}
                >
                  {label}
                </span>
              );
            })}
          </div>
        ))}
      </div>
      <div className="mt-3 flex flex-wrap justify-center gap-1.5 border-t border-tn-border/60 pt-2">
        {(
          [
            ["lmb", "LMB"],
            ["rmb", "RMB"],
            ["scroll", "Scroll"],
            ["volup", "Vol+"],
            ["voldown", "Vol−"],
            ["mute", "Mute"],
            ["brightup", "☀+"],
            ["brightdown", "☀−"],
            ["play", "⏯"],
          ] as const
        ).map(([id, label]) => (
          <span
            key={id}
            className={`keycap inline-flex h-7 items-center justify-center rounded-md border border-tn-border bg-background/50 px-2 text-[10px] ${
              active.has(id) ? "active" : ""
            }`}
          >
            {label}
          </span>
        ))}
      </div>
    </div>
  );
}
