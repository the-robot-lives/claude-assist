import { Spinner } from "@/components/ui";

export default function Loading() {
  return (
    <div className="flex min-h-[50dvh] flex-col items-center justify-center gap-3 text-text-muted">
      <Spinner size={28} />
      <p className="text-sm">Loading…</p>
    </div>
  );
}
