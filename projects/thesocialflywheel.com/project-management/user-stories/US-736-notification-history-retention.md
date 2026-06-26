---
id: US-736
title: "Define and Communicate Notification History Retention Period"
slug: notification-history-retention
personas: [P-010]
epic: "Notifications"
priority: should-have
complexity: low
tags: [notification-center, retention, history, transparency]
---

# US-736: Define and Communicate Notification History Retention Period

## User Story

**As a** Skeptical Switcher
**I want to** know how long my notification history is retained and when items will be purged
**So that** I can trust the platform's data practices and know when to act on time-sensitive notifications

## Acceptance Criteria

- **Given** I open the notification center
  **When** I view the settings or footer of the center
  **Then** I see a clear label stating "Notifications are retained for 30 days. Older notifications are permanently deleted."

- **Given** a notification is about to expire (within 3 days)
  **When** I view that notification in the center
  **Then** it is marked with an "Expiring soon" indicator and I can save or act on it before deletion

## Notes
Retention period is 30 days by default. Premium tiers may extend this to 90 days.
