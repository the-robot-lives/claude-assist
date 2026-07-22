# 17: TokenResultPanel

| Field | Value |
|-------|-------|
| ID | CMP-17 |
| Category | Feedback & Indicators |
| Used In | SCR-13 |

## Description
The result panel for token-driven public actions (confirm subscription,
unsubscribe): shows success, expired/invalid/used states, and next-step actions
without requiring login.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Confirm | Double opt-in confirmation result |
| Unsubscribe | Unsubscribe result |

## Props / Configuration
- `action` — confirm | unsubscribe
- `state` — success | expired | invalid | used
- `onResend` — resend confirmation (confirm variant)
- `onManage` — link to preference center

## Interactions
- Renders the token outcome; offers resend/manage next steps
- Announced result; safe handling of bad tokens
