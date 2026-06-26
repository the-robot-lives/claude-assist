---
id: US-073
persona: P-006
persona_slug: trd-vr-explorer
title: "Connect nodes in VR with ray-pick assists"
epic: "VR & comfort"
priority: P0
segment: secondary
tags: [ray-pick, magnetic-assist, dwell-confirm, connect]
---

# US-073 — Connect nodes in VR with ray-pick assists

**As** Aiko, the VR/XR power user,
**I want** draw an edge to a small deep bubble in VR with assists, not raw ray-picking,
**so that** precise connect actions aren't miserable in a dense packing.

## Acceptance criteria
- [ ] A magnetic assist snaps the ray to the nearest valid endpoint within a distance-scaled angular radius
- [ ] Dwell-to-confirm shows the resolved target highlighted before commit
- [ ] Ray stabilization (one-euro/low-pass filter) suppresses hand tremor
- [ ] Releasing on empty space cancels cleanly with no orphan edge

## Notes
Implements feasibility C1 (the gated risk); counters Aiko's frustration 2 (raw ray-picking is miserable).
