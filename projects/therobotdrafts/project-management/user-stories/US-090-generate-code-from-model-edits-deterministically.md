---
id: US-090
persona: P-008
persona_slug: trd-automation-agent
title: "Generate code from model edits deterministically"
epic: "Code round-trip & LLM codegen"
priority: P0
segment: edge-case
tags: [codegen, deterministic, round-trip, headless]
---

# US-090 — Generate code from model edits deterministically

**As** ARIA, the automation agent,
**I want** generate or surgically overlay source from model changes deterministically and headlessly,
**so that** the same model edit always produces the same code, safe to run in a pipeline.

## Acceptance criteria
- [ ] Deterministic skeleton codegen runs without an LLM and produces byte-stable output for identical input
- [ ] Surgical overlay edits target only the changed region of a source file
- [ ] When an LLM refinement step is configured it is optional and its absence still yields valid skeleton code
- [ ] A failed/ambiguous generation is reported as a structured error and writes nothing, rather than a partial file

## Notes
Serves ARIA goal 2; builds on the build's deterministic-skeleton-before-LLM pattern (UX-review 'keep').
