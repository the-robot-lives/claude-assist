---
id: US-016
persona: P-001
persona_slug: trd-systems-architect
title: "Project a deployment diagram of services"
epic: "Diagram coverage & projection-to-2D"
priority: P2
segment: primary
tags: [deployment-diagram, uml, projection, topology]
---

# US-016 — Project a deployment diagram of services

**As** Dana, the Systems Architect,
**I want** project the service topology into a UML deployment diagram,
**so that** I can communicate the runtime shape of the system, not just its classes.

## Acceptance criteria
- [ ] A region of services projects to a UML deployment diagram with nodes and artifacts
- [ ] Communication paths between deployment nodes render per UML notation
- [ ] The diagram is derived from the current model and exportable like other projections
- [ ] Services lacking deployment metadata are shown as undeployed rather than omitted silently

## Notes
Extends diagram coverage (README: deployment among supported types) for stakeholder communication.
