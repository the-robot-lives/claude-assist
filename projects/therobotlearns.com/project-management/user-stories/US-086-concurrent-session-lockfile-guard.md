---
id: US-086
title: "Concurrent-Session Guard Prevents Two Sessions Clobbering the KB"
slug: concurrent-session-lockfile-guard
personas: [P-001, P-003]
epic: "Resilience & Errors"
priority: must-have
complexity: medium
tags: [resilience, lockfile, concurrency, data-integrity]
---

# US-086: Concurrent-Session Guard Prevents Two Sessions Clobbering the KB

## User Story

**As a** daily learner who sometimes opens robot-learns in more than one terminal
**I want to** be prevented from running two sessions against the same KB at once
**So that** simultaneous writes from two sessions never silently clobber each other's changes

## Acceptance Criteria

- **Given** a robot-learns session is already active against my KB
  **When** I start a second session against the same KB path
  **Then** I'm shown which process/session holds the lock (with start time) and blocked from writing until it's released

- **Given** the lock-holding session exits normally
  **When** it terminates
  **Then** the lockfile is released immediately, and a new session can start without manual cleanup

- **Given** the lock-holding session crashed instead of exiting cleanly
  **When** I start a new session
  **Then** robot-learns detects the stale lock (dead PID) and offers to reclaim it after confirming, rather than blocking forever

- **Given** I only need read access (e.g., browsing articles) while another session holds the write lock
  **When** I request a read-only session
  **Then** it's permitted without contending for the write lock

## Notes
Stale-lock detection (third criterion) is what keeps this from becoming its own failure mode after a crash — pairs with the atomic-write guarantee in US-085.
