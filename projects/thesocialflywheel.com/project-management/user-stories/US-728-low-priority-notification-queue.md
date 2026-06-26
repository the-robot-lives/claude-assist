---
id: US-728
title: "Separate Low-Priority Notifications Into a Background Queue"
slug: low-priority-notification-queue
personas: [P-006]
epic: "Notifications"
priority: should-have
complexity: medium
tags: [priority, notifications, queue, ux]
---

# US-728: Separate Low-Priority Notifications Into a Background Queue

## User Story

**As a** Quiet Consumer
**I want to** have low-priority notifications (reactions, channel activity, digest items) held in a separate queue
**So that** they do not compete for attention with urgent notifications like DMs and mentions

## Acceptance Criteria

- **Given** a low-priority notification is generated
  **When** I have the low-priority queue enabled
  **Then** it is stored in the "Catch-up" section of the notification center and does not trigger a push notification

- **Given** I open the "Catch-up" section
  **When** it loads
  **Then** I see all queued low-priority items sorted by recency with a total unread count badge

## Notes
Users should be able to reclassify individual notification types between high and low priority in preferences.
