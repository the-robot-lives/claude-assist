---
id: US-074
persona: P-006
persona_slug: trd-vr-explorer
title: "Name elements with a near-field VR keyboard"
epic: "VR & comfort"
priority: P1
segment: secondary
tags: [near-field-keyboard, naming, vr-input, sdf-mirror]
---

# US-074 — Name elements with a near-field VR keyboard

**As** Aiko, the VR/XR power user,
**I want** type an element's name on a near-field keyboard panel that mirrors onto the in-world label,
**so that** I can name code identifiers reliably in the headset.

## Acceptance criteria
- [ ] Creating/renaming opens a near-field keyboard panel with the name field focused
- [ ] Typed text live-mirrors onto the in-world SDF label so I see the result land in place
- [ ] Enter commits, Esc commits a deduped default name, Tab commits and starts the next node in the same parent
- [ ] Voice-to-text is offered as a convenience but the keyboard path works without it

## Notes
Implements authoring-ux 3.5 / feasibility A2-A3; near-field panel is the required VR input surface.
