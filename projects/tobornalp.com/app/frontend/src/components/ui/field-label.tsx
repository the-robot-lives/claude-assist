import { cn } from "@/lib/cn";

// Associates a label with its control. Wrapping the control in the <label> gives implicit
// association; pass `htmlFor` (with a matching control `id`) for explicit association when
// the control is not a direct child. A required field shows a small brand-red dot.
export interface FieldLabelProps {
  label: React.ReactNode;
  children: React.ReactNode;
  htmlFor?: string;
  required?: boolean;
  hint?: React.ReactNode;
  error?: React.ReactNode;
  className?: string;
}

export function FieldLabel({ label, children, htmlFor, required, hint, error, className }: FieldLabelProps) {
  return (
    <label htmlFor={htmlFor} className={cn("flex flex-col gap-1.5", className)}>
      <span className="flex items-center gap-1 text-sm font-medium text-text">
        {label}
        {required && (
          <span aria-hidden className="text-brand-red" title="Required">
            •
          </span>
        )}
      </span>
      {children}
      {error ? (
        <span className="text-xs text-error">{error}</span>
      ) : hint ? (
        <span className="text-xs text-text-muted">{hint}</span>
      ) : null}
    </label>
  );
}
