# Setup Step Indicator

| Field | Value |
|-------|-------|
| **ID** | `setup-step-indicator` |
| **Category** | Navigation & Layout |
| **Used In** | 11-Setup Wizard |

## Description

Shows progress through the multi-step first-run flow (install confirmation, machine detection, profile creation, KB seeding, tour), so the user always knows how much setup is left. Single-use, but included for its complex multi-step interaction pattern.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | `Step 3 of 6` |
| **Compact** | Step counter plus current step name |
| **Expanded** | Full step list with completed/current/upcoming states |

## Props / Configuration

- `steps` — ordered array of step labels
- `current` — index

## Interactions

- Read-only during normal flow; back-navigation (where safe) re-opens a completed step for correction.
