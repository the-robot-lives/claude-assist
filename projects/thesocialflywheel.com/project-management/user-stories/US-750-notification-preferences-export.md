---
id: US-750
title: "Export and Import Notification Preferences"
slug: notification-preferences-export
personas: [P-010]
epic: "Notifications"
priority: wont-have
complexity: high
tags: [preferences, portability, notifications, power-user]
---

# US-750: Export and Import Notification Preferences

## User Story

**As a** Skeptical Switcher
**I want to** export my notification preferences to a file and re-import them after a device migration or account reset
**So that** I do not have to manually reconfigure dozens of per-type and per-channel settings after switching devices

## Acceptance Criteria

- **Given** I navigate to notification preferences
  **When** I tap "Export preferences"
  **Then** a JSON file containing all my notification settings is generated and downloaded/shared to my device

- **Given** I have a previously exported preferences file
  **When** I tap "Import preferences" and select the file
  **Then** all settings in the file are applied to my account and a confirmation lists what was changed

## Notes
Deferred to post-launch. Server-side sync (US-746) and per-type preferences (US-718, US-719) should be shipped first as they reduce the need for manual export/import.
