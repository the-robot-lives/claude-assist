"use client";

import { KeyboardEvent, useState } from "react";

export interface TagInputProps {
  value: string[];
  onChange: (tags: string[]) => void;
  placeholder?: string;
}

export function TagInput({
  value,
  onChange,
  placeholder = "Add tag and press Enter",
}: TagInputProps) {
  const [draft, setDraft] = useState("");

  function addTag(raw: string) {
    const tag = raw.trim();
    if (!tag) return;
    if (value.some((t) => t.toLowerCase() === tag.toLowerCase())) {
      setDraft("");
      return;
    }
    onChange([...value, tag]);
    setDraft("");
  }

  function onKeyDown(e: KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Enter" || e.key === ",") {
      e.preventDefault();
      addTag(draft);
    } else if (e.key === "Backspace" && !draft && value.length) {
      onChange(value.slice(0, -1));
    }
  }

  return (
    <div className="rounded-lg border border-rule bg-surface px-2 py-2 flex flex-wrap gap-1.5 focus-within:border-accent">
      {value.map((tag) => (
        <span
          key={tag}
          className="inline-flex items-center gap-1 font-mono text-[12px] text-ink-secondary bg-elevated rounded-sm px-2 py-0.5"
        >
          {tag}
          <button
            type="button"
            onClick={() => onChange(value.filter((t) => t !== tag))}
            className="text-ink-tertiary hover:text-ink"
            aria-label={`Remove ${tag}`}
          >
            ×
          </button>
        </span>
      ))}
      <input
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={onKeyDown}
        onBlur={() => addTag(draft)}
        placeholder={value.length ? "" : placeholder}
        className="flex-1 min-w-[120px] bg-transparent font-sans text-[14px] text-ink outline-none px-1 py-0.5"
      />
    </div>
  );
}
