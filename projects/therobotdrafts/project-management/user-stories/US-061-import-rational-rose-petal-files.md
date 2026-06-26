---
id: US-061
persona: P-005
persona_slug: trd-legacy-modeler
title: "Import Rational Rose petal files"
epic: "Interchange (XMI/Rose/EA/PlantUML import-export)"
priority: P1
segment: secondary
tags: [rose, petal, legacy, import]
---

# US-061 — Import Rational Rose petal files

**As** Robert, the enterprise UML modeler,
**I want** import my legacy Rational Rose petal files,
**so that** my institutional Rose models come forward instead of being re-modeled from scratch.

## Acceptance criteria
- [ ] Rose .mdl/.ptl files import into the unified model with classes, relationships, and diagrams
- [ ] Rose-specific notation maps to the equivalent UML 2.5.1 constructs
- [ ] An import report lists what was mapped and what Rose constructs have no modern equivalent
- [ ] A malformed or partial petal file imports what it can and reports the rest rather than failing wholesale

## Notes
Serves Robert goal 1 (bring Rose models in) and counters frustration 3 (migration = re-modeling).
