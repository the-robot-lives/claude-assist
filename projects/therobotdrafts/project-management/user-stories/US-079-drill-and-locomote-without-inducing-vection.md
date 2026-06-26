---
id: US-079
persona: P-006
persona_slug: trd-vr-explorer
title: "Drill and locomote without inducing vection"
epic: "VR & comfort"
priority: P1
segment: secondary
tags: [locomotion, teleport, drill, vection]
---

# US-079 — Drill and locomote without inducing vection

**As** Aiko, the VR/XR power user,
**I want** drill into containers and move through the model with comfortable, vection-free locomotion,
**so that** exploring deep structures doesn't make me queasy.

## Acceptance criteria
- [ ] Drill-in uses push-in/teleport-in rather than a long smooth dolly
- [ ] Locomotion options include teleport and a comfort-mode smooth move with vignette
- [ ] Drill transitions are bounded (<=300ms ease) and keep the parent framed/parafoveal
- [ ] A large re-pack ripple after an edit animates only the affected subtree, with fade-through for big displacements

## Notes
Implements feasibility A1 comfort caveats and the VR drill idiom; serves Aiko goal 1 (comfortable exploration).
