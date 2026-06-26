---
id: US-018
persona: P-001
persona_slug: trd-systems-architect
title: "Re-parent a module in-model and preview the impact"
epic: "Authoring (add/connect/edit/re-parent)"
priority: P2
segment: primary
tags: [re-parent, refactor, impact-preview, authoring]
---

# US-018 — Re-parent a module in-model and preview the impact

**As** Dana, the Systems Architect,
**I want** re-parent a module into a different package in the model and preview the dependency impact,
**so that** I can evaluate a refactor's blast radius before touching code.

## Acceptance criteria
- [ ] Re-parent is a drag-into-container gesture; the packer re-packs both old and new parents (no free-positioning)
- [ ] Before committing, an impact preview lists edges that would cross newly or differently
- [ ] The re-parent is a single undo step
- [ ] An illegal containment (per the active notation) shows the invalid affordance during the drag and is refused on drop

## Notes
Aligns with authoring-ux 3.6 (re-parent is the only move); gives Dana refactor-planning value without yet round-tripping code.
