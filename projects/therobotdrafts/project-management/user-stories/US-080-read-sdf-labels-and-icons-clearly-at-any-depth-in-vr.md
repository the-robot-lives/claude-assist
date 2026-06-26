---
id: US-080
persona: P-006
persona_slug: trd-vr-explorer
title: "Read SDF labels and icons clearly at any depth in VR"
epic: "VR & comfort"
priority: P1
segment: secondary
tags: [sdf, labels, legibility, foveation]
---

# US-080 — Read SDF labels and icons clearly at any depth in VR

**As** Aiko, the VR/XR power user,
**I want** have labels and verb icons stay crisp at any depth and angle in the headset,
**so that** I can read the model in-headset instead of squinting at aliased text.

## Acceptance criteria
- [ ] Labels and verb glyphs render from an SDF atlas, billboarded and crisp at depth/angle
- [ ] Minimum stroke is >=6-8 arc-min and primary actionable wedges are ~1.2-1.5 deg so foveated rendering doesn't eat them
- [ ] A 1px dark contrast halo keeps icons readable against a busy multi-hue bubble field
- [ ] Labels never mirror-reverse when I orbit behind or rotate a node ~180 degrees

## Notes
Implements feasibility F3 and counters UX-review label/mirror issues for VR legibility; Aiko churn condition.
