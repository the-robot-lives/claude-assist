---
id: US-015
title: "Offline sale capture & queue"
slug: "offline-sale-capture-queue"
personas: [P-001, P-002]
epic: "Register & Checkout"
priority: "must-have"
complexity: "L"
tags: [offline-first, sync, reliability]
---

# US-015: Offline Sale Capture & Queue

## User Story

**As a** market-stall owner (P-001),
**I want to** complete sales even when I have no internet connection,
**So that** a bad signal never stops me from serving a customer.

## Acceptance Criteria

- [ ] Given the device has no network connectivity, when I complete a sale, then it is saved locally, a receipt can still print, and the transaction is marked "pending sync."
- [ ] Given multiple offline sales accumulate, when the device is offline, then each is stored with a stable local ID so none are lost or overwritten if the app restarts.
- [ ] Given the device is offline, when I use the register, then no screen or button is disabled or degraded due to lack of connectivity, except QR payment confirmation, which has its own offline handling per US-024.

## Notes

Foundational story — nearly every other register story must degrade gracefully under this state. Related: US-016, US-024.
