import { cn } from "@/lib/cn";

// Key — mono faint item identifiers (TRP-142, O-7, PERS-12) and the small
// gutter marks that sit in the same slot.
export interface KeyProps extends React.HTMLAttributes<HTMLSpanElement> {
  children: React.ReactNode;
}

export function Key({ children, className, ...props }: KeyProps) {
  return (
    <span className={cn("text-[11px] tracking-[0.03em] text-faint", className)} {...props}>
      {children}
    </span>
  );
}
