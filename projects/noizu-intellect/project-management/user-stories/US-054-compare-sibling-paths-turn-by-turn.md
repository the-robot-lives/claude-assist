---
id: US-054
title: "Compare sibling paths turn-by-turn"
slug: compare-sibling-paths-turn-by-turn
personas: [P-005, P-004]
epic: "Parallel-Path Execution"
priority: could-have
complexity: medium
tags: [comparison, sibling-paths, turn-by-turn, picker]
---

# US-054: Compare Sibling Paths Turn-by-Turn

## User Story

**As a** non-technical PM acting as the human picker
**I want to** view two or more sibling paths from the same run side by side, aligned turn by turn from their shared base checkpoint
**So that** I can see exactly where their approaches diverged and make an informed pick instead of only reading each path's final answer in isolation

## Acceptance Criteria

- **Given** a run with completed sibling paths that share a base tag
  **When** I select two or more paths and open compare view
  **Then** they render side by side (or stacked, per layout), with turns aligned by turn number back to their common fork point, and the diverging turn visually highlighted

- **Given** paths have different turn counts (one finished in 3 turns, another in 7)
  **When** comparing
  **Then** the shorter path's remaining columns/rows show clearly as "no further turns" rather than misaligning against the longer path's later turns

- **Given** I'm comparing paths
  **When** I open a specific turn on either path
  **Then** I can see that turn's full Plan/Reply/Reflect content and which agent produced it, without leaving compare view

- **Given** I've reviewed the comparison
  **When** I make my pick
  **Then** the compare view state (which paths and turns I inspected) is retained alongside the pick and rationale as part of the decision history, satisfying the audit trail Priya's picker workflow depends on

## Notes
This is the primary decision-support surface for the human Picker role and doubles as Elias's tool for diagnosing why one approach out-performed another. It depends on the shared-base guarantee from US-044 (siblings truly share a fork point) and the outcome records from US-051 (final-state summaries feeding the comparison header).
