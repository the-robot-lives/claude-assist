---
id: US-012
persona: P-001
persona_slug: trd-systems-architect
title: "Trace a call path across service and language boundaries"
epic: "Bubble navigation & orientation"
priority: P0
segment: primary
tags: [call-path, cross-boundary, tracing, polyglot]
---

# US-012 — Trace a call path across service and language boundaries

**As** Dana, the Systems Architect,
**I want** trace a call path that crosses service and language boundaries end to end,
**so that** I can follow how a request actually flows through the platform.

## Acceptance criteria
- [ ] Selecting a source and target reveals the call path(s) between them through the unified code-graph
- [ ] Path segments that cross a service or language boundary are visually marked
- [ ] Each hop is selectable to inspect the function at that step
- [ ] When no path exists the tool says so explicitly instead of showing a partial/misleading trace

## Notes
Core to Dana's goal 2 (trace call paths across boundaries) and the unified code-graph promise.
