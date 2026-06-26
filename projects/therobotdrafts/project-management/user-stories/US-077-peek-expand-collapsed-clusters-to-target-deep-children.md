---
id: US-077
persona: P-006
persona_slug: trd-vr-explorer
title: "Peek-expand collapsed clusters to target deep children"
epic: "VR & comfort"
priority: P1
segment: secondary
tags: [peek-expand, hlod, dense-clusters, targeting]
---

# US-077 — Peek-expand collapsed clusters to target deep children

**As** Aiko, the VR/XR power user,
**I want** have a collapsed cluster peek-expand when my ray rests on it so I can target a child inside,
**so that** deep targets stay reachable without permanently exploding the view.

## Acceptance criteria
- [ ] Ray-resting on a collapsed HLOD proxy temporarily peek-expands it to reveal children
- [ ] Only one proxy peeks at a time; child upload is amortized to stay within budget
- [ ] Moving the ray away re-collapses with hysteresis so a wobbling ray doesn't strobe expand/collapse
- [ ] A quick release on the proxy itself attaches to the container, a legal package-level edge

## Notes
Implements authoring-ux 4.5 and feasibility C2; essential for connect in dense packings.
