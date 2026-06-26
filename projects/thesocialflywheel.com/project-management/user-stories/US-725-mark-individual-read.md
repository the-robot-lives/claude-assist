---
id: US-725
title: "Mark Individual Notification as Read or Dismiss It"
slug: mark-individual-read
personas: [P-006]
epic: "Notifications"
priority: must-have
complexity: low
tags: [notification-center, mark-read, ux]
---

# US-725: Mark Individual Notification as Read or Dismiss It

## User Story

**As a** Quiet Consumer
**I want to** mark a single notification as read or dismiss it without acting on it
**So that** I can keep the notification center tidy while skipping items I do not want to engage with

## Acceptance Criteria

- **Given** I am in the notification center
  **When** I swipe left on an individual notification
  **Then** I see options for "Mark as read" and "Dismiss" (removes from list)

- **Given** I dismiss a notification
  **When** I navigate away and return
  **Then** the dismissed notification is no longer visible by default but is accessible via a "Show dismissed" toggle

## Notes
Dismissed notifications are soft-deleted and recoverable for 7 days.
