---
id: US-095
title: "New Device Login Notification"
slug: new-device-login-notification
personas: [P-004]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [security, notifications, login, new-device]
---

# US-095: New Device Login Notification

## User Story

**As a** cautious newcomer
**I want to** receive a notification when my account is accessed from a new device
**So that** I am aware of every new login and can act if one is unauthorized

## Acceptance Criteria

- **Given** I log in from a device I have never used before
  **When** login succeeds
  **Then** an email and (if enabled) a push notification are sent within 60 seconds listing the device, approximate location, and time

- **Given** I receive a new-device notification
  **When** I click "This wasn't me"
  **Then** that session is immediately revoked and I am prompted to change my password
