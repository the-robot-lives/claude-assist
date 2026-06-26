---
id: US-069
persona: P-005
persona_slug: trd-legacy-modeler
title: "Validate diagrams against notation standards"
epic: "Diagram coverage & projection-to-2D"
priority: P2
segment: secondary
tags: [validation, notation-lint, standards, compliance]
---

# US-069 — Validate diagrams against notation standards

**As** Robert, the enterprise UML modeler,
**I want** run a notation validation that flags non-standard or malformed constructs,
**so that** I can verify diagrams meet the standards before sign-off.

## Acceptance criteria
- [ ] A validate action checks a diagram/region against the active notation's rules
- [ ] Violations are listed with the offending element and the rule reference
- [ ] Selecting a violation focuses the element
- [ ] A fully valid diagram reports 'no violations' explicitly

## Notes
Serves Robert's meticulous standards-validation behavior (P-005 behaviors).
