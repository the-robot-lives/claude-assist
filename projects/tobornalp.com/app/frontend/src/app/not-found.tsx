import Link from "next/link";
import { Panel, StatusTag } from "@/components/ui";

export default function NotFound() {
  return (
    <div className="flex min-h-[50dvh] items-center justify-center px-4">
      <Panel className="flex max-w-sm flex-col items-center gap-3 px-6 py-9 text-center">
        <div className="flex items-center gap-2">
          <StatusTag tone="err" />
          <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">page not found</h1>
        </div>
        <p className="text-[11.5px] text-faint">the page you&rsquo;re looking for doesn&rsquo;t exist or may have moved.</p>
        <Link href="/app" className="mt-1 text-[12px] font-bold text-acc no-underline hover:text-acc-hi">
          back to app →
        </Link>
      </Panel>
    </div>
  );
}
