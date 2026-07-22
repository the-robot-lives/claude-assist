---
id: US-005
title: "Take the guided workspace tour of parallel-path execution"
slug: take-the-guided-workspace-tour-of-parallel-path-execution
personas: [P-003, P-008]
epic: "Onboarding & Identity"
priority: should-have
complexity: medium
tags: [onboarding, tour, accessibility, parallel-path]
---

# US-005: Take the Guided Workspace Tour of Parallel-Path Execution

## User Story

**As a** team lead new to Noizu Intellect (and, using only a keyboard and NVDA screen reader, as a blind developer)
**I want to** walk through a guided tour that explains parallel-path execution — decomposition into N paths, tag/checkout forking, grading, and picking — using a real sample run
**So that** I understand the product's core mechanic well enough to trust and use it, regardless of whether I'm navigating visually or by screen reader

## Acceptance Criteria

- **Given** I am a first-time member of a project (human, any role) who has not dismissed the tour
  **When** I open the workspace for the first time
  **Then** I am offered a guided tour that walks a pre-seeded sample parallel-path run: a Planner decomposing a request into N paths, each path forking from a shared checkpoint, a Reviewer's grades, and a pick that back-propagates weight onto the winning path's decision factors

- **Given** I am navigating the tour with a keyboard and NVDA
  **When** each tour step renders
  **Then** focus moves programmatically to the step's content, the step is announced as a landmark with a semantic heading, and every tour control (next/back/skip/exit) is reachable via Tab/Shift+Tab with visible focus indicators — no step depends on hover or drag

- **Given** the tour references live UI regions (path list, grade panel, pick button)
  **When** a screen-reader user reaches that step
  **Then** the referenced region exposes its state via ARIA (e.g. "Path 2 of 3, graded 8/10") rather than relying on color or icon-only cues

- **Given** I exit the tour early
  **When** I return to the workspace later
  **Then** I can relaunch the same tour from a persistent help menu entry, and my progress does not silently resume mid-step without context

## Notes
This is the conceptual-explainer counterpart to actually running a path ([[US-004]] provisions the agents needed to run one for real). Ties to [[P-008]]'s baseline need for keyboard-first, semantic-tree navigation across the whole app, not just this tour.
