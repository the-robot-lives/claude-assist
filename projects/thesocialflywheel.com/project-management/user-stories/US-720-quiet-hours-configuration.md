---
id: US-720
title: "Configure Quiet Hours for Notifications"
slug: quiet-hours-configuration
personas: [P-006]
epic: "Notifications"
priority: must-have
complexity: medium
tags: [quiet-hours, do-not-disturb, preferences]
---

# US-720: Configure Quiet Hours for Notifications

## User Story

**As a** Quiet Consumer
**I want to** set a daily quiet-hours window during which push notifications are silenced
**So that** I am not disturbed during sleep or focused work without fully disabling notifications

## Acceptance Criteria

- **Given** I enable quiet hours and set a start and end time
  **When** the quiet window is active
  **Then** push notifications are suppressed and resume automatically when the window ends

- **Given** quiet hours are active and a notification arrives
  **When** quiet hours end
  **Then** queued notifications are delivered as a batch summary, not individually

## Notes
Quiet hours respect the device's local timezone and update automatically when the user travels.
