---
id: US-052
persona: P-004
persona_slug: trd-reverse-engineer
title: "Trace every path that reaches a sensitive module"
epic: "Bubble navigation & orientation"
priority: P0
segment: secondary
tags: [tracing, attack-surface, crypto, paths]
---

# US-052 — Trace every path that reaches a sensitive module

**As** Sven, the reverse engineer,
**I want** trace every call path that reaches a sensitive module like crypto,
**so that** I can focus on the parts that matter for an audit without reconstructing the whole structure.

## Acceptance criteria
- [ ] Selecting a target module reveals all inbound paths that reach it, transitively
- [ ] Each distinct path is enumerated and individually focusable
- [ ] Path nodes crossing a trust/artifact boundary are marked
- [ ] When the module is unreachable from the selected scope the trace says so explicitly

## Notes
Serves Sven's SDK-audit scenario (trace every path touching crypto) and goal 3.
