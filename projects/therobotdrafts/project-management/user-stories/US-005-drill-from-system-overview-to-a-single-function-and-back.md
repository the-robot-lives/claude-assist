---
id: US-005
persona: P-001
persona_slug: trd-systems-architect
title: "Drill from system overview to a single function and back"
epic: "Bubble navigation & orientation"
priority: P0
segment: primary
tags: [drill, zoom, level-of-detail, spatial-memory]
---

# US-005 — Drill from system overview to a single function and back

**As** Dana, the Systems Architect,
**I want** zoom and drill from the whole-system view down to one function and return without losing my place,
**so that** I keep a stable mental map while inspecting detail.

## Acceptance criteria
- [ ] Drill-in (scroll-in/Enter) descends into a container; drill-out returns to the exact prior framing
- [ ] A breadcrumb shows the current containment path (system > service > class > method)
- [ ] Hierarchical level-of-detail reveals members only as you approach; the overview stays uncluttered
- [ ] Drilling into an empty container shows a 'no children' state rather than an empty void

## Notes
Realizes the README 'zoom from overview to a single function and back without losing your place' promise.
