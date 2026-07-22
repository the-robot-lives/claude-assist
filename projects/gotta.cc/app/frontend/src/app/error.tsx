"use client";

import Link from "next/link";

// Top-level error boundary. Prevents a full white-screen when a route throws
// at render time (e.g. an unexpected data/schema drift) — degrades to a
// friendly message with a retry + a way back to browsing.
export default function Error({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-cream px-6">
      <div className="max-w-md text-center">
        <h1
          className="font-display text-2xl font-semibold tracking-tight text-ink"
          style={{ fontVariationSettings: "'WONK' 1" }}
        >
          Something went wrong.
        </h1>
        <p className="mt-3 font-body text-base leading-relaxed text-ink-secondary">
          We couldn&rsquo;t load this page. Please try again, or head back to
          browse the directory.
        </p>
        <div className="mt-6 flex items-center justify-center gap-4">
          <button
            onClick={reset}
            className="rounded-xl bg-coral px-5 py-2 font-ui text-sm font-semibold text-white transition-all duration-150 hover:-translate-y-0.5 hover:bg-coral-hover"
          >
            Try again
          </button>
          <Link
            href="/"
            className="font-ui text-sm font-semibold text-olive hover:text-olive-hover transition-colors duration-200"
          >
            Browse the directory &rarr;
          </Link>
        </div>
      </div>
    </div>
  );
}
