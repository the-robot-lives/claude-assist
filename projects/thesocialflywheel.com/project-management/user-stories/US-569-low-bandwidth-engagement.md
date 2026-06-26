---
id: US-569
title: "Engage with Posts on a Low-Bandwidth Connection"
slug: low-bandwidth-engagement
personas: [P-006, P-004]
epic: "Reactions & Engagement"
priority: should-have
complexity: medium
tags: [performance, low-bandwidth, reactions]
---

# US-569: Engage with Posts on a Low-Bandwidth Connection

## User Story

**As a** Quiet Consumer on a slow connection
**I want to** reactions and replies to submit reliably
**So that** poor network conditions don't block my engagement

## Acceptance Criteria

- **Given** my connection is below 2G speed
  **When** I submit a reaction
  **Then** the UI applies an optimistic update immediately and syncs in the background

- **Given** the sync fails
  **When** connectivity is restored
  **Then** the reaction is automatically retried and confirmed without any user action

- **Given** the retry also fails permanently
  **Then** I see a non-blocking banner "Reaction not saved — tap to retry"

## Notes
Use service worker or local queue for offline queuing. Optimistic state must roll back on permanent failure.
