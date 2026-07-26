"use client";

import { useState } from "react";
import { Chip } from "@/components/ui";

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
      <div className="flex flex-wrap items-center gap-1.5 rounded-card border border-line2 bg-ground px-2 py-1.5 focus-within:border-acc">
        {/* Plain tags wear the `scope` look, not mint — mint stays reserved for
            agents / active / done so real signals keep their volume. */}
        {value.map((t) => (
          <Chip key={t} variant="scope">
            #{t}
            <button
              type="button"
              onClick={() => remove(t)}
              className="ml-1 text-faint hover:text-ink"
              aria-label={`remove ${t}`}
            >
              ×
            </button>
          </Chip>
        ))}
        <input
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={onKeyDown}
          onBlur={() => draft && add(draft)}
          placeholder={value.length === 0 ? placeholder : ""}
          className="min-w-[6rem] flex-1 bg-transparent text-[12px] text-ink outline-none placeholder:text-faint"
        />
      </div>
      {matches.length > 0 && (
        <ul className="absolute z-10 mt-1 w-full overflow-hidden rounded-card border border-line bg-panel shadow-pop">
          {matches.map((s) => (
            <li key={s}>
              <button
                type="button"
                onMouseDown={(e) => { e.preventDefault(); add(s); }}
                className="block w-full px-3 py-1.5 text-left text-[12px] text-ink hover:bg-sel"
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
