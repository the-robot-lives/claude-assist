"use client";

import { useState } from "react";
import { cn } from "@/lib/cn";

// Free-form tag chip input with org-scoped autocomplete. Enter or comma commits a
// chip; Backspace on an empty field removes the last. Values are lower-cased +
// de-duplicated client-side (the server normalizes again authoritatively).
export function TagChips({
  value,
  onChange,
  suggestions = [],
  placeholder = "add tag…",
}: {
  value: string[];
  onChange: (tags: string[]) => void;
  suggestions?: string[];
  placeholder?: string;
}) {
  const [draft, setDraft] = useState("");

  const add = (raw: string) => {
    const t = raw.trim().toLowerCase();
    if (t && !value.includes(t)) onChange([...value, t]);
    setDraft("");
  };

  const remove = (t: string) => onChange(value.filter((x) => x !== t));

  const onKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter" || e.key === ",") {
      e.preventDefault();
      add(draft);
    } else if (e.key === "Backspace" && draft === "" && value.length > 0) {
      remove(value[value.length - 1]);
    }
  };

  const matches =
    draft.trim().length > 0
      ? suggestions
          .filter((s) => s.includes(draft.trim().toLowerCase()) && !value.includes(s))
          .slice(0, 6)
      : [];

  return (
    <div className="relative">
      <div className="flex flex-wrap items-center gap-1 rounded-md border border-border bg-surface px-2 py-1.5">
        {value.map((t) => (
          <span
            key={t}
            className="inline-flex items-center gap-1 rounded bg-brand-blue/15 px-1.5 py-0.5 text-[11px] font-medium text-brand-blue"
          >
            #{t}
            <button type="button" onClick={() => remove(t)} className="text-brand-blue/70 hover:text-brand-blue" aria-label={`remove ${t}`}>
              ×
            </button>
          </span>
        ))}
        <input
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={onKeyDown}
          onBlur={() => draft && add(draft)}
          placeholder={value.length === 0 ? placeholder : ""}
          className="min-w-[6rem] flex-1 bg-transparent text-sm text-text outline-none placeholder:text-text-muted"
        />
      </div>
      {matches.length > 0 && (
        <ul className="absolute z-10 mt-1 w-full overflow-hidden rounded-md border border-border bg-surface shadow-lg">
          {matches.map((s) => (
            <li key={s}>
              <button
                type="button"
                onMouseDown={(e) => { e.preventDefault(); add(s); }}
                className="block w-full px-3 py-1.5 text-left text-sm text-text hover:bg-surface-alt"
              >
                #{s}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
