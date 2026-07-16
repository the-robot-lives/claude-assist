# Accessibility Toggle

| Field | Value |
|-------|-------|
| **ID** | `accessibility-toggle` |
| **Category** | Input & Forms |
| **Used In** | 06-Quiz Generator & Runner, 07-Quiz SPA |

## Description

Switches on the accessibility mode appropriate to the surface: linear screen-reader-friendly output in the terminal quiz runner, or text-size/high-contrast controls in the browser Quiz SPA.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | Single toggle switch/flag |
| **Compact** | Toggle plus current mode label |
| **Expanded** | Full panel (text-size stepper, contrast mode, motion preference) |

## Props / Configuration

- `screenReaderMode` — boolean (terminal)
- `textScale`, `highContrast` — (SPA)

## Interactions

- Persists per-profile once set, so it doesn't need re-enabling each session.
