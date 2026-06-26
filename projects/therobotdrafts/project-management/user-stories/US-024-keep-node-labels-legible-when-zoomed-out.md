---
id: US-024
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Keep node labels legible when zoomed out"
epic: "Performance & scale"
priority: P0
segment: primary
tags: [labels, lod, sdf, legibility]
---

# US-024 — Keep node labels legible when zoomed out

**As** Marcus, the newly-onboarding engineer,
**I want** have node labels stay readable as I zoom out across a large system,
**so that** the 'fly through a large codebase' promise actually works instead of turning labels to mush.

## Acceptance criteria
- [ ] Labels use SDF text with a 3-tier distance LOD (full card -> name-only billboard -> colored dot)
- [ ] Labels fade rather than alias as nodes recede; no fixed-raster pinpricks
- [ ] At the dot LOD, hovering or focusing a node restores its readable label
- [ ] Label LOD thresholds are tunable and never leave a mid-distance band of unreadable text

## Notes
Implements UX-review B6 / counters P0-4; the legibility fix is core to Marcus's churn condition.
