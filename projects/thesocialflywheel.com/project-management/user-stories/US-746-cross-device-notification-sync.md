---
id: US-746
title: "Sync Notification Read State Across Devices"
slug: cross-device-notification-sync
personas: [P-003]
epic: "Notifications"
priority: should-have
complexity: high
tags: [sync, cross-device, notification-center, ux]
---

# US-746: Sync Notification Read State Across Devices

## User Story

**As a** Social Connector who uses Flywheel Social on both phone and desktop
**I want to** have notification read/dismissed state sync across all my devices
**So that** I do not see duplicate unread badges or re-read notifications I already handled

## Acceptance Criteria

- **Given** I mark a notification as read on my phone
  **When** I open the app on my desktop browser within 30 seconds
  **Then** that notification is already shown as read in the desktop notification center

- **Given** I dismiss a push notification on one device
  **When** the same push notification is pending on another device
  **Then** the pending notification is cancelled on the second device within 30 seconds

## Notes
Sync is best-effort under poor connectivity; eventual consistency within 2 minutes is acceptable.
