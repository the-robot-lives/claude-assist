import { cn } from "@/lib/cn";

// Chip — the pill vocabulary for item kinds, scopes and actors.
// `agent` is deliberately dashed: the human/agent distinction is never blurred.
export type ChipVariant = "default" | "bug" | "story" | "task" | "epic" | "agent" | "scope";

const VARIANT: Record<ChipVariant, string> = {
  default: "border-line2 text-mut",
  bug: "border-err bg-err-bg text-err",
  story: "border-info bg-info-bg text-info",
  task: "border-line2 text-mut",
  epic: "border-vio-line bg-vio-bg text-vio",
  agent: "border-dashed border-acc-line bg-acc-bg text-acc",
  scope: "border-line2 bg-panel2 text-mut",
};

export interface ChipProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: ChipVariant;
  children: React.ReactNode;
}

export function Chip({ variant = "default", className, children, ...props }: ChipProps) {
  return (
    <span
      className={cn(
        "inline-block whitespace-nowrap rounded-pill border px-[9px] py-px text-[10px] tracking-[0.04em]",
        VARIANT[variant],
        className,
      )}
      {...props}
    >
      {children}
    </span>
  );
}
