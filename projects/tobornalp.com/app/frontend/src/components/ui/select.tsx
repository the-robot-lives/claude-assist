import { forwardRef } from "react";
import { cn } from "@/lib/cn";
import { inputBaseClass } from "./input";

export interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  invalid?: boolean;
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(function Select(
  { className, invalid, "aria-invalid": ariaInvalid, children, ...props },
  ref,
) {
  return (
    <select
      ref={ref}
      aria-invalid={ariaInvalid ?? invalid}
      className={cn(
        inputBaseClass,
        "cursor-pointer pr-8",
        invalid && "border-error focus:border-error focus:ring-error/40",
        className,
      )}
      {...props}
    >
      {children}
    </select>
  );
});
