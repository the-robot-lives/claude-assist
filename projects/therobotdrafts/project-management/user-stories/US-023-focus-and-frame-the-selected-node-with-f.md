---
id: US-023
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Focus and frame the selected node with F"
epic: "Bubble navigation & orientation"
priority: P0
segment: primary
tags: [focus, frame-selection, hotkey, orientation]
---

# US-023 — Focus and frame the selected node with F

**As** Marcus, the newly-onboarding engineer,
**I want** press F to focus and frame whatever node I have selected,
**so that** I can recover orientation and zero in on the thing I care about, like every 3D tool I know.

## Acceptance criteria
- [ ] Pressing F frames the current selection with margin and a smooth-but-bounded transition
- [ ] Home resets to the default whole-model view
- [ ] A HUD 'Recenter' button offers the same focus action for mouse-only users
- [ ] Invoking focus with nothing selected falls back to frame-all rather than doing nothing

## Notes
Implements UX-review B5; counters P0-3 (only Ctrl+F frame-all exists, no focus-on-selection).
