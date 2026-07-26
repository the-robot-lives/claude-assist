import { forwardRef } from "react";
import { cn } from "@/lib/cn";

// Btn — the console pill button. Prefer this over the older `Button`, which
// renders the styleguide's `.btn` class family.
// `btnClass()` is exported so <Link> and <a> can wear the same skin.
export type BtnVariant = "default" | "primary";

const VARIANT: Record<BtnVariant, string> = {
  default: "border-line2 bg-panel2 text-ink hover:border-faint",
  // Primary is solid mint on black text — never mint text on a mint field.
  primary: "border-acc bg-acc text-black hover:border-acc-hi hover:bg-acc-hi",
};

export function btnClass(variant: BtnVariant = "default", className?: string): string {
  return cn(
    "inline-flex items-center justify-center gap-1.5 rounded-pill border px-3.5 py-[5px] text-[12px] font-bold no-underline transition-colors",
    VARIANT[variant],
    "disabled:cursor-not-allowed disabled:opacity-60",
    className,
  );
}

export interface BtnProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: BtnVariant;
}

export const Btn = forwardRef<HTMLButtonElement, BtnProps>(function Btn(
  { variant = "default", className, type = "button", ...props },
  ref,
) {
  return <button ref={ref} type={type} className={btnClass(variant, className)} {...props} />;
});
