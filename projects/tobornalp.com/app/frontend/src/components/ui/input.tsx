import { forwardRef } from "react";
import { cn } from "@/lib/cn";

// Token-styled text input. Inherits surface/text/border tokens so it adapts to dark mode
// automatically. Pass `invalid` to render the error-ring treatment.
export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  invalid?: boolean;
}

export const inputBaseClass =
  "w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text " +
  "placeholder:text-text-muted transition-colors " +
  "focus:border-brand-blue focus:outline-none focus:ring-2 focus:ring-brand-blue/40 " +
  "disabled:cursor-not-allowed disabled:opacity-60";

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { className, invalid, "aria-invalid": ariaInvalid, ...props },
  ref,
) {
  return (
    <input
      ref={ref}
      aria-invalid={ariaInvalid ?? invalid}
      className={cn(inputBaseClass, invalid && "border-error focus:border-error focus:ring-error/40", className)}
      {...props}
    />
  );
});
