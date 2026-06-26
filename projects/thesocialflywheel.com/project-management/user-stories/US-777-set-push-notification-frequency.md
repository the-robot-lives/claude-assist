---
id: US-777
title: "Set Push Notification Frequency"
slug: set-push-notification-frequency
personas: [P-006]
epic: "Settings & Preferences"
priority: must-have
complexity: low
tags: [notifications, push, frequency, preferences]
---

# US-777: Set Push Notification Frequency

## User Story

**As a** quiet consumer
**I want to** control how frequently push notifications are delivered
**So that** I can stay informed without constant interruptions

## Acceptance Criteria

- **Given** I open Notification Settings
  **When** I select "Batched – once per hour"
  **Then** the app groups all eligible notifications and delivers one push per hour instead of one per event.

- **Given** I select "Quiet Hours" and set 10 PM–8 AM
  **When** a notification is triggered during that window
  **Then** it is queued and delivered silently at 8 AM.

## Notes
