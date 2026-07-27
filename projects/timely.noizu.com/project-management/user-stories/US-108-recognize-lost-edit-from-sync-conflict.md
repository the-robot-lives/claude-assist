---
id: US-108
title: "Recognize a lost edit from a sync conflict"
slug: recognize-lost-edit-from-sync-conflict
personas: [P-001, P-003, P-007]
epic: "Sync & Multi-Device"
priority: should-have
complexity: medium
tags: [sync, conflict]
---

# US-108: Recognize a lost edit from a sync conflict

## User Story

**As a** user who edited the same time span from two devices close together
**I want to** understand when my edit was overwritten by another device's edit, rather than have it disappear silently
**So that** I trust the system enough to redo the correction instead of assuming a bug ate my work

## Acceptance Criteria

- **Given** I edit a span's title on my phone while offline, and another device edits the SAME span's note - a different field - online in the meantime with a later effective timestamp
  **When** my phone reconnects and pushes
  **Then** the whole row, not just the conflicting field, resolves to whichever device's `updated_at_effective` (client time clamped to server receipt time) is later - my title edit is discarded even though it touched a different field than the other device's edit. **This is current, accepted behavior, not a defect.**

- **Given** my edit loses
  **When** the server responds
  **Then** the result status is `applied` (the mutation WAS processed) with `stale_base: true` and the server's winning row returned - Timely never reports a lost edit as a silent failure or a network error

- **Given** my edit is superseded
  **When** I next look at that span
  **Then** the client surfaces a "your edit was superseded" notice with a one-tap reapply that resubmits my change at a fresh timestamp, rather than leaving me to notice the loss on my own

- **Given** both devices' edits land with the exact same `updated_at_effective`
  **When** the tie-break runs
  **Then** the device with the lexically greater `origin_device_id` wins, and both devices compute that same winner locally without asking the server

## Notes

This story is written to match documented reality, not an ideal - it MUST NOT be softened into describing field-level merge as already shipping. See docs/SYNC-PROTOCOL.md §8.1 (default LWW rule), §12 (worked example T3-T4, the exact scenario in the first criterion), and §13 known limitation #1: entity-level LWW losing concurrent edits to disjoint fields is a known, currently-accepted cost; field-level merge is the documented v2 fix, deferred because three independently hand-written clients must agree on it exactly, and entity-level LWW is the version they can all get right first.
