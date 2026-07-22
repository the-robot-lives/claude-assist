---
id: US-100
title: "Large-text/high-contrast mode for older merchants"
slug: "large-text-high-contrast-mode"
personas: [P-001, P-002]
epic: "Accessibility & i18n"
priority: "should-have"
complexity: "M"
tags: [accessibility, a11y, ux]
---

# US-100: Large-text/high-contrast mode for older merchants

## User Story

**As an** older market-stall owner (P-001) with reduced near vision,
**I want** a large-text, high-contrast display mode,
**So that** I can read prices and buttons clearly on the sell screen without straining.

## Acceptance Criteria

- [ ] Given Settings > Accessibility, when the user enables "large text" mode, then font sizes across the sell screen and catalog increase to a legible scale without breaking layout or clipping text.
- [ ] Given the user enables "high contrast" mode, when active, then color combinations meet at least WCAG AA contrast ratios for text and interactive elements.
- [ ] Given both modes are combined with the OS-level accessibility text scale, when the user changes the OS setting, then the app's layout adapts gracefully (no overlapping or truncated critical buttons like "Charge"/"Cash").

## Notes

Should-have — directly serves the stated persona of older merchants unfamiliar with smartphones (product principle 1). Complements US-099 but independently valuable for sighted users with low vision needs.
