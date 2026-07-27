---
id: US-102
title: "Keep working with an expired session"
slug: keep-working-with-expired-session
personas: [P-001, P-003, P-004]
epic: "Sync & Multi-Device"
priority: must-have
complexity: medium
tags: [sync, offline]
---

# US-102: Keep working with an expired session

## User Story

**As a** user whose access token has expired while I'm working
**I want to** keep tracking and reviewing without being forced back to a sign-in screen
**So that** an expired token never interrupts a work session

## Acceptance Criteria

- **Given** my access token and refresh token have both expired and I have no network
  **When** I start, stop, or edit a time span
  **Then** the write is accepted and queued exactly as if I were authenticated online - nothing is gated on token validity or network reachability

- **Given** I have network but a refresh attempt fails with 401
  **When** I keep using the app
  **Then** reads continue to be served from the local store (the UI's source of truth at all times), the session is marked `reauth_required` as a status indicator rather than a blocking modal, and neither the local store nor the push queue is cleared

- **Given** I sign back in under the SAME `user_id` the queue was built under
  **When** the app reconnects
  **Then** the queue flushes normally; **given** I instead sign in as a DIFFERENT user on a shared device, the app refuses to flush and quarantines the queue against the previous identity rather than silently pushing one person's captured day into another person's workspace

## Notes

See docs/SYNC-PROTOCOL.md §11.3 (offline grace) and §11.4 (reauthentication and queue safety). The quarantine behavior in the third criterion is described in the protocol as the worst failure this system can produce and the most preventable - test it deliberately, not just the happy path.
