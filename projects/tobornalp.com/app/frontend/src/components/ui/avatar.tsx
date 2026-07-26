import { cn } from "@/lib/cn";

// Avatar — humans are a 22px circle of initials; agents are a dashed mint
// squircle carrying the ▣ glyph. The two must stay visually distinct: a reader
// should never have to guess whether a teammate is organic.
export interface AvatarProps {
  /** Display name or email; initials are derived when `initials` is absent. */
  name?: string;
  kind?: "human" | "agent";
  initials?: string;
  title?: string;
  className?: string;
}

export function Avatar({ name, kind = "human", initials, title, className }: AvatarProps) {
  const agent = kind === "agent";
  return (
    <span
      title={title ?? name}
      aria-hidden={!name && !initials}
      className={cn(
        "inline-flex h-[22px] w-[22px] flex-none items-center justify-center border text-[10px] font-bold",
        agent
          ? "rounded-[8px] border-dashed border-acc-line bg-acc-bg text-acc"
          : "rounded-full border-line2 bg-panel2 text-ink",
        className,
      )}
    >
      {agent ? "▣" : (initials ?? deriveInitials(name))}
    </span>
  );
}

function deriveInitials(name?: string): string {
  if (!name) return "?";
  const base = name.includes("@") ? name.split("@")[0] : name;
  const parts = base.split(/[\s._-]+/).filter(Boolean);
  if (parts.length === 0) return "?";
  const letters = parts.length === 1 ? parts[0].slice(0, 2) : parts[0][0] + parts[1][0];
  return letters.toUpperCase();
}
