---
id: US-724
title: "Mark All Notifications as Read"
slug: mark-all-read
personas: [P-006]
epic: "Notifications"
priority: must-have
complexity: low
tags: [notification-center, mark-read, ux]
---

# US-724: Mark All Notifications as Read

## User Story

**As a** Quiet Consumer
**I want to** clear my unread notification count with a single "mark all as read" action
**So that** I can reset my mental state after catching up without clicking each item individually

## Acceptance Criteria

- **Given** I have unread notifications in the notification center
  **When** I tap "Mark all as read"
  **Then** all notifications are marked read, the unread badge resets to zero, and the unread visual indicator is removed from all items

- **Given** I mark all as read
  **When** a new notification arrives moments later
  **Then** only the new notification shows the unread indicator; previously read ones do not

## Notes
This action shows a 5-second undo toast: "Marked all as read · Undo".
