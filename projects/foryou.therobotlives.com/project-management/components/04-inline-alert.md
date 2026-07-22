# 04: InlineAlert

| Field | Value |
|-------|-------|
| ID | CMP-04 |
| Category | Feedback & Indicators |
| Used In | SCR-01, SCR-04, SCR-07, SCR-11, SCR-12, SCR-13, SCR-15, SCR-21 |

## Description
Announced inline messaging for validation errors, success, and status. Uses live
regions so assistive technology hears changes; never conveys meaning by color
alone.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Error | Validation / failure messaging |
| Success | Confirmations (signup, save, unsubscribe) |
| Info | Neutral status / guidance |

## Props / Configuration
- `variant` — error | success | info
- `message` — string
- `live` — polite | assertive — ARIA live region politeness
- `icon` — optional non-color indicator

## Interactions
- Renders into an ARIA live region; announced on change
- Pairs with FormField (CMP-01) for field-level errors
