"use client";

import { useId } from "react";

/**
 * Lightweight rich-text shell (S2.2 props contract).
 * v0.1: plain textarea with structured onChange; swap for Tiptap later
 * without changing parent integration surface.
 */
export interface RichTextEditorProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  readOnly?: boolean;
  minRows?: number;
  className?: string;
  /** Called when user types [[ to request entry link search (S2.2). */
  onLinkRequest?: (query: string) => void;
  label?: string;
}

export function RichTextEditor({
  value,
  onChange,
  placeholder = "Write entry content…",
  readOnly = false,
  minRows = 12,
  className = "",
  onLinkRequest,
  label,
}: RichTextEditorProps) {
  const id = useId();

  return (
    <div className={className}>
      {label && (
        <label
          htmlFor={id}
          className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5"
        >
          {label}
        </label>
      )}
      <textarea
        id={id}
        readOnly={readOnly}
        value={value}
        rows={minRows}
        placeholder={placeholder}
        onChange={(e) => {
          const next = e.target.value;
          onChange(next);
          if (onLinkRequest) {
            const m = next.slice(0, e.target.selectionStart ?? next.length).match(/\[\[([^\]]*)$/);
            if (m) onLinkRequest(m[1] ?? "");
          }
        }}
        className="w-full rounded-lg border border-rule bg-surface px-3 py-3 font-body text-[15px] leading-relaxed text-ink focus:outline-none focus:border-accent resize-y disabled:opacity-70"
      />
      <p className="mt-1.5 font-mono text-[11px] text-ink-tertiary">
        Tip: type <code className="text-ink-secondary">[[</code> to start an
        inline entry link (search hooks in when the link picker lands).
      </p>
    </div>
  );
}

export function RichTextRenderer({
  value,
  className = "",
}: {
  value: string;
  className?: string;
}) {
  return (
    <div
      className={`font-body text-[15px] leading-relaxed text-ink whitespace-pre-wrap ${className}`}
    >
      {value || (
        <span className="text-ink-tertiary italic">No content yet.</span>
      )}
    </div>
  );
}
