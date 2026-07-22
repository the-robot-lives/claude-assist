"use client";

import { useEffect } from "react";
import { Button, EmptyState } from "@/components/ui";

export default function Error({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => {
    // Surface for observability; the app also wires OpenTelemetry at the layout level.
    console.error(error);
  }, [error]);

  return (
    <div className="flex min-h-[50dvh] items-center justify-center px-4">
      <EmptyState
        title="Something went wrong"
        action={
          <Button variant="outline" onClick={reset}>
            Try again
          </Button>
        }
      >
        An unexpected error occurred. You can retry, or reload the page if the problem persists.
      </EmptyState>
    </div>
  );
}
