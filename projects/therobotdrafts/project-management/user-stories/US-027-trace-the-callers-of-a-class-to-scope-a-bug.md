---
id: US-027
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Trace the callers of a class to scope a bug"
epic: "Bubble navigation & orientation"
priority: P0
segment: primary
tags: [callers, blast-radius, tracing, scoping]
---

# US-027 — Trace the callers of a class to scope a bug

**As** Marcus, the newly-onboarding engineer,
**I want** select a class and reveal everything that calls into it,
**so that** I can scope a bug's blast radius without pestering senior engineers.

## Acceptance criteria
- [ ] A 'show callers' action reveals inbound call edges and the calling elements
- [ ] Callers are listed in a panel and each is selectable/focusable
- [ ] The trace can expand transitively one level at a time to follow the chain
- [ ] A class with no callers shows an explicit 'no callers found' state

## Notes
Implements Marcus goal 3 (stop pestering seniors) and the ticket-scoping scenario.
