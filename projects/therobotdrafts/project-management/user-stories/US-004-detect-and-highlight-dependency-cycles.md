---
id: US-004
persona: P-001
persona_slug: trd-systems-architect
title: "Detect and highlight dependency cycles"
epic: "Bubble navigation & orientation"
priority: P1
segment: primary
tags: [cycles, coupling, analysis, highlight]
---

# US-004 — Detect and highlight dependency cycles

**As** Dana, the Systems Architect,
**I want** have the tool find dependency cycles and highlight the elements involved,
**so that** I can spot circular coupling that I'd otherwise miss by eye.

## Acceptance criteria
- [ ] A 'find cycles' action scans the current region and lists each detected cycle
- [ ] Selecting a cycle highlights its member nodes and the edges that close the loop
- [ ] Cycles are encoded with shape/label in addition to color so they read in monochrome
- [ ] When no cycles exist the result panel says so explicitly rather than showing an empty list

## Notes
Supports Dana's 'why is this coupled to that' investigations (P-001 bio); uses non-color-only encoding (design-conventions redundancy).
