---
id: US-745
title: "Notify User of Changes to Their Exclusion Settings"
slug: exclusion-update-notification
personas: [P-001]
epic: "Notifications"
priority: should-have
complexity: low
tags: [safety, exclusions, notifications, account]
---

# US-745: Notify User of Changes to Their Exclusion Settings

## User Story

**As a** Bridge Builder
**I want to** receive a notification if my exclusion or block settings are changed by any means other than my direct action
**So that** I can quickly identify unauthorized changes to my safety configuration

## Acceptance Criteria

- **Given** my account has an active session on a secondary device
  **When** that session modifies my block or exclusion list
  **Then** I receive a security notification on all other active sessions: "Your safety settings were updated from another device."

- **Given** I tap the safety settings notification
  **When** the detail screen opens
  **Then** I see a log of recent safety setting changes with device/session info and an option to review and revert

## Notes
This is a security-class notification and cannot be disabled by the user. It is always delivered via in-app and email.
