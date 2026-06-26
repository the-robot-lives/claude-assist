---
id: US-062
persona: P-005
persona_slug: trd-legacy-modeler
title: "Import an EA native repository"
epic: "Interchange (XMI/Rose/EA/PlantUML import-export)"
priority: P1
segment: secondary
tags: [enterprise-architect, ea, repository, import]
---

# US-062 — Import an EA native repository

**As** Robert, the enterprise UML modeler,
**I want** import a Sparx EA native repository,
**so that** I can evaluate the tool against the EA models my org actually uses.

## Acceptance criteria
- [ ] An EA repository imports its packages, diagrams, elements, and connectors
- [ ] EA stereotypes and custom properties are preserved as model metadata
- [ ] An import report summarizes coverage and flags unmapped EA-specific features
- [ ] Connecting to an inaccessible/locked repository reports a clear error instead of a partial silent import

## Notes
Serves Robert's EA-migrant archetype; full interchange is his churn condition.
