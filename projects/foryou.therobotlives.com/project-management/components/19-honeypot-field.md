# 19: HoneypotField

| Field | Value |
|-------|-------|
| ID | CMP-19 |
| Category | Input & Forms |
| Used In | SCR-11, SCR-12, SCR-21 |

## Description
A visually hidden anti-spam field included in public forms. Real users never fill
it; automated submissions that do are silently dropped, indistinguishable from a
normal response.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Default | Standard hidden honeypot on any public form |

## Props / Configuration
- `name` — innocuous field name
- `onTrip` — server-side rejection signal (silent)

## Interactions
- Hidden from sighted and assistive users (aria-hidden, off-screen, no tab stop)
- Filled → submission dropped as generic 202; complements rate-limiting
