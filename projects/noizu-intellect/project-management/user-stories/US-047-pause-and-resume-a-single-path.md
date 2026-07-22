---
id: US-047
title: "Pause and resume a single path"
slug: pause-and-resume-a-single-path
personas: [P-001]
epic: "Parallel-Path Execution"
priority: should-have
complexity: medium
tags: [pause, resume, path-control]
---

# US-047: Pause and Resume a Single Path

## User Story

**As a** solo staff engineer
**I want to** pause one path in a run without affecting its siblings, and resume it later
**So that** I can hold off a path that needs my input or looks questionable while the rest of the run keeps going

## Acceptance Criteria

- **Given** a path is running (mid-turn or between turns)
  **When** I click pause on that path
  **Then** the path's GenServer completes its current in-flight LLM call (if any) but does not start a new turn, and its status shows "paused" in the live view (US-046), while sibling paths continue unaffected

- **Given** a path is paused
  **When** I click resume
  **Then** the path picks up exactly where it left off — next turn number, same memory sandbox state, same model strategy — with no state loss or turn-order corruption

- **Given** a path is paused
  **When** I inspect it
  **Then** I can still read its full history and post an out-of-band note or instruction that the next turn will pick up on resume, without that note counting as a turn itself

- **Given** a path has been paused for longer than the project's configured idle retention window
  **When** the window elapses
  **Then** I receive a notification that the path is still paused and consuming a run slot, rather than it silently timing out or being auto-cancelled

## Notes
Pause/resume is a per-path control distinct from the run-level pause implied by hitting a spend cap (US-041) — this story is about deliberate, path-scoped human intervention. Complements cancel (US-048), which is a one-way terminal action.
