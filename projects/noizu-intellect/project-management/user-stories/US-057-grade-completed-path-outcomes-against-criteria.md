---
id: US-057
title: "Grade completed path outcomes against criteria"
slug: grade-completed-path-outcomes-against-criteria
personas: [P-005, P-001]
epic: "Review & Reward"
priority: must-have
complexity: high
tags: [reviewer-agent, grading, path-execution]
---

# US-057: Grade Completed Path Outcomes Against Criteria

## User Story

**As a** researcher (Dr. Elias Thorn) running repeatable parallel-path experiments
**I want to** have a Reviewer agent automatically grade each completed path's outcome against the plan's stated success criteria
**So that** I get a consistent, auditable score for every path without having to manually re-read every transcript

## Acceptance Criteria

- **Given** a parallel-path run where all N paths have reached a terminal state (completed, failed, or timed out)
  **When** the Reviewer agent runs its grading pass
  **Then** it produces a structured grade record per path (score, rubric breakdown, rationale text) tied to that path's outcome and the plan's original success criteria

- **Given** a path that failed or was abandoned mid-execution
  **When** grading runs
  **Then** the path still receives a grade record (e.g. score 0 with a "did not complete" rationale) rather than being silently omitted from the comparison set

- **Given** a completed path with an incomplete or ambiguous success criterion in the plan
  **When** the Reviewer agent grades it
  **Then** the grade record flags the ambiguity explicitly rather than fabricating a confident score

## Notes
Grading runs as a distinct pass after path execution, separate from the per-path Plan → Reply → Reflect turn pipeline. Grade records should be versioned content so re-grading (e.g. after rubric changes) is diffable. Feeds directly into [[US-058]] (ranked shortlist) and is a prerequisite for reward back-propagation ([[US-062]]).
