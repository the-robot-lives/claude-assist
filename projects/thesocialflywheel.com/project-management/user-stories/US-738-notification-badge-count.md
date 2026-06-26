---
id: US-738
title: "Display Unread Notification Badge Count on App Icon"
slug: notification-badge-count
personas: [P-006]
epic: "Notifications"
priority: must-have
complexity: low
tags: [badge, push-notifications, app-icon, ux]
---

# US-738: Display Unread Notification Badge Count on App Icon

## User Story

**As a** Quiet Consumer
**I want to** see a badge count on the app icon reflecting my unread notifications
**So that** I can assess at a glance whether I need to open the app without being pushed by a notification

## Acceptance Criteria

- **Given** I have unread notifications in the notification center
  **When** I view the app icon on my home screen
  **Then** a badge displays the total count of unread high-priority notifications (capped at 99+)

- **Given** I mark all notifications as read in the app
  **When** I return to the home screen
  **Then** the badge is cleared immediately

## Notes
Badge count reflects only high-priority unread notifications by default. Users can configure it to include all types in notification settings.
