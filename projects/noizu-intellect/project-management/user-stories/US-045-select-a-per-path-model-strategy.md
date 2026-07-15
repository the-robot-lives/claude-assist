---
id: US-045
title: "Select a per-path model strategy"
slug: select-a-per-path-model-strategy
personas: [P-001, P-009]
epic: "Parallel-Path Execution"
priority: could-have
complexity: medium
tags: [model-selection, fastest, cheapest, pinned, cost-control]
---

# US-045: Select a Per-Path Model Strategy

## User Story

**As a** budget hobbyist
**I want to** assign each path in a run its own model strategy — fastest, cheapest, or a specific pinned model — instead of one model for the whole run
**So that** I can run cheap/fast throwaway attempts alongside one high-quality pinned attempt without paying premium rates on every path

## Acceptance Criteria

- **Given** I am configuring paths before launch (US-040)
  **When** I set path A to `cheapest`, path B to `fastest`, and path C to a pinned model (e.g. a specific provider+model id)
  **Then** each path's agent turns resolve their model per that path's strategy independently, and the resolved model is visible on the path before any turn executes

- **Given** a path is set to `cheapest` or `fastest`
  **When** the resolution layer evaluates available providers
  **Then** it honors provider fallback rules already configured at the project level (see model management mechanics), never silently falling back to a more expensive model than the strategy implies

- **Given** a pinned model becomes unavailable mid-run (provider outage, quota exhausted)
  **When** the path's next turn is due
  **Then** the path pauses and surfaces a clear error naming the unavailable model, rather than silently substituting a different model that would break the pinned/controlled comparison

- **Given** I don't set a per-path strategy
  **When** a path launches
  **Then** it inherits the run-level default model strategy, so per-path override is opt-in, not required

## Notes
Enables Devon's "cheap breadth + one expensive control" pattern and Rosa's need to keep most paths on free/local models. Pinning matters for Elias's repeatable-experiment use case (US-053) where model identity must be held constant to isolate the effect of a prompt or path-approach change.
