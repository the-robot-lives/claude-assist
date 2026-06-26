---
id: US-100
persona: P-009
persona_slug: trd-accessibility-first-dev
title: "Get non-color status feedback for actions"
epic: "Accessibility (color/keyboard/motion)"
priority: P1
segment: edge-case
tags: [status-feedback, non-color, affordance, accessibility]
---

# US-100 — Get non-color status feedback for actions

**As** Theo, the accessibility-constrained developer,
**I want** get valid/invalid and mode feedback through shape, icon, and text - not color alone,
**so that** I can tell what's happening even though red and green look the same to me.

## Acceptance criteria
- [ ] Valid-target feedback shows a check glyph + rim thickening; invalid shows a dashed rim + cross, never color alone
- [ ] Active mode and sticky state show a persistent labeled pill, not just a hue change
- [ ] Errors persist in a dismissible toast/log, not a one-shot color flash
- [ ] Every status conveyed by the reserved color channel is duplicated by a shape or text cue

## Notes
Implements authoring-ux 5.1-5.2 for Theo; counters UX-review P0-5/P1-2 one-shot flashes and color-only states.
