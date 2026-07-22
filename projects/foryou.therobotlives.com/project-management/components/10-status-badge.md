# 10: StatusBadge

| Field | Value |
|-------|-------|
| ID | CMP-10 |
| Category | Data Display |
| Used In | SCR-04, SCR-18, SCR-19, SCR-22 |

## Description
A small labeled badge conveying status or role: signup status, opt-in mode, member
role, and migration stage. Uses text + shape, never color alone.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Signup status | pending_optin / subscribed / unsubscribed / bounced |
| Opt-in mode | single / double |
| Role | owner / admin / editor / member |
| Migration stage | provisioned / repointed / verified / backfilled |

## Props / Configuration
- `kind` — status | optin | role | stage
- `value` — the specific state
- `label` — display text

## Interactions
- Static; accessible label independent of color
