---
id: US-093
title: "Degraded mode when server unreachable for days"
slug: "degraded-mode-extended-outage"
personas: [P-008]
epic: "Sync, Performance & Edge Cases"
priority: "must-have"
complexity: "L"
tags: [sync, offline, resilience]
---

# US-093: Degraded mode when server unreachable for days

## User Story

**As a** rural pharmacy owner (P-008) who may go days without a reliable connection,
**I want** the app to keep working fully offline for extended periods,
**So that** a multi-day outage doesn't stop me from running my business.

## Acceptance Criteria

- [ ] Given the device has had no successful sync for multiple days, when the user continues to make sales, then all core register functions (sell, inventory adjust, cash drawer) remain fully available with no feature degraded or locked.
- [ ] Given an extended offline period, when local storage approaches capacity from the growing sync queue, then the app prioritizes retaining unsynced transactions over any purely cached/reference data that can be re-fetched later.
- [ ] Given connectivity is restored after several days offline, when a large sync queue exists, then sync processes in the background in batches, prioritizing financial transactions first, without freezing the UI.

## Notes

Depends on US-089 and interacts with US-094 (storage-full handling) for the multi-day-outage worst case. This is a must-have direct expression of product principle 2, not an edge case, for P-008's context.
