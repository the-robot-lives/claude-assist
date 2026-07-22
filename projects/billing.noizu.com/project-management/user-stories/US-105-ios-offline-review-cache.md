---
id: US-105
title: "iOS offline review cache"
slug: ios-offline-review-cache
personas: [P-008, P-007]
epic: "Cross-Platform Apps"
priority: could-have
complexity: high
tags: [ios, offline, sync]
---

# US-105: iOS offline review cache

## User Story

**As a** mobile approval operator  
**I want to** view recently opened customers, invoices, and reports when connectivity drops  
**So that** travel or weak signal does not leave me with a blank billing app

## Acceptance Criteria

- **Given** I recently viewed billing records on iOS  
  **When** the network is unavailable  
  **Then** the app shows cached read-only records, stale-state indicators, and disables actions requiring server confirmation

## Notes
Financial mutations should not queue silently in the first release. If offline action queues are added later, they need explicit conflict and confirmation handling.
