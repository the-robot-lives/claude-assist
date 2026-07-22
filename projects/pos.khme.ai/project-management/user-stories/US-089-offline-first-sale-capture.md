---
id: US-089
title: "Offline-first sale capture with background sync"
slug: "offline-first-sale-capture"
personas: [P-008, P-001]
epic: "Sync, Performance & Edge Cases"
priority: "must-have"
complexity: "XL"
tags: [sync, offline, core]
---

# US-089: Offline-first sale capture with background sync

## User Story

**As a** rural pharmacy owner (P-008) with intermittent connectivity,
**I want to** complete sales entirely offline,
**So that** a dropped connection never blocks me from serving a customer.

## Acceptance Criteria

- [ ] Given the device has no network connectivity, when the cashier completes a sale on the sell screen, then the sale is recorded locally, the drawer/inventory update immediately, and a receipt (digital or printed) is produced without any network call in the critical path.
- [ ] Given connectivity returns after a period offline, when the app detects it, then all queued local transactions sync to the backend automatically in the background without interrupting active use of the register.
- [ ] Given a sync is in progress, when the user views the sell screen, then a non-blocking status indicator shows "syncing" / "up to date" without any modal or interruption.

## Notes

XL — decompose into local transaction store, sync queue/retry engine, and status UI as separate build tickets. This is the foundational story the rest of this epic (US-090 through US-095) depends on; must-have per product principle 2 ("offline-first").
