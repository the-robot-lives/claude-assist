---
id: US-107
title: "Android push notifications for billing events"
slug: android-push-notifications-for-billing-events
personas: [P-006, P-008]
epic: "Cross-Platform Apps"
priority: should-have
complexity: medium
tags: [android, push, notifications]
---

# US-107: Android push notifications for billing events

## User Story

**As a** mobile approval operator  
**I want to** receive Android notifications for overdue, paid, failed-send, and approval-needed events  
**So that** urgent billing work reaches me on my primary phone

## Acceptance Criteria

- **Given** I opt into billing notifications  
  **When** a subscribed event occurs  
  **Then** the notification uses the correct Android channel, opens the relevant screen, and respects workspace preferences

## Notes
Notification channels should separate urgent approval events from lower-priority revenue summaries.
