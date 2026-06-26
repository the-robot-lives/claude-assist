---
id: US-737
title: "Clear All Old Notifications at Once"
slug: clear-old-notifications
personas: [P-006]
epic: "Notifications"
priority: could-have
complexity: low
tags: [notification-center, cleanup, ux]
---

# US-737: Clear All Old Notifications at Once

## User Story

**As a** Quiet Consumer
**I want to** bulk-delete notifications older than a chosen age (e.g., 7 days)
**So that** I can keep the notification center uncluttered without waiting for auto-expiry

## Acceptance Criteria

- **Given** I tap "Clear old notifications" in the notification center
  **When** I select a time threshold (e.g., 7 days)
  **Then** all notifications older than the threshold are permanently deleted and the list refreshes

- **Given** I choose to clear old notifications
  **When** I confirm the action
  **Then** a toast confirms "Notifications older than 7 days cleared" and the action is not reversible

## Notes
This action clears only read notifications by default; unread notifications older than the threshold require explicit confirmation to delete.
