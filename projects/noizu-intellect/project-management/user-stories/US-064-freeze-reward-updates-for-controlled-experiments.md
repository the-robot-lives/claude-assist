---
id: US-064
title: "Freeze reward updates for controlled experiments"
slug: freeze-reward-updates-for-controlled-experiments
personas: [P-005]
epic: "Review & Reward"
priority: could-have
complexity: medium
tags: [decision-weights, experiment-control, freeze]
---

# US-064: Freeze Reward Updates for Controlled Experiments

## User Story

**As a** researcher (Dr. Elias Thorn) comparing planner behavior across experimental conditions
**I want to** freeze the decision-weight store so picks stop updating weights
**So that** I can run repeated trials against a fixed planning policy without the weights drifting between trials

## Acceptance Criteria

- **Given** a project or run scope
  **When** I enable the reward-freeze toggle
  **Then** all subsequent picks still record grades, rationale, and decision history as normal, but no decision-weight updates ([[US-062]]) are applied while frozen

- **Given** a frozen decision-weight store
  **When** I inspect it
  **Then** the UI/API clearly indicates the store is frozen and since when, so I don't mistake a stalled weight trajectory for a bug

- **Given** a frozen store
  **When** I unfreeze it
  **Then** normal back-propagation resumes for picks made after the unfreeze point; picks made while frozen are not retroactively applied unless I explicitly request a backfill

## Notes
Scoped per-project (not global) so one researcher's experiment doesn't silently disable learning for other projects on a shared self-hosted instance. Backfill-on-unfreeze is explicitly out of scope for the default flow — flagged as an edge case, not built by default.
