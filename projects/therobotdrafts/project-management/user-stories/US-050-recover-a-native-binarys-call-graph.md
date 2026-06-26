---
id: US-050
persona: P-004
persona_slug: trd-reverse-engineer
title: "Recover a native binary's call graph"
epic: "Ingestion & reverse-engineering"
priority: P1
segment: secondary
tags: [ghidra, native, call-graph, binary]
---

# US-050 — Recover a native binary's call graph

**As** Sven, the reverse engineer,
**I want** load a native binary and explore its recovered call graph,
**so that** I can locate the interesting code (e.g. a parser) in a stripped binary spatially.

## Acceptance criteria
- [ ] Importing a native binary runs a native decompiler (Ghidra) and yields recovered functions and call edges
- [ ] Recovered functions render as bubbles with call relationships traceable like source
- [ ] Functions without recovered names get stable synthetic identifiers
- [ ] If symbol/section recovery is partial, the model marks low-confidence regions instead of presenting them as certain

## Notes
Serves Sven's native-dive scenario (P-004 scenario 2); extends ingestion to native artifacts.
