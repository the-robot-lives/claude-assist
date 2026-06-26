---
id: US-715
title: "Control Push Notification Content Preview on Lock Screen"
slug: push-notification-lock-screen-preview
personas: [P-006]
epic: "Notifications"
priority: should-have
complexity: low
tags: [push-notifications, privacy, lock-screen]
---

# US-715: Control Push Notification Content Preview on Lock Screen

## User Story

**As a** Quiet Consumer
**I want to** control whether message previews appear on my lock screen
**So that** sensitive conversations are not visible to bystanders when my phone is unattended

## Acceptance Criteria

- **Given** I have set lock-screen preview to "hide content"
  **When** a DM notification arrives
  **Then** the lock-screen notification reads "New message from Flywheel Social" with no sender name or content preview

- **Given** I have set lock-screen preview to "show all"
  **When** a DM notification arrives
  **Then** the lock-screen notification shows the sender's name and up to 100 characters of message text

## Notes
This setting maps to OS-level notification content visibility where supported; on platforms without API support, show a privacy reminder in settings.
