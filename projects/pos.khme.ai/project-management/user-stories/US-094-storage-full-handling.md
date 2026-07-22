---
id: US-094
title: "Storage-full handling"
slug: "storage-full-handling"
personas: [P-008, P-005]
epic: "Sync, Performance & Edge Cases"
priority: "should-have"
complexity: "M"
tags: [sync, offline, storage]
---

# US-094: Storage-full handling

## User Story

**As a** rural pharmacy owner (P-008) on a low-end Android device,
**I want to** be warned before local storage fills up with unsynced data,
**So that** I don't lose sales data or have the app crash mid-transaction.

## Acceptance Criteria

- [ ] Given device storage available to the app drops below a safe threshold, when the user opens the app, then a non-blocking banner warns them and suggests connecting to sync/free up space.
- [ ] Given storage is critically low (sale data cannot be safely written), when the cashier attempts to complete a new sale, then the app blocks only that action with a clear message, rather than corrupting or silently dropping the transaction.
- [ ] Given the user syncs successfully after a low-storage warning, when synced transactions are confirmed on the backend, then their local copies are pruned to reclaim space automatically.

## Notes

Depends on US-089's local store design. Should-have rather than must-have because it's a safety net for an edge case of an edge case (extended offline + high volume), but important for P-008 and P-005's low-end hardware contexts.
