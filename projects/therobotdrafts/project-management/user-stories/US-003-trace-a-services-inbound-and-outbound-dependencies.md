---
id: US-003
persona: P-001
persona_slug: trd-systems-architect
title: "Trace a service's inbound and outbound dependencies"
epic: "Bubble navigation & orientation"
priority: P0
segment: primary
tags: [tracing, dependencies, coupling, navigation]
---

# US-003 — Trace a service's inbound and outbound dependencies

**As** Dana, the Systems Architect,
**I want** select a service bubble and reveal everything that depends on it and everything it depends on,
**so that** I can find coupling and understand why a service is a bottleneck.

## Acceptance criteria
- [ ] Selecting a node and invoking 'trace dependencies' reveals inbound and outbound edges, visually distinguished by direction
- [ ] Inbound and outbound sets can be toggled independently
- [ ] Counts (e.g. '37 inbound, 12 outbound') are shown in a detail panel
- [ ] A node with zero dependencies in a direction shows an explicit 'none' state, not a blank panel

## Notes
Directly serves Dana's coupling-audit scenario (P-001 scenario 1) and goal 2 (trace dependencies).
