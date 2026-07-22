# 18: ConfirmDialog

| Field | Value |
|-------|-------|
| ID | CMP-18 |
| Category | Modals & Overlays |
| Used In | SCR-16, SCR-22 |

## Description
A modal that guards irreversible or high-impact actions (account/data deletion
request, listmonk decommission) with an explicit confirm step.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Standard | Confirm a reversible-but-notable action |
| Destructive | Confirm an irreversible action (deletion, decommission) |

## Props / Configuration
- `title` / `body`
- `confirmLabel` / `cancelLabel`
- `variant` — standard | destructive
- `onConfirm` / `onCancel`
- `requireTypedConfirmation` — optional for destructive

## Interactions
- Focus-trapped; keyboard operable; explicit confirm
- Pairs with destructive Button (CMP-03)
