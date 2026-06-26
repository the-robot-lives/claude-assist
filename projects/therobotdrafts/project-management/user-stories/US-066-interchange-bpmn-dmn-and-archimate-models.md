---
id: US-066
persona: P-005
persona_slug: trd-legacy-modeler
title: "Interchange BPMN, DMN, and ArchiMate models"
epic: "Interchange (XMI/Rose/EA/PlantUML import-export)"
priority: P2
segment: secondary
tags: [bpmn, dmn, archimate, exchange-xml]
---

# US-066 — Interchange BPMN, DMN, and ArchiMate models

**As** Robert, the enterprise UML modeler,
**I want** import and export BPMN, DMN, and ArchiMate via their exchange XML,
**so that** non-UML notations my org uses also survive interchange.

## Acceptance criteria
- [ ] BPMN 2.0, DMN, and ArchiMate exchange XML import into the model and project back to their notations
- [ ] Export produces valid exchange XML for each
- [ ] An interchange report flags any constructs that don't round-trip cleanly
- [ ] An invalid exchange file reports the parse error and location rather than importing partial garbage

## Notes
Extends interchange breadth (README diagram families) for Robert's multi-notation process.
