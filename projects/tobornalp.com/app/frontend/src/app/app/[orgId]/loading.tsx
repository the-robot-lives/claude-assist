import { Spinner } from "@/components/ui";

export default function OrgLoading() {
  return (
    <div className="flex min-h-[40dvh] flex-col items-center justify-center gap-3 text-faint">
      <Spinner size={24} />
      <p className="text-[12px]">loading workspace…</p>
    </div>
  );
}
