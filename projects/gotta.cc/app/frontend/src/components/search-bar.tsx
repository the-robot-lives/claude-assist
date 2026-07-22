"use client";

import { useEffect, useRef, useState } from "react";

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  onDebouncedChange?: (value: string) => void;
  onSubmit?: (value: string) => void;
  placeholder?: string;
  autoFocus?: boolean;
}

/**
 * Controlled search input. The parent owns `value`/`onChange` for immediate
 * updates. An optional internal 200ms debounce fires `onDebouncedChange` for
 * query-triggering consumers; Enter fires `onSubmit` (un-debounced).
 */
export function SearchBar({
  value,
  onChange,
  onDebouncedChange,
  onSubmit,
  placeholder = "Search sites…",
  autoFocus = false,
}: SearchBarProps) {
  const [local, setLocal] = useState(value);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Keep internal field in sync if the parent's value changes externally
  // (e.g. from the URL on /search).
  useEffect(() => {
    setLocal(value);
  }, [value]);

  function commit(next: string) {
    setLocal(next);
    onChange(next);
    if (onDebouncedChange) {
      if (timer.current) clearTimeout(timer.current);
      timer.current = setTimeout(() => onDebouncedChange(next), 200);
    }
  }

  useEffect(() => {
    return () => {
      if (timer.current) clearTimeout(timer.current);
    };
  }, []);

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        if (timer.current) clearTimeout(timer.current);
        onSubmit?.(local);
      }}
      className="relative"
    >
      <span className="pointer-events-none absolute left-5 top-1/2 -translate-y-1/2 text-ink-tertiary">
        <svg
          viewBox="0 0 24 24"
          className="h-5 w-5"
          fill="none"
          stroke="currentColor"
          strokeWidth={2}
          strokeLinecap="round"
          strokeLinejoin="round"
          aria-hidden="true"
        >
          <circle cx="11" cy="11" r="7" />
          <path d="m20 20-3.5-3.5" />
        </svg>
      </span>
      <input
        type="search"
        value={local}
        onChange={(e) => commit(e.target.value)}
        placeholder={placeholder}
        autoFocus={autoFocus}
        className="w-full rounded-xl border border-rule-strong bg-surface px-5 py-4 pl-14 font-body text-lg text-ink placeholder:text-ink-tertiary focus:border-olive focus:outline-none"
      />
    </form>
  );
}
