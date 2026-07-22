---
id: US-044
title: "Work offline count sessions and sync later"
slug: "offline-count-sync"
personas: [P-005]
epic: "Companion App"
priority: "must-have"
complexity: "L"
tags: [companion-app, offline, sync]
---

# US-044: Work offline count sessions and sync later

## User Story

**As a** stockroom clerk (P-005),
**I want to** run counting, receiving, and spot-check sessions entirely without a network connection,
**So that** a weak signal in the stockroom or storeroom (common in rural areas) never stops me from working.

## Acceptance Criteria

- [ ] Given I have no network connection, when I start, work through, and submit a count/receive/spot-check session, then every step behaves identically to the online experience — no feature is hidden or disabled due to connectivity.
- [ ] Given a session was submitted offline, when connectivity returns, then it syncs automatically in the background without requiring me to remember to "upload" it manually.
- [ ] Given two staff members independently adjusted the same item's stock while both were offline (e.g. clerk counted it, cashier sold the last one), when both sessions sync, then the system merges by applying both deltas in timestamp order rather than one overwriting the other, and flags the result for review if the resulting stock would go negative.
- [ ] Given a sync is in progress or pending, when I look at the session list, then each session shows a clear status (pending sync / syncing / synced / sync failed) so I always know what's safely recorded server-side vs. still local-only.

## Notes

This underpins every other companion-app story ([[US-039]], [[US-040]], [[US-041]], [[US-042]], [[US-043]]) — it's listed last but is effectively a foundation dependency, not an add-on. Cross-epic: general sync engine and conflict-resolution architecture live in Sync & Edge Cases (US-076–100); this story specifies the companion-app-specific behavior and merge rule for stock deltas.
