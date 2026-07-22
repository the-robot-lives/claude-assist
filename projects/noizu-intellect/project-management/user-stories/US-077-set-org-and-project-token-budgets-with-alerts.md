---
id: US-077
title: "Set org/project token budgets and per-request path caps"
slug: set-org-and-project-token-budgets-with-alerts
personas: [P-006, P-009]
epic: "Admin & Platform Ops"
priority: must-have
complexity: high
tags: [budgets, quotas, alerts, parallel-paths]
---

# US-077: Set Org/Project Token Budgets and Per-Request Path Caps

## User Story

**As a** self-hosting admin/SRE
**I want to** set a monthly token budget at the org level with per-project sub-budgets and alert thresholds, plus a maximum token spend per individual solution path within a run
**So that** spend stays predictable at every level — the whole deployment, a project, and a single runaway path can't blow past what I've budgeted

## Acceptance Criteria

- **Given** I am on the budgets screen for an org
  **When** I set a monthly token cap and one or more alert thresholds (e.g. 75%, 90%, 100%)
  **Then** the cap and thresholds are saved and apply cumulatively across all projects in the org

- **Given** an org budget is set
  **When** I set a project-level sub-budget
  **Then** the system rejects sub-budgets whose sum would let a single project silently exceed the org cap, unless I explicitly mark the org cap as advisory

- **Given** cumulative token spend crosses an alert threshold
  **When** the threshold is crossed
  **Then** a notification is sent to configured admin recipients within the same evaluation cycle as the triggering turn's token accounting

- **Given** a project has a per-path token cap configured
  **When** a path's cumulative token usage across its Plan/Reply/Reflect turns reaches the cap
  **Then** that path is terminated, marked as capped (distinct from failed or graded), excluded from the Reviewer's grading pool, and the run's other paths continue unaffected

- **Given** a budget is fully exhausted at any level (org, project, or path)
  **When** a new path execution would consume tokens against it
  **Then** the run is blocked or the offending path is capped with a clear budget-exceeded error, not silently degraded

## Notes
Rosa (P-009) cares about this at personal/hobbyist scale — the same mechanic should work for a single-project self-host with a tiny budget as it does for a multi-project org. The per-path cap protects the core parallel-path mechanic itself (N concurrent sub-conversations forking from a shared checkpoint) from one branch's cost blowing out the whole decomposition. Pairs with [[US-078]] for the reporting view that shows where spend actually went.
