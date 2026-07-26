import { cn } from "@/lib/cn";

// Centered empty-state: optional icon, a title, optional body copy, optional action slot.
// Use inside a SectionCard body or a full-page container.
export interface EmptyStateProps {
  title: React.ReactNode;
  icon?: React.ReactNode;
  children?: React.ReactNode;
  action?: React.ReactNode;
  className?: string;
}

export function EmptyState({ title, icon, children, action, className }: EmptyStateProps) {
  return (
    <div className={cn("flex flex-col items-center justify-center gap-2 px-4 py-10 text-center", className)}>
      {icon && <div className="text-faint [&>svg]:h-8 [&>svg]:w-8">{icon}</div>}
      <h3 className="text-[12px] font-bold text-mut">{title}</h3>
      {children && <p className="max-w-sm text-[11.5px] text-faint">{children}</p>}
      {action && <div className="mt-2">{action}</div>}
    </div>
  );
}
