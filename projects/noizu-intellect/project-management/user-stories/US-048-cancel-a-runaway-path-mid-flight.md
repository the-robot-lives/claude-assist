---
id: US-048
title: "Cancel a runaway path mid-flight"
slug: cancel-a-runaway-path-mid-flight
personas: [P-001]
epic: "Parallel-Path Execution"
priority: must-have
complexity: medium
tags: [cancel, path-control, budget, safety]
---

# US-048: Cancel a Runaway Path Mid-Flight

## User Story

**As a** solo staff engineer
**I want to** cancel a single path that's spiraling — looping, off-topic, or burning budget with no useful progress — without stopping the rest of the run
**So that** I can stop the bleeding on one bad path while letting the paths that are working keep going

## Acceptance Criteria

- **Given** a path is running and I judge it a runaway (repeated similar turns, off-task, or nearing its spend cap uselessly)
  **When** I click cancel on that path
  **Then** the path's GenServer terminates after its current in-flight LLM call completes (never mid-request), its status is set to "cancelled" (a terminal state distinct from "failed"), and no further turns are scheduled for it

- **Given** a path is cancelled
  **When** I later view the run
  **Then** the cancelled path's full turn history remains visible and included in the execution tree (US-052) and any turn-by-turn comparison (US-054), marked clearly as cancelled rather than being deleted

- **Given** a path is cancelled
  **When** the Reviewer's grading step runs over the run's completed paths
  **Then** the cancelled path is excluded from grading and cannot be picked as the winner, but is retained for post-hoc analysis of why it went wrong

- **Given** I cancel a path
  **When** sibling paths are still running
  **Then** they are entirely unaffected — no shared state, checkpoint, or resource is invalidated by one path's cancellation

## Notes
Cancellation is one-way and terminal, unlike pause (US-047). "Current call completes, no mid-request kill" avoids leaving a provider-side request in an undefined state and keeps token accounting accurate. This is a safety-critical control for a system whose whole premise is fanning out concurrent, potentially expensive agent turns.
