---
id: US-046
title: "Watch live progress across concurrent paths"
slug: watch-live-progress-across-concurrent-paths
personas: [P-001, P-008]
epic: "Parallel-Path Execution"
priority: must-have
complexity: medium
tags: [live-progress, pubsub, status, monitoring]
---

# US-046: Watch Live Progress Across Concurrent Paths

## User Story

**As a** solo staff engineer
**I want to** watch a live view of all paths in a run — status, current turn, and which agent is acting — updating as it happens
**So that** I know at a glance which paths are progressing, stuck, or already finished without polling each thread individually

## Acceptance Criteria

- **Given** a run has N paths in flight
  **When** I open the run's live view
  **Then** I see each path's current status (queued/running/paused/blocked/completed/failed), current turn number, and the handle of the agent whose turn is active, updating via PubSub without a page refresh

- **Given** a path's agent transitions between the Plan, Reply, and Reflect passes of a turn
  **When** the transition happens
  **Then** the live view reflects the current pass, not just "running", so I can tell a stalled Reflect pass from a stalled Plan pass

- **Given** I am using a screen reader (NVDA)
  **When** path statuses update
  **Then** updates are exposed through accessible live-region semantics so status changes are announced without requiring we visually scan a grid, and the view is fully keyboard-navigable

- **Given** a path completes or fails while I'm watching
  **When** the transition occurs
  **Then** the live view surfaces a distinct, non-disruptive notification (not a modal that blocks viewing other paths) and the path's final status persists in the view after completion

## Notes
This is the moment-to-moment operational view feeding into the full execution tree (US-052) and pause/cancel controls (US-047/US-048). Accessible live-region design directly serves Alex (P-008), whose workflow depends on semantic status rather than a purely visual grid/kanban layout.
