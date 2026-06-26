---
id: US-008
persona: P-001
persona_slug: trd-systems-architect
title: "Search a type by qualified name and focus it"
epic: "Search & filter"
priority: P0
segment: primary
tags: [search, focus, qualified-name, navigation]
---

# US-008 — Search a type by qualified name and focus it

**As** Dana, the Systems Architect,
**I want** search for a type by its qualified name and have the view focus it,
**so that** I can jump straight to the element under discussion in a review.

## Acceptance criteria
- [ ] A search field (Ctrl/Cmd+F twin or dedicated) matches on qualified and simple names with type-ahead
- [ ] Selecting a result focuses and frames that node, expanding any collapsed parents on the path
- [ ] Matching nodes are highlighted using the reserved non-kind state channel, not a kind hue
- [ ] A no-match query shows a 'no results' message, not a silent empty frame

## Notes
Supports goal-directed navigation; pairs with US-026 (Marcus) but architect-scoped to qualified names across services.
