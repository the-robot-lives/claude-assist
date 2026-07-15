---
id: US-040
title: "Review and edit the Planner's path breakdown before launch"
slug: review-and-edit-the-planners-path-breakdown-before-launch
personas: [P-001]
epic: "Parallel-Path Execution"
priority: should-have
complexity: medium
tags: [planner, decomposition, editing, human-in-the-loop]
---

# US-040: Review and Edit the Planner's Path Breakdown Before Launch

## User Story

**As a** solo staff engineer
**I want to** edit the Planner's proposed path breakdown — rename a path's approach, drop one, merge two, or add my own — before any path is launched
**So that** I don't burn budget on paths I already know are dead ends, and can steer the run toward the comparisons I actually care about

## Acceptance Criteria

- **Given** the Planner has proposed a breakdown of N candidate paths
  **When** I remove one candidate and edit the rationale text on another
  **Then** the breakdown updates in place as a new version of the proposal message, and the Planner does not re-run its Plan pass unless I explicitly ask it to reconsider

- **Given** I add a path the Planner didn't propose, specifying its own approach description
  **When** I save the edit
  **Then** the added path is included in the launch set with the same shared base checkpoint as the others, and is visually marked as human-authored rather than Planner-authored

- **Given** I edit the breakdown
  **When** the edit exceeds my configured per-run path cap (see US-041)
  **Then** the UI blocks launch and tells me which cap is violated rather than silently truncating my edits

- **Given** I've finalized my edits
  **When** I click launch
  **Then** the exact edited breakdown (not the original proposal) is what US-044 forks into concurrent paths, and the diff between original and edited breakdown is retained for later review

## Notes
Editing happens on the versioned proposal message, consistent with the platform's "every mutable text is a versioned row" rule — this gives Devon (and later Mara/Elias) an audit trail of how much human steering shaped each run, which matters for the reward back-propagation story eventually.
