"use client";

import { useEffect } from "react";
import { Panel, StatusTag } from "@/components/ui";

export default function Error({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => {
    // Surface for observability; the app also wires OpenTelemetry at the layout level.
    console.error(error);
  }, [error]);

  return (
    <div className="flex min-h-[50dvh] items-center justify-center px-4">
      <Panel className="flex max-w-sm flex-col items-center gap-3 px-6 py-9 text-center">
        <div className="flex items-center gap-2">
          <StatusTag tone="err" />
          <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">something went wrong</h1>
        </div>
        <p className="text-[11.5px] text-faint">
          an unexpected error occurred. you can retry, or reload the page if the problem persists.
        </p>
        <button type="button" onClick={reset} className="mt-1 text-[12px] font-bold text-acc hover:text-acc-hi">
          try again →
        </button>
      </Panel>
    </div>
  );
}
