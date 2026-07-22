---
id: US-058
title: "See a ranked top-K shortlist of path outcomes"
slug: see-a-ranked-top-k-shortlist-of-path-outcomes
personas: [P-001, P-003]
epic: "Review & Reward"
priority: must-have
complexity: medium
tags: [reviewer-agent, shortlist, path-execution]
---

# US-058: See a Ranked Top-K Shortlist of Path Outcomes

## User Story

**As a** staff engineer (Devon Reyes) launching parallel-path runs with a large path cap
**I want to** see only the top-K graded outcomes surfaced to me, ranked by Reviewer score
**So that** I can pick a winner quickly without wading through every low-scoring path

## Acceptance Criteria

- **Given** a run with more completed paths than the configured shortlist size K
  **When** grading finishes
  **Then** the UI surfaces exactly the top-K paths ordered by grade score, with the remaining paths still accessible on request but not shown by default

- **Given** two paths with tied grade scores at the K-th cutoff
  **When** the shortlist is built
  **Then** both tied paths are included (the list may exceed K by the tie count rather than arbitrarily dropping one)

- **Given** a team lead (Sam Okafor) who wants a wider or narrower shortlist for a specific run
  **When** they set the shortlist size K for that run
  **Then** the override applies only to that run, and future runs default back to the project-level K setting

## Notes
K is a project-level default with a per-run override, similar to the existing path-cap setting. Shortlist is the direct input to the comparison view in [[US-059]].
