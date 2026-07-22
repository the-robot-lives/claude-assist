---
id: P-007
name: "Grace Whitfield"
slug: accessibility-low-bandwidth
archetype: "Assistive-tech user on a constrained connection"
segment: edge-case
tags: [accessibility, a11y, low-bandwidth, screen-reader, edge-case]
---

# P-007: Grace Whitfield

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 58 |
| Occupation | Retired teacher, community volunteer |
| Location | Rural Montana, USA |
| Tech comfort | medium |

## Bio
Grace uses a screen reader and often browses on a slow, intermittent connection.
She wants to sign up for a community-relevant list and manage her preferences,
but bloated forms and unlabeled fields lock her out.

## Goals
- Complete a signup and manage preferences using only a keyboard/screen reader.
- Use forms that load and work on a slow, high-latency connection.
- Understand errors and confirmations that are announced, not just colored.

## Frustrations
- Unlabeled inputs, missing focus order, and color-only error states.
- Heavy JavaScript widgets that never finish loading on slow links.
- Preference centers that are impossible to operate without a mouse.

## Behaviors
- Navigates entirely by keyboard; relies on ARIA labels and live regions.
- Abandons pages that don't render usable content quickly.
- Values plain, progressively-enhanced forms.

## Job to Be Done
> "When I sign up or change my preferences, I want forms that work with my screen
> reader on a slow connection, so I'm not excluded from staying in touch."

## Relationship to Product
The accessibility & low-bandwidth conscience of the product — ensures the public
signup surface, widget, and preference center meet WCAG and degrade gracefully.

## Scenarios
- **Scenario 1:** Screen-reader signup — completes a list signup entirely by
  keyboard with announced validation.
- **Scenario 2:** Low-bandwidth — the widget renders and submits on a throttled
  connection with a no-JS fallback path.
- **Scenario 3:** Announced confirmation — success and unsubscribe states are
  conveyed via live regions, not color alone.
