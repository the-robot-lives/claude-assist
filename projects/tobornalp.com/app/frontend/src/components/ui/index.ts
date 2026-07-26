// Shared UI component library — dark-neon console primitives.
// Import from "@/components/ui".

export { Button, type ButtonProps, type ButtonVariant, type ButtonSize } from "./button";
export { Input, inputBaseClass, type InputProps } from "./input";
export { Select, type SelectProps } from "./select";
export { Textarea, type TextareaProps } from "./textarea";
export { FieldLabel, type FieldLabelProps } from "./field-label";
export { Dialog, type DialogProps, type DialogSize } from "./dialog";
export { EmptyState, type EmptyStateProps } from "./empty-state";
export { Spinner, type SpinnerProps } from "./spinner";
export { SectionCard, Empty } from "./section-card";
export { ProgressBar, type ProgressTone } from "./progress-bar";
export { PriorityBadge, StatusBadge } from "./badges";

// Console primitives — see design/concept-dark-neon/DESIGN-SPEC.md
export { Panel, PanelHeader, type PanelProps, type PanelHeaderProps } from "./panel";
export { Chip, type ChipProps, type ChipVariant } from "./chip";
export { Btn, btnClass, type BtnProps, type BtnVariant } from "./btn";
export { Avatar, type AvatarProps } from "./avatar";
export {
  StatusLine,
  StatusSeg,
  StatusTag,
  type StatusLineProps,
  type StatusSegProps,
  type StatusTone,
} from "./status-line";
export { PriorityDot, toPriorityLevel, type PriorityDotProps, type PriorityLevel } from "./priority-dot";
export { Key, type KeyProps } from "./item-key";
