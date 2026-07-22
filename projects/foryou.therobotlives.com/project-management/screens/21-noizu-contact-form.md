# 21: noizu.com Contact Form

| Field | Value |
|-------|-------|
| ID | SCR-21 |
| Type | modal |
| Category | Inquiries & Lead Capture |
| User Stories | US-081, US-082, US-083, US-086, US-087, US-088 |

## Description
The enhanced noizu.com contact modal: name + email + free-text inquiry plus
optional Company, Project type/service, Budget range, and Timeline. Posts to the
foryou public endpoint targeting a noizu.com "contact" list; backward-compatible
with the legacy inquiries endpoint.

## Key Components
- ContactForm — required + optional fields
- FormField — per-type field renderers (incl. select for budget/project type)
- HoneypotField — anti-spam
- SuccessState — confirmation of receipt
- InlineAlert — validation errors

## Interactions
- Submit basic or enhanced inquiry; optional fields may be blank
- Confirmation on success; spam protection; dual-write to default list

## Navigation
- **From:** noizu.com pages
- **To:** confirmation state; admin Inquiries (SCR-20) downstream
