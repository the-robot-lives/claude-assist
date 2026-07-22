---
id: US-016
title: "Sync offline queue on reconnect"
slug: "sync-offline-queue-reconnect"
personas: [P-001, P-002]
epic: "Register & Checkout"
priority: "must-have"
complexity: "M"
tags: [offline-first, sync, reliability]
---

# US-016: Sync Offline Queue on Reconnect

## User Story

**As a** minimart owner (P-002),
**I want to** have queued offline sales sync automatically once connectivity returns,
**So that** my back-office records stay accurate without manual intervention.

## Acceptance Criteria

- [ ] Given one or more sales are queued locally, when the device regains connectivity, then sync begins automatically in the background without blocking the sell screen.
- [ ] Given a sync conflict occurs (e.g., duplicate submission), when detected, then the system de-duplicates by local sale ID rather than creating two records.
- [ ] Given sync is in progress, when I check a queued sale's status, then I can see "pending," "syncing," or "synced" state per transaction.

## Notes

Depends on US-015. Related: broader conflict-resolution policy in the Sync & Edge Cases epic (US-076-100).
