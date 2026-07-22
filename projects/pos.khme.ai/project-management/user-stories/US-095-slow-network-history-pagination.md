---
id: US-095
title: "Slow-network pagination of history"
slug: "slow-network-history-pagination"
personas: [P-002, P-006]
epic: "Sync, Performance & Edge Cases"
priority: "should-have"
complexity: "S"
tags: [performance, sync, ux]
---

# US-095: Slow-network pagination of history

## User Story

**As a** minimart owner (P-002) on a slow mobile connection,
**I want** my sales history to load in small pages rather than all at once,
**So that** I can browse past transactions without long waits or timeouts.

## Acceptance Criteria

- [ ] Given the user opens sales history, when the list loads, then only the most recent page (e.g., 20-50 transactions) is fetched initially, rendering within 2 seconds on a 3G-equivalent connection.
- [ ] Given the user scrolls to the bottom of the loaded list, when more history exists, then the next page loads incrementally with a lightweight loading indicator, without re-fetching already-loaded pages.
- [ ] Given the network drops mid-pagination, when the next page fails to load, then already-loaded history remains visible and a retry affordance is shown instead of clearing the screen.

## Notes

Complements offline-first sync (US-089) for the "connected but slow" condition rather than fully offline.
