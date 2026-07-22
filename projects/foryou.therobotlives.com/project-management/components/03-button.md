# 03: Button

| Field | Value |
|-------|-------|
| ID | CMP-03 |
| Category | Input & Forms |
| Used In | SCR-01, SCR-02, SCR-03, SCR-05, SCR-06, SCR-07, SCR-08, SCR-13, SCR-14, SCR-16, SCR-22 |

## Description
The core action primitive used across every screen for primary, secondary, and
destructive actions, on the design-system classes.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Primary | Main call to action (create, submit) |
| Secondary | Non-primary actions (cancel, back) |
| Destructive | Irreversible actions (archive, decommission) with confirm |

## Props / Configuration
- `variant` — primary | secondary | destructive
- `size` — sm | md | lg
- `loading` — boolean — shows spinner, disables
- `disabled` — boolean
- `onClick` — handler

## Interactions
- Hover/focus/active/disabled states; keyboard activatable
- Destructive variant pairs with ConfirmDialog (CMP-18)
- Loading state announced to assistive technology
