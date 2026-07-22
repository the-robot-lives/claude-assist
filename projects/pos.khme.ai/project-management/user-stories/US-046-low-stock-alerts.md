---
id: US-046
title: "Receive low-stock alerts"
slug: "low-stock-alerts"
personas: [P-002, P-001]
epic: "Forecasting & Resupply"
priority: "must-have"
complexity: "S"
tags: [forecasting, alerts, low-stock]
---

# US-046: Receive low-stock alerts

## User Story

**As a** market-stall owner (P-001),
**I want to** get a simple notification when an item is running low,
**So that** I know to reorder even if I never open the forecasting dashboard.

## Acceptance Criteria

- [ ] Given an item's stock falls below a threshold (either a manually-set reorder point, or, once available, the velocity-based projection from [[US-045]]), when the threshold is crossed, then a notification appears in-app and, if enabled, as a push notification.
- [ ] Given no reorder point is manually set for an item, when the system has enough sales history, then it defaults to a sensible auto-threshold rather than requiring every item to be configured by hand — this is what makes it usable for a novice like Sokha without forecasting knowledge.
- [ ] Given multiple items are low at once, when I view the alert list, then they're grouped into a single daily summary rather than one interruption per item, to avoid notification fatigue on a phone-only workflow.
- [ ] Given I dismiss or snooze an alert for an item, when the same low-stock condition persists, then it does not re-fire for a merchant-configurable cooldown (default 24h), but does re-fire if stock drops further.

## Notes

Simpler and more essential than the full reorder-suggestion dashboard — this is the must-have notification layer that works even for merchants who never touch forecasting configuration. Related: [[US-045]], [[US-035]] (expiry alerts use a parallel but distinct surface).
