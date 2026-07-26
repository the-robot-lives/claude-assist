import { Spinner } from "@/components/ui";

export default function Loading() {
  return (
    <div className="flex min-h-[50dvh] flex-col items-center justify-center gap-3 text-faint">
      <Spinner size={28} />
      <p className="text-[12px]">loading…</p>
    </div>
  );
}
