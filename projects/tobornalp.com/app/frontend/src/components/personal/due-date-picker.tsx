"use client";

import { Input } from "@/components/ui";

// Due-date entry: a native date picker plus a free-text field for a relative
// phrase ("today", "next monday", "in 3 days"). Emits the raw string; the server
// resolves phrases via `parse_shorthand` in the user's timezone, so the client
// never has to interpret them.
export function DueDatePicker({
  value,
  onChange,
}: {
  value: string | null;
  onChange: (v: string | null) => void;
}) {
  // A native date input only accepts YYYY-MM-DD; show it there when the value is
  // ISO, otherwise leave the phrase in the text field.
  const isIso = !!value && /^\d{4}-\d{2}-\d{2}$/.test(value);

  return (
    <div className="flex items-center gap-2">
      <Input
        type="date"
        aria-label="due date"
        value={isIso ? (value as string) : ""}
        onChange={(e) => onChange(e.target.value || null)}
        className="w-40"
      />
      <Input
        type="text"
        aria-label="due date phrase"
        placeholder="or 'next monday'"
        value={isIso ? "" : value ?? ""}
        onChange={(e) => onChange(e.target.value || null)}
        className="w-40"
      />
    </div>
  );
}
