---
id: US-025
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Recenter to recover from being lost in space"
epic: "Bubble navigation & orientation"
priority: P0
segment: primary
tags: [recenter, recovery, orientation, control]
---

# US-025 — Recenter to recover from being lost in space

**As** Marcus, the newly-onboarding engineer,
**I want** have a reliable one-press recenter when I've flown into empty space,
**so that** I'm never stranded staring into black with all nodes behind me.

## Acceptance criteria
- [ ] A single command returns the camera to a view where the model is visible and framed
- [ ] Recenter works from any camera position or orientation, including upside-down
- [ ] An on-screen control (not just a hotkey) performs recenter
- [ ] Recenter is bounded/comfort-friendly motion, not an instant teleport that disorients

## Notes
Counters UX-review P0-3 directly; Marcus churns if the empty state/orientation confuses him (P-002 relationship).
