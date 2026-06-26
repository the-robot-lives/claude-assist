---
id: US-007
persona: P-001
persona_slug: trd-systems-architect
title: "Export a projected diagram to PlantUML"
epic: "Interchange (XMI/Rose/EA/PlantUML import-export)"
priority: P1
segment: primary
tags: [export, plantuml, interchange, docs]
---

# US-007 — Export a projected diagram to PlantUML

**As** Dana, the Systems Architect,
**I want** export a projected diagram to PlantUML text,
**so that** I can drop a current architecture view into our design docs the way I already do.

## Acceptance criteria
- [ ] A projected diagram can be exported as valid PlantUML that renders to the same structure
- [ ] Export covers the elements and relationships visible in the projection, not the whole model
- [ ] The exported text is offered for copy and for save-to-file
- [ ] Exporting an unsupported notation reports which elements could not be represented rather than emitting silently-lossy output

## Notes
Matches Dana's existing 'exports PlantUML for docs' behavior (P-001 behaviors).
