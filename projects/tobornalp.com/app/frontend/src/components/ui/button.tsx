import { forwardRef } from "react";
import { cn } from "@/lib/cn";

// Design-system button. Emits the `.btn` family defined in design-system.generated.css
// (scoped under html[data-design-theme="organic"]). Variants/sizes map to those classes;
// disabled styling is layered with Tailwind utilities since the generated CSS has none.
export type ButtonVariant = "primary" | "outline" | "ghost" | "danger";
export type ButtonSize = "sm" | "md" | "lg";

const VARIANT: Record<ButtonVariant, string> = {
  primary: "btn",
  outline: "btn btn-outline",
  ghost: "btn btn-ghost",
  danger: "btn danger",
};

const SIZE: Record<ButtonSize, string> = {
  sm: "btn-sm",
  md: "",
  lg: "btn-lg",
};

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  /** Apply the `.rounded` modifier (pill/rounded corners). */
  rounded?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = "primary", size = "md", rounded = false, className, type = "button", ...props },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      className={cn(
        VARIANT[variant],
        SIZE[size],
        rounded && "rounded",
        "disabled:cursor-not-allowed disabled:opacity-60",
        className,
      )}
      {...props}
    />
  );
});
