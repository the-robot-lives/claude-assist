import type { KeyId } from "@/lib/bindings";

const LABELS: Partial<Record<KeyId, string>> = {
  super: "SUPER",
  shift: "SHIFT",
  ctrl: "CTRL",
  alt: "ALT",
  rctrl: "RCTRL",
  return: "↵",
  space: "Space",
  tab: "Tab",
  print: "PrtSc",
  escape: "Esc",
  left: "←",
  right: "→",
  up: "↑",
  down: "↓",
  scroll: "Scroll",
  lmb: "LMB",
  rmb: "RMB",
  volup: "Vol+",
  voldown: "Vol−",
  mute: "Mute",
  micmute: "Mic",
  brightup: "☀+",
  brightdown: "☀−",
  play: "⏯",
  next: "⏭",
  prev: "⏮",
};

export function keyLabel(id: KeyId | string): string {
  if (id in LABELS) return LABELS[id as KeyId]!;
  return String(id).toUpperCase();
}

export function Keycap({
  label,
  active = false,
  wide,
  className = "",
}: {
  label: string;
  active?: boolean;
  wide?: "sm" | "md" | "lg" | "xl";
  className?: string;
}) {
  const width =
    wide === "xl"
      ? "min-w-[7.5rem]"
      : wide === "lg"
        ? "min-w-[5rem]"
        : wide === "md"
          ? "min-w-[3.5rem]"
          : wide === "sm"
            ? "min-w-[2.75rem]"
            : "min-w-[2rem]";

  return (
    <span
      className={`keycap inline-flex items-center justify-center rounded-md border border-tn-border bg-tn-bg-dark px-2 py-1 text-[11px] font-medium tracking-wide text-foreground/90 ${width} ${
        active ? "active" : ""
      } ${className}`}
    >
      {label}
    </span>
  );
}

export function KeyChord({
  keys,
  activeIds,
  compact = false,
}: {
  keys: string[];
  activeIds?: Set<string>;
  compact?: boolean;
}) {
  return (
    <span className={`inline-flex flex-wrap items-center ${compact ? "gap-1" : "gap-1.5"}`}>
      {keys.map((k, i) => (
        <span key={`${k}-${i}`} className="inline-flex items-center gap-1">
          {i > 0 && <span className="text-muted text-[10px]">+</span>}
          <Keycap label={k} active={activeIds?.has(k.toLowerCase()) || activeIds?.has(k)} />
        </span>
      ))}
    </span>
  );
}
