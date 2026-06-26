---
id: US-010
persona: P-001
persona_slug: trd-systems-architect
title: "Re-ingest changed code to keep the model live"
epic: "Ingestion & reverse-engineering"
priority: P1
segment: primary
tags: [incremental, re-ingest, live-model, delta]
---

# US-010 — Re-ingest changed code to keep the model live

**As** Dana, the Systems Architect,
**I want** re-run ingestion after code changes and have only the changed regions update,
**so that** the model stays current without a slow full re-import and without me losing my view.

## Acceptance criteria
- [ ] Re-ingest detects changed files and updates affected bubbles incrementally
- [ ] Unchanged regions keep their position and my current framing is preserved
- [ ] Added, removed, and modified elements are briefly flagged so I can see what moved
- [ ] If a re-ingest fails partway, the model rolls back to the last consistent state rather than half-updating

## Notes
Realizes the 'always-live' thesis (README Why) and counters Dana's frustration that diagrams drift the moment code changes.
