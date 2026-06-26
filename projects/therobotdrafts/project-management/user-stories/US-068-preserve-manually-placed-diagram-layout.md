---
id: US-068
persona: P-005
persona_slug: trd-legacy-modeler
title: "Preserve manually-placed diagram layout"
epic: "Authoring (add/connect/edit/re-parent)"
priority: P2
segment: secondary
tags: [layout-preservation, manual-placement, diagrams, interchange]
---

# US-068 — Preserve manually-placed diagram layout

**As** Robert, the enterprise UML modeler,
**I want** keep the manual layout of imported diagrams instead of having auto-layout move everything,
**so that** my carefully placed elements don't get scrambled on import.

## Acceptance criteria
- [ ] Imported diagram layouts (where the source carries coordinates) are preserved in the 2D projection
- [ ] Auto-layout is opt-in, never applied silently to imported diagrams
- [ ] If I do request auto-layout, I can undo back to the original placement
- [ ] Diagrams without source coordinates get a sensible default layout, flagged as auto-placed

## Notes
Counters Robert's distrust of auto-layout that moves his elements (P-005 behaviors).
