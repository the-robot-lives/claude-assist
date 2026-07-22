import Link from "next/link";
import { Button, EmptyState } from "@/components/ui";

export default function NotFound() {
  return (
    <div className="flex min-h-[50dvh] items-center justify-center px-4">
      <EmptyState
        title="Page not found"
        action={
          <Link href="/app">
            <Button variant="outline">Back to app</Button>
          </Link>
        }
      >
        The page you’re looking for doesn’t exist or may have moved.
      </EmptyState>
    </div>
  );
}
