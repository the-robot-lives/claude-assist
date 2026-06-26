---
id: P-008
name: "ARIA (Automation Agent)"
slug: "automation-agent"
archetype: "LLM / CI Automation Actor"
segment: "edge-case"
tags: [agent, llm, automation, ci, headless, api, non-human]
---

# ARIA — LLM / CI Automation Actor

## Demographics

| Field | Value |
|-------|-------|
| **Age** | n/a (software actor) |
| **Role** | Automated agent / CI pipeline integration |
| **Technical Level** | Expert (programmatic) |
| **Industry** | DevOps / AI tooling |
| **Location** | Runs in CI and on developer machines |

## Bio

ARIA is not a person — it's the LLM-backed automation and CI integration that uses The Robot Draft programmatically. It imports code to keep models current, generates and overlays code from model edits, and exports artifacts for pipelines and documentation. It needs stable contracts, predictable failure, and no human-only UI gates.

## Goals

1. Keep models continuously in sync with code on every commit
2. Generate or surgically overlay source from model changes deterministically
3. Export diagrams/artifacts headlessly for docs and review pipelines

## Frustrations

1. Features locked behind right-click GUI with no programmatic path
2. Silent or ephemeral errors that a pipeline can't detect
3. Long operations with no cancellation, timeout, or progress contract

## Behaviors

- Calls the same import/codegen/export paths the GUI does, but headlessly
- Needs machine-readable status and exit codes
- Respects rate limits and configured endpoints

## Job to Be Done

> "When code changes in CI, I want to re-derive the model and regenerate artifacts headlessly with reliable success/failure signals, so the model and docs never drift from the code."

## Relationship to Product

ARIA is the automation actor the LLM/codegen surface implies. It values an API/headless mode, deterministic codegen, structured errors, cancellation/timeouts, and config via env/secret not just PlayerPrefs. It "churns" (gets disabled) if it can't run without a human clicking.

## Scenarios

1. **CI re-model** — On merge, ARIA re-imports changed files, updates the model, and fails the build if structure violates a rule.
2. **Doc export** — Nightly, ARIA exports current diagrams to SVG/PlantUML for the docs site.
