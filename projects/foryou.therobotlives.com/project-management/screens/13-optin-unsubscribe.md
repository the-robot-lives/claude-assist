# 13: Opt-in Confirmation & Unsubscribe

| Field | Value |
|-------|-------|
| ID | SCR-13 |
| Type | primary |
| Category | Signups & Subscriptions |
| User Stories | US-040, US-041, US-042, US-097 |

## Description
Token-driven public pages reached from email: confirm a double-opt-in
subscription, request a resend, and one-click unsubscribe — all without login.

## Key Components
- TokenResultPanel — success/failure state for confirm/unsubscribe tokens
- Button — "resend confirmation" / "manage preferences"
- InlineAlert — expired/invalid/used token messaging

## Interactions
- Confirm subscription via valid token; resend confirmation (throttled)
- Unsubscribe via token; safe handling of invalid/used tokens

## Navigation
- **From:** confirmation / unsubscribe emails (mailer)
- **To:** Preference Center (SCR-14)
