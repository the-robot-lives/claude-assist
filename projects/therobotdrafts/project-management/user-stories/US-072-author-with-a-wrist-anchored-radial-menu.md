---
id: US-072
persona: P-006
persona_slug: trd-vr-explorer
title: "Author with a wrist-anchored radial menu"
epic: "VR & comfort"
priority: P0
segment: secondary
tags: [radial-menu, vr-authoring, wrist-anchored, parity]
---

# US-072 — Author with a wrist-anchored radial menu

**As** Aiko, the VR/XR power user,
**I want** summon a wrist-anchored radial menu to run all authoring verbs in VR,
**so that** I can add, connect, delete, drill, and project without a keyboard.

## Acceptance criteria
- [ ] The controller menu button summons a hand-anchored, billboarded radial with the authoring verbs
- [ ] Ring-1 has <=6 sectors selectable by thumbstick direction + trigger or ray-flick; depth is capped at 2
- [ ] Ring-2 kind/edge/notation rings use ray-pick (not thumbstick) with a vertical-list fallback past 8 items
- [ ] B-button cancels any in-progress verb and returns to Select; the user is never trapped in a mode

## Notes
Implements authoring-ux 2.3 and feasibility F1/F2; serves Aiko's headset-fly-through scenario and parity goal.
