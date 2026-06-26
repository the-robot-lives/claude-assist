---
id: US-060
persona: P-005
persona_slug: trd-legacy-modeler
title: "Import XMI with full relationship fidelity"
epic: "Interchange (XMI/Rose/EA/PlantUML import-export)"
priority: P0
segment: secondary
tags: [xmi, import, fidelity, uml]
---

# US-060 — Import XMI with full relationship fidelity

**As** Robert, the enterprise UML modeler,
**I want** import an XMI package and have every element and relationship preserved,
**so that** I can adopt the tool without abandoning decades of modeling work.

## Acceptance criteria
- [ ] Importing standard XMI reconstructs elements, relationships, stereotypes, and tagged values
- [ ] An import summary reports counts of elements/relationships read vs mapped
- [ ] Round-trippable detail is retained on the model, not flattened to a subset
- [ ] Any element that cannot be mapped is listed explicitly rather than silently dropped

## Notes
Serves Robert's migration-trial scenario and counters his frustration 2 (XMI silently drops detail).
