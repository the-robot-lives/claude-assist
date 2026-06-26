---
id: US-098
title: "Authentication Event Notification Preferences"
slug: auth-event-notification-preferences
personas: [P-004]
epic: "Authentication & Security"
priority: should-have
complexity: low
tags: [notifications, security, preferences, email]
---

# US-098: Authentication Event Notification Preferences

## User Story

**As a** cautious newcomer
**I want to** choose which security events trigger email or push notifications
**So that** I receive the alerts I care about without inbox overload

## Acceptance Criteria

- **Given** I open Notification Preferences
  **When** I view the "Security" section
  **Then** I can independently toggle notifications for: new device login, password changed, 2FA changed, suspicious login, and session revoked

- **Given** I disable notifications for "new device login"
  **When** I log in from a new device
  **Then** no email or push notification is sent for that event

## Notes
Suspicious-login alerts cannot be fully disabled; only the channel (email vs push) can be changed.
