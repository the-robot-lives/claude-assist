---
id: US-098
persona: P-009
persona_slug: trd-accessibility-first-dev
title: "Use a reduced-motion mode with instant transitions"
epic: "Accessibility (color/keyboard/motion)"
priority: P0
segment: edge-case
tags: [reduced-motion, vestibular, instant-cut, comfort]
---

# US-098 — Use a reduced-motion mode with instant transitions

**As** Theo, the accessibility-constrained developer,
**I want** turn on reduced motion so camera changes are instant cuts instead of smooth flights,
**so that** navigating the tool doesn't trigger my vestibular nausea.

## Acceptance criteria
- [ ] A reduced-motion setting replaces smooth camera flights with instant cuts or minimal eased moves
- [ ] Focus, frame, drill, and recenter all honor reduced motion
- [ ] Re-pack/layout animations are disabled or reduced to instant under the setting
- [ ] The setting can follow the OS reduce-motion preference and persists across sessions

## Notes
Counters Theo's frustration 2 (smooth/fast 3D motion triggers nausea); serves goal 2 (tolerable motion).
