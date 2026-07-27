---
id: US-101
title: "Work fully offline"
slug: work-fully-offline
personas: [P-001, P-004, P-007]
epic: "Sync & Multi-Device"
priority: must-have
complexity: medium
tags: [sync, offline]
---

# US-101: Work fully offline

## User Story

**As a** user with an unreliable or absent network connection
**I want to** create, edit, and delete time spans with no network at all
**So that** a full day of work is never blocked on connectivity

## Acceptance Criteria

- **Given** the desktop agent has no network connection
  **When** I start, stop, split, merge, retitle, or delete a time span
  **Then** the mutation is accepted locally and appended to a durable, ordered push queue that survives app restart - it is never rejected for lack of connectivity

- **Given** the device reconnects
  **When** the queued mutations are pushed
  **Then** they are delivered in the order they were queued (FIFO per device, one batch in flight at a time), and each carries its own `mutation_id` so an interrupted retry cannot apply the same mutation twice

- **Given** a queued span create names a project or client that has not synced yet
  **When** the server processes the create
  **Then** the server auto-vivifies the client/project row instead of rejecting the span, so a day of offline capture is never stranded behind one missing taxonomy row

## Notes

Offline is the normal case, not the error case (docs/SYNC-PROTOCOL.md §2, design commitment 1). See §7.2 for push-queue semantics and §6.1 step 4 for auto-vivification. This story is the foundation the rest of the Sync & Multi-Device epic builds on.
