"use client";

import { Fragment } from "react";
import {
  Dialog as HDialog,
  DialogPanel,
  DialogTitle,
  Transition,
  TransitionChild,
} from "@headlessui/react";
import { cn } from "@/lib/cn";

// Token-styled modal built on Headless UI (focus trap, ESC/backdrop close, a11y roles are
// handled by the primitive). Provide `title` for the labelled heading, `footer` for the
// action row. `onClose` fires on backdrop click / ESC.
export type DialogSize = "sm" | "md" | "lg" | "xl";

const SIZE: Record<DialogSize, string> = {
  sm: "max-w-sm",
  md: "max-w-md",
  lg: "max-w-lg",
  xl: "max-w-2xl",
};

export interface DialogProps {
  open: boolean;
  onClose: () => void;
  title?: React.ReactNode;
  children: React.ReactNode;
  footer?: React.ReactNode;
  size?: DialogSize;
  className?: string;
}

export function Dialog({ open, onClose, title, children, footer, size = "md", className }: DialogProps) {
  return (
    <Transition appear show={open} as={Fragment}>
      <HDialog as="div" className="relative z-50" onClose={onClose}>
        <TransitionChild
          as={Fragment}
          enter="ease-out duration-150"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-100"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black/70 backdrop-blur-sm" aria-hidden="true" />
        </TransitionChild>

        <div className="fixed inset-0 flex items-center justify-center p-4">
          <TransitionChild
            as={Fragment}
            enter="ease-out duration-150"
            enterFrom="opacity-0 scale-95"
            enterTo="opacity-100 scale-100"
            leave="ease-in duration-100"
            leaveFrom="opacity-100 scale-100"
            leaveTo="opacity-0 scale-95"
          >
            <DialogPanel
              className={cn(
                "w-full rounded-panel border border-line2 bg-panel p-5 shadow-pop",
                SIZE[size],
                className,
              )}
            >
              {title && (
                <DialogTitle className="text-[12px] font-bold uppercase tracking-[0.1em] text-ink">
                  {title}
                </DialogTitle>
              )}
              <div className={cn(title && "mt-3")}>{children}</div>
              {footer && <div className="mt-5 flex items-center justify-end gap-2">{footer}</div>}
            </DialogPanel>
          </TransitionChild>
        </div>
      </HDialog>
    </Transition>
  );
}
