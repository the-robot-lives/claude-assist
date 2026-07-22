"use client";

import type { Binding, KeyId } from "@/lib/bindings";
import { KeyChord } from "./Keycap";

export function BindingRow({
  binding,
  hot = false,
  hover = false,
  copied = false,
  onHover,
  onLeave,
  onCopy,
}: {
  binding: Binding;
  hot?: boolean;
  hover?: boolean;
  copied?: boolean;
  onHover: (keys: KeyId[]) => void;
  onLeave: () => void;
  onCopy: (binding: Binding) => void;
}) {
  return (
    <button
      type="button"
      onMouseEnter={() => onHover(binding.keyIds)}
      onMouseLeave={onLeave}
      onFocus={() => onHover(binding.keyIds)}
      onBlur={onLeave}
      onClick={() => onCopy(binding)}
      className={`binding-row group flex w-full items-start gap-3 rounded-lg border border-tn-border bg-card px-3 py-2.5 text-left ${
        hot ? "hot" : hover ? "hover-keys" : "hover:border-tn-blue/40 hover:bg-card-hover"
      }`}
    >
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <KeyChord keys={binding.keys} />
          {binding.tags?.slice(0, 2).map((t) => (
            <span
              key={t}
              className="rounded-full border border-tn-border/80 px-1.5 py-0.5 text-[9px] uppercase tracking-wider text-muted"
            >
              {t}
            </span>
          ))}
        </div>
        <div className="mt-1.5 text-[13px] leading-snug text-foreground/90">
          {binding.action}
        </div>
        {binding.notes && (
          <div className="mt-1 text-[11px] leading-snug text-tn-yellow/90">
            {binding.notes}
          </div>
        )}
      </div>
      <span
        className={`shrink-0 rounded-md px-2 py-1 text-[10px] font-medium transition ${
          copied
            ? "bg-tn-green/20 text-tn-green"
            : "bg-tn-bg-dark text-muted opacity-0 group-hover:opacity-100 group-focus-visible:opacity-100"
        }`}
      >
        {copied ? "copied" : "copy"}
      </span>
    </button>
  );
}
