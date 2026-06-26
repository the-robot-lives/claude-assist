---
id: US-049
persona: P-004
persona_slug: trd-reverse-engineer
title: "Decompile a JAR into a navigable bubble model"
epic: "Ingestion & reverse-engineering"
priority: P0
segment: secondary
tags: [decompiler, jar, bytecode, source-less]
---

# US-049 — Decompile a JAR into a navigable bubble model

**As** Sven, the reverse engineer,
**I want** import a vendored JAR and have it decompiled into bubbles I can navigate,
**so that** I can explore a dependency I have no source for without chaining decompilers by hand.

## Acceptance criteria
- [ ] Importing a JAR runs a JVM decompiler (CFR/JADX) and produces packages, classes, and methods as bubbles
- [ ] The decompiled model exposes class structure, fields, and call relationships
- [ ] Decompilation progress is shown and the operation is cancellable
- [ ] Classes that fail to decompile appear as stubs with a recorded reason rather than vanishing

## Notes
Serves Sven's SDK-audit scenario (P-004 scenario 1) and goal 1 (lift compiled artifacts).
