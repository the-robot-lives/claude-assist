---
id: US-001
persona: P-001
persona_slug: trd-systems-architect
title: "Reverse-engineer a monorepo into a bubble model"
epic: "Ingestion & reverse-engineering"
priority: P0
segment: primary
tags: [ingestion, reverse-engineering, multi-language, import]
---

# US-001 — Reverse-engineer a monorepo into a bubble model

**As** Dana, the Systems Architect,
**I want** point the tool at my multi-language monorepo and have it reverse-engineer the whole repo into a unified bubble model,
**so that** I can see the system's current structure derived from code instead of a stale diagram.

## Acceptance criteria
- [ ] Selecting a repo root ingests source via the compiler-grade frontends (Roslyn/Clang/JDT/TS/go-types) and produces packages, types, and functions as nested bubbles
- [ ] Mixed languages in one repo resolve into a single unified code-graph, not one silo per language
- [ ] A progress indicator shows files processed and remaining; the import is cancellable mid-run
- [ ] If a file fails to parse, ingestion continues and the failure is recorded in a dismissible error surface rather than aborting the whole import

## Notes
Addresses Dana's core JTBD of seeing live structure derived from code (P-001 goal 1); first link in the ingestion->model pipeline.
