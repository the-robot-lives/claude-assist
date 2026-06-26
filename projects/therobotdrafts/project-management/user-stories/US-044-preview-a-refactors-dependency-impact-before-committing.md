---
id: US-044
persona: P-003
persona_slug: trd-tech-lead
title: "Preview a refactor's dependency impact before committing"
epic: "Authoring (add/connect/edit/re-parent)"
priority: P1
segment: secondary
tags: [impact-preview, refactor, planning, dependencies]
---

# US-044 — Preview a refactor's dependency impact before committing

**As** Priya, the tech lead,
**I want** preview the dependency impact of a proposed move/split before I commit to it,
**so that** I can plan a refactor by seeing impact and dependencies first.

## Acceptance criteria
- [ ] Selecting a proposed change (re-parent/split) shows which dependencies would be added, removed, or cross a boundary
- [ ] The impact is summarized as counts and a navigable list
- [ ] I can discard the preview to leave the model unchanged
- [ ] A change with no dependency impact reports that explicitly rather than an empty preview

## Notes
Serves Priya goal 3 (plan refactors by seeing impact first); shares machinery with Dana US-018.
