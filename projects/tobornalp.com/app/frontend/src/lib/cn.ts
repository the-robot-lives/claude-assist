// Tiny class-name joiner — filters falsy values so conditional classes stay terse.
// No dependency on clsx/classnames; the design system is class-driven, not variant-object driven.
export type ClassValue = string | number | bigint | boolean | null | undefined;

export function cn(...parts: ClassValue[]): string {
  return parts.filter(Boolean).join(" ");
}
