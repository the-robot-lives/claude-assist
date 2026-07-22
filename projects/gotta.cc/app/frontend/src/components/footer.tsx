function AsteriskMark({ className = "h-7 w-7" }: { className?: string }) {
  return (
    <svg className={`shrink-0 ${className}`} viewBox="0 0 200 200" aria-hidden="true">
      <g transform="translate(100,100)" style={{ fill: "var(--coral)" }}>
        <rect x="-8" y="-65" width="16" height="130" rx="8" />
        <rect x="-8" y="-65" width="16" height="130" rx="8" transform="rotate(60)" />
        <rect x="-8" y="-65" width="16" height="130" rx="8" transform="rotate(120)" />
      </g>
    </svg>
  );
}

export function Footer() {
  return (
    <footer className="border-t border-rule px-6 py-6">
      <div className="mx-auto flex max-w-[960px] flex-col items-center justify-between gap-4 sm:flex-row">
        <span className="flex items-center gap-1.5 font-ui text-xs text-ink-tertiary">
          <AsteriskMark className="h-3.5 w-3.5" />
          &copy; 2026 gotta.cc
        </span>
        <div className="flex gap-6">
          <a
            href="#"
            className="font-ui text-xs text-ink-tertiary transition-colors duration-150 hover:text-ink-secondary"
          >
            Privacy
          </a>
          <a
            href="#"
            className="font-ui text-xs text-ink-tertiary transition-colors duration-150 hover:text-ink-secondary"
          >
            Terms
          </a>
        </div>
      </div>
    </footer>
  );
}
