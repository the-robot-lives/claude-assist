---
id: US-749
title: "Display In-App Notification Toast for Foreground Alerts"
slug: in-app-notification-toast
personas: [P-003]
epic: "Notifications"
priority: must-have
complexity: medium
tags: [notifications, toast, in-app, foreground]
---

# US-749: Display In-App Notification Toast for Foreground Alerts

## User Story

**As a** Social Connector actively using the app
**I want to** see a brief in-app toast notification at the top of the screen when a new event occurs
**So that** I am aware of activity without leaving my current context

## Acceptance Criteria

- **Given** I am actively using the app and a high-priority event occurs (DM, mention, match)
  **When** the event is received
  **Then** a toast banner slides down from the top of the screen showing the event type, sender/source, and a 1-line preview

- **Given** the toast is visible
  **When** I tap it
  **Then** I am navigated to the relevant content; when I ignore it, the toast auto-dismisses after 4 seconds

## Notes
At most one toast is shown at a time; subsequent toasts queue behind the current one. Low-priority events do not trigger toasts.
