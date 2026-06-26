---
id: US-071
persona: P-006
persona_slug: trd-vr-explorer
title: "Fly through a system in VR at frame budget"
epic: "VR & comfort"
priority: P0
segment: secondary
tags: [vr, frame-rate, fly-through, comfort]
---

# US-071 — Fly through a system in VR at frame budget

**As** Aiko, the VR/XR power user,
**I want** fly through a large system in VR holding the headset frame budget,
**so that** the spatial metaphor pays off instead of dropping frames and making me sick.

## Acceptance criteria
- [ ] A large graph sustains 90fps (or the 72fps Quest budget) during fly-through with HLOD/foveation engaged
- [ ] Frame drops are avoided when dense clusters enter view; LOD degrades before frame time blows the budget
- [ ] A performance readout is available to confirm the budget is held
- [ ] If the scene can't hold budget, the tool reduces detail rather than stuttering and warns the user

## Notes
Aiko notices frame drops instantly and churns on nausea (P-006 frustrations/relationship); core VR promise.
