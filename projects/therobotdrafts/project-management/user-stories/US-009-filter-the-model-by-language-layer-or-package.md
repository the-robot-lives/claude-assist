---
id: US-009
persona: P-001
persona_slug: trd-systems-architect
title: "Filter the model by language, layer, or package"
epic: "Search & filter"
priority: P1
segment: primary
tags: [filter, scope, layers, declutter]
---

# US-009 — Filter the model by language, layer, or package

**As** Dana, the Systems Architect,
**I want** filter the visible model by language, architectural layer, or package,
**so that** I can isolate the slice of a huge system I'm reasoning about.

## Acceptance criteria
- [ ] Filter controls let me show/hide by language, by package prefix, and by a layer tag
- [ ] Filtered-out nodes are removed or dimmed consistently, and edges to hidden nodes are bundled, not dangling
- [ ] Active filters are shown as removable chips so the current scope is legible
- [ ] Clearing all filters restores the full model in one action

## Notes
Addresses Dana's frustration that flat 2D tools don't scale (P-001 frustration 2); declutter for large repos.
