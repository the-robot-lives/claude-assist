---
id: US-014
persona: P-001
persona_slug: trd-systems-architect
title: "Compare two model versions to see structural drift"
epic: "Performance & scale"
priority: P2
segment: primary
tags: [diff, versions, drift, comparison]
---

# US-014 — Compare two model versions to see structural drift

**As** Dana, the Systems Architect,
**I want** compare the model from two ingests and see what structurally changed,
**so that** I can review how the architecture drifted between releases.

## Acceptance criteria
- [ ] Selecting two ingests produces a structural diff: added, removed, and re-parented elements and changed edges
- [ ] Changes are summarized in a list and reflected visually in the model with add/remove/changed markers
- [ ] I can filter the diff to a region or package
- [ ] Comparing two identical ingests reports 'no structural changes' rather than an empty diff view

## Notes
Extends the live-model value for architecture review across releases; advanced, hence P2.
