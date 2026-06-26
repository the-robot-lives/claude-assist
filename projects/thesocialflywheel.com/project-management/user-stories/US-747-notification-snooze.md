---
id: US-747
title: "Snooze a Notification to Be Reminded Later"
slug: notification-snooze
personas: [P-006]
epic: "Notifications"
priority: could-have
complexity: medium
tags: [notifications, snooze, reminder, ux]
---

# US-747: Snooze a Notification to Be Reminded Later

## User Story

**As a** Quiet Consumer
**I want to** snooze a notification to resurface later (e.g., in 1 hour or tomorrow morning)
**So that** I can acknowledge a notification without losing it when I am not ready to act on it

## Acceptance Criteria

- **Given** I swipe on a notification in the notification center
  **When** I select "Snooze"
  **Then** I am presented with snooze options: 1 hour, 3 hours, Tomorrow 8 AM, and a custom time picker

- **Given** I snooze a notification
  **When** the snooze period expires
  **Then** the notification reappears at the top of the notification center marked as "Snoozed — returning now" and a push reminder fires if push is enabled

## Notes
Snoozed notifications are stored server-side so they resurface even if the app is closed.
