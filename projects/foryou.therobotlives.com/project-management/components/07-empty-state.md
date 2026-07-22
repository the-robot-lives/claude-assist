# 07: EmptyState

| Field | Value |
|-------|-------|
| ID | CMP-07 |
| Category | Feedback & Indicators |
| Used In | SCR-02, SCR-05, SCR-06, SCR-14, SCR-16 |

## Description
A reusable empty-state block with an explanation and a primary call to action.
Powers the orgless CTA, no-Services, no-Lists, no-subscriptions, and no-inquiries
states.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Actionable | Empty with a primary CTA (create org/service/list) |
| Informational | Empty with guidance only (subscriptions appear here) |

## Props / Configuration
- `title` — string
- `description` — string
- `action` — optional Button config (label + handler)
- `icon` — optional illustration

## Interactions
- CTA triggers the relevant create flow
- Accessible heading + description structure
