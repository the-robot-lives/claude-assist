---
id: US-017
persona: P-001
persona_slug: trd-systems-architect
title: "Export a high-resolution render of a region"
epic: "Interchange (XMI/Rose/EA/PlantUML import-export)"
priority: P1
segment: primary
tags: [export, svg, png, render]
---

# US-017 — Export a high-resolution render of a region

**As** Dana, the Systems Architect,
**I want** export a clean high-resolution SVG/PNG render of the selected region,
**so that** I can paste an authoritative picture into a stakeholder deck or doc.

## Acceptance criteria
- [ ] Export produces SVG and PNG of the current region at a chosen resolution
- [ ] Labels in the export are legible at the chosen size (vector text for SVG)
- [ ] The export respects active filters/overlays so it matches what I see on screen
- [ ] Exporting an empty selection prompts me to select a region rather than emitting a blank image

## Notes
Supports the review-handoff scenario; pairs with US-007 (PlantUML) for image vs text outputs.
