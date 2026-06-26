---
id: US-006
persona: P-001
persona_slug: trd-systems-architect
title: "Project a subsystem region to a UML component diagram"
epic: "Diagram coverage & projection-to-2D"
priority: P0
segment: primary
tags: [projection, uml, component-diagram, handoff]
---

# US-006 — Project a subsystem region to a UML component diagram

**As** Dana, the Systems Architect,
**I want** select a region of the model and project it into a standard UML component diagram,
**so that** I can produce an authoritative architecture view to hand to teams.

## Acceptance criteria
- [ ] Selecting a region and invoking Project->2D offers UML component among the notation choices
- [ ] The projection is derived live from the current model, reflecting the latest ingest
- [ ] Component boundaries, provided/required interfaces, and connectors render per UML 2.5.1 notation
- [ ] Projecting an empty or invalid region surfaces a clear reason instead of a blank diagram

## Notes
Serves Dana's review-handoff scenario (P-001 scenario 2); Project->2D is the spec's Output-group verb.
