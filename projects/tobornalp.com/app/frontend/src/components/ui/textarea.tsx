import { forwardRef } from "react";
import { cn } from "@/lib/cn";
import { inputBaseClass } from "./input";

export interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  invalid?: boolean;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(function Textarea(
  { className, invalid, "aria-invalid": ariaInvalid, rows = 4, ...props },
  ref,
) {
  return (
    <textarea
      ref={ref}
      rows={rows}
      aria-invalid={ariaInvalid ?? invalid}
      className={cn(
        inputBaseClass,
        "resize-y leading-relaxed",
        invalid && "border-error focus:border-error focus:ring-error/40",
        className,
      )}
      {...props}
    />
  );
});
