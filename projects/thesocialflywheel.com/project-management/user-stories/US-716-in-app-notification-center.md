---
id: US-716
title: "View All Notifications in the In-App Notification Center"
slug: in-app-notification-center
personas: [P-006]
epic: "Notifications"
priority: must-have
complexity: medium
tags: [notification-center, in-app, history]
---

# US-716: View All Notifications in the In-App Notification Center

## User Story

**As a** Quiet Consumer
**I want to** have a single in-app notification center that shows all recent activity
**So that** I can review what I missed in one place without relying on push notifications

## Acceptance Criteria

- **Given** I navigate to the notification center
  **When** the page loads
  **Then** I see a reverse-chronological list of notifications from the past 30 days, grouped by day, with unread items visually distinguished from read ones

- **Given** the notification center is open and a new notification arrives
  **When** the system delivers it
  **Then** it appears at the top of the list in real-time without a page refresh

## Notes
Notifications older than 30 days are archived and accessible via a "Load older" control.
