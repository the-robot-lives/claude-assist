---
id: US-051
persona: P-004
persona_slug: trd-reverse-engineer
title: "Unify mixed artifact types into one code-graph"
epic: "Ingestion & reverse-engineering"
priority: P1
segment: secondary
tags: [unified-graph, mixed-artifacts, cross-reference, polyglot]
---

# US-051 — Unify mixed artifact types into one code-graph

**As** Sven, the reverse engineer,
**I want** import IL, JVM bytecode, and native artifacts together into one unified model,
**so that** I can follow cross-references across artifact boundaries instead of three disconnected piles.

## Acceptance criteria
- [ ] Multiple artifact types ingested into one project resolve into a single unified code-graph
- [ ] Cross-artifact references (e.g. a native shim called from bytecode) are linked where resolvable
- [ ] Each node records which decompiler/artifact it came from
- [ ] Unresolved cross-artifact references are shown as dangling-with-reason, not dropped

## Notes
Counters Sven's frustration 2 (switching between three decompilers) and values the unified code-graph.
