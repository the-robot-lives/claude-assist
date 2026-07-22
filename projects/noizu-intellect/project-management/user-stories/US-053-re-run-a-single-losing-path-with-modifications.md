---
id: US-053
title: "Re-run a single losing path with modifications"
slug: re-run-a-single-losing-path-with-modifications
personas: [P-005]
epic: "Parallel-Path Execution"
priority: could-have
complexity: medium
tags: [re-run, losing-path, modification, experiment]
---

# US-053: Re-Run a Single Losing Path With Modifications

## User Story

**As a** researcher
**I want to** take a losing (non-picked) path from a completed run and re-run it from its own fork point with a targeted modification — a different model, an edited prompt, or an added instruction
**So that** I can isolate whether the loss was caused by the path's approach or by a specific, fixable variable, without re-running the entire multi-path decomposition

## Acceptance Criteria

- **Given** a completed run where a path was graded but not picked
  **When** I select "re-run with modifications" on that path
  **Then** the system checks out a fresh thread from that path's own origin tag (not the run's shared base), pre-filled with the same approach rationale, and opens it for edits

- **Given** I'm editing the re-run before launch
  **When** I change the model strategy (US-045), edit an agent's turn-triggering instruction, or adjust the assigned agent set
  **Then** the modification is recorded as a diff against the original losing path, so later comparison (US-054) can attribute outcome differences to the specific change

- **Given** I launch the modified re-run
  **When** it completes
  **Then** it produces its own normalized outcome record (US-051) and is linked to the original losing path as a "retry of" relationship, without altering the original run's history or its already-recorded grade

- **Given** the re-run path completes
  **When** the Reviewer grades it
  **Then** it can be picked independently, even though the run it originated from already had a different winner selected

## Notes
This keeps Elias's experiments cheap and targeted — re-running one path rather than the whole N-path decomposition — while preserving reproducibility: the origin tag guarantees the retry starts from the identical context the original losing path did, isolating the variable under test.
