---
id: US-067
persona: P-005
persona_slug: trd-legacy-modeler
title: "Get a fidelity report of dropped elements on import"
epic: "Interchange (XMI/Rose/EA/PlantUML import-export)"
priority: P1
segment: secondary
tags: [fidelity-report, import, coverage, transparency]
---

# US-067 — Get a fidelity report of dropped elements on import

**As** Robert, the enterprise UML modeler,
**I want** see an explicit fidelity report after any import listing what didn't map,
**so that** I can trust the tool because it tells me exactly what it couldn't represent.

## Acceptance criteria
- [ ] Every import produces a report: elements read, mapped, partially mapped, and dropped
- [ ] Each unmapped item lists its source identifier and the reason
- [ ] The report is exportable for the record
- [ ] A fully clean import states '100% mapped' explicitly rather than showing an empty report

## Notes
Directly answers Robert's distrust that interchange silently drops detail (frustration 2).
