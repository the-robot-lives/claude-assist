---
id: US-044
title: "Launch N paths that fork from a shared base context"
slug: launch-n-paths-that-fork-from-a-shared-base-context
personas: [P-001]
epic: "Parallel-Path Execution"
priority: must-have
complexity: high
tags: [path-launch, fork, checkout, concurrency]
---

# US-044: Launch N Paths That Fork From a Shared Base Context

## User Story

**As a** solo staff engineer
**I want to** launch the finalized breakdown so all N paths fork concurrently from one shared base checkpoint
**So that** every path starts from the exact same context and the differences in outcome are attributable to the paths' approaches, not to drift in starting conditions

## Acceptance Criteria

- **Given** a finalized breakdown of N candidate paths (from US-039/US-040) within my configured cap (US-041)
  **When** I click launch
  **Then** the system auto-tags the current thread state as the shared base checkpoint, then checks out N independent path threads from that single tag, and starts one path GenServer per thread

- **Given** the N paths have been checked out
  **When** I inspect any two paths immediately after launch
  **Then** their message history, memory sandbox contents, and cognition tables are identical up to the base checkpoint and diverge only from the first turn each path executes

- **Given** paths are launched concurrently
  **When** one path's first agent turn fails to start (e.g. provider error, quota exhaustion)
  **Then** the other paths continue independently — a single path's launch failure never blocks or cancels sibling paths

- **Given** a run has launched
  **When** I view the run
  **Then** each path shows its assigned agent(s), its origin rationale from the breakdown, and a link back to the shared base tag

## Notes
This is the mechanical core of the product's differentiator — everything else in this epic (progress, pause/cancel, comparison, grading) operates on the paths this story creates. The shared-base guarantee is what makes later grading (US-051) and turn-by-turn comparison (US-054) meaningful rather than apples-to-oranges.
