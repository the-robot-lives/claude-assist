---
id: US-104
title: "iOS push notifications for billing events"
slug: ios-push-notifications-for-billing-events
personas: [P-006, P-008]
epic: "Cross-Platform Apps"
priority: should-have
complexity: medium
tags: [ios, push, notifications]
---

# US-104: iOS push notifications for billing events

## User Story

**As a** mobile approval operator  
**I want to** receive iOS notifications for overdue, paid, failed-send, and approval-needed events  
**So that** urgent billing work reaches me without requiring dashboard polling

## Acceptance Criteria

- **Given** I opt into billing notifications  
  **When** a subscribed event occurs  
  **Then** the notification includes safe context, opens the correct screen, and respects workspace notification preferences

## Notes
Notifications must avoid sensitive line-item detail on the lock screen unless the user explicitly enables detailed previews.
