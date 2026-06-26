---
id: US-078
persona: P-006
persona_slug: trd-vr-explorer
title: "Keep an edge type sticky while drawing in VR"
epic: "VR & comfort"
priority: P2
segment: secondary
tags: [sticky-type, edge-drawing, vr-rhythm, authoring]
---

# US-078 — Keep an edge type sticky while drawing in VR

**As** Aiko, the VR/XR power user,
**I want** have the edge type stay sticky in VR so I can draw a run of edges without a per-edge picker,
**so that** the drawing rhythm isn't broken by a look-away on every edge.

## Acceptance criteria
- [ ] In VR the pending edge type persists across releases (sticky-type default)
- [ ] The current type is shown as a controller/HUD badge and the picker is one button away
- [ ] Switching the pending type applies to subsequent edges until changed
- [ ] Desktop keeps draw-then-type; both modalities can do both

## Notes
Implements feasibility C3 (sticky-type is the VR default) for comfortable repeated authoring.
