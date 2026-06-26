---
id: US-070
persona: P-005
persona_slug: trd-legacy-modeler
title: "Export Mermaid and DOT for lightweight sharing"
epic: "Interchange (XMI/Rose/EA/PlantUML import-export)"
priority: P2
segment: secondary
tags: [mermaid, dot, export, lightweight]
---

# US-070 — Export Mermaid and DOT for lightweight sharing

**As** Robert, the enterprise UML modeler,
**I want** export a diagram to Mermaid and DOT text,
**so that** I can share a quick structure snippet with people who don't run EA.

## Acceptance criteria
- [ ] A projected diagram exports to valid Mermaid and to Graphviz DOT
- [ ] The export covers the visible elements and relationships
- [ ] Text outputs are offered for copy and save
- [ ] Constructs not expressible in the target format are reported rather than emitted as broken syntax

## Notes
Broadens Robert's outbound interchange to lightweight formats; complements XMI/Rose round-trip.
