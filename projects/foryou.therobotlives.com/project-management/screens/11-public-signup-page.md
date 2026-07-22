# 11: Public Signup Page

| Field | Value |
|-------|-------|
| ID | SCR-11 |
| Type | primary |
| Category | Signups & Subscriptions |
| User Stories | US-037, US-038, US-039, US-043, US-044, US-045, US-049, US-100 |

## Description
The hosted, unauthenticated signup page for a List. Renders fields from declared
attributes, validates, submits to the rate-limited public endpoint, and shows a
generic success state. Accessible and low-bandwidth friendly.

## Key Components
- DynamicForm — attribute-driven form renderer
- FormField — per-type field renderers
- HoneypotField — hidden anti-spam field
- SuccessState — announced thank-you / check-your-email message
- InlineAlert — validation errors

## Interactions
- Submit signup (idempotent upsert); client+server validation
- Generic 202 with no existence leak; rate-limited; honeypot drops spam

## Navigation
- **From:** portfolio sites; branded Service links
- **To:** Opt-in Confirmation (SCR-13); Preference Center (SCR-14) after account
