---
id: US-063
persona: P-005
persona_slug: trd-legacy-modeler
title: "Export to XMI and round-trip diff for fidelity"
epic: "Interchange (XMI/Rose/EA/PlantUML import-export)"
priority: P0
segment: secondary
tags: [xmi, export, round-trip, fidelity-diff]
---

# US-063 — Export to XMI and round-trip diff for fidelity

**As** Robert, the enterprise UML modeler,
**I want** export a model back to XMI and diff it against the original import,
**so that** I can prove adoption is non-lossy before I commit my org to it.

## Acceptance criteria
- [ ] Exporting produces standards-valid XMI of the current model
- [ ] A round-trip diff (import -> export) reports any elements/relationships/properties that changed or were lost
- [ ] A clean round-trip reports zero loss explicitly
- [ ] Where loss is unavoidable, the diff names each affected element rather than hiding it

## Notes
Serves Robert's migration-trial scenario (export back to compare) and goal 3 (round-trip out).
