import { forwardRef } from "react";
import { cn } from "@/lib/cn";

// Console text input: recessed onto the true-black ground so the field reads as a
// hole in the panel rather than another raised surface. Shared by Select and
// Textarea via `inputBaseClass`. Pass `invalid` for the error treatment.
export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  invalid?: boolean;
}

export const inputBaseClass =
  "w-full rounded-card border border-line2 bg-ground px-3 py-1.5 text-[12.5px] text-ink " +
  "placeholder:text-faint transition-colors " +
  "focus:border-acc focus:outline-none focus:ring-1 focus:ring-acc-line " +
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
