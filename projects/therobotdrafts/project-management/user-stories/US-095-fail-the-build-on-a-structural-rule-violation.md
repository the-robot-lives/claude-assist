---
id: US-095
persona: P-008
persona_slug: trd-automation-agent
title: "Fail the build on a structural rule violation"
epic: "Automation / headless / API"
priority: P2
segment: edge-case
tags: [lint-gate, rules, ci-gate, governance]
---

# US-095 — Fail the build on a structural rule violation

**As** ARIA, the automation agent,
**I want** evaluate the model against structural rules and fail the build when violated,
**so that** architectural constraints are enforced automatically in CI.

## Acceptance criteria
- [ ] A rule set (e.g. no new cycles, layer-violation bans) is evaluated against the re-modeled graph
- [ ] A violation produces a non-zero exit and a structured report of offending elements
- [ ] Rules are configurable and versionable as a file in the repo
- [ ] A clean run reports zero violations explicitly and exits success

## Notes
Serves ARIA's CI-re-model scenario (fail the build on a structure violation); governance gate, hence P2.
