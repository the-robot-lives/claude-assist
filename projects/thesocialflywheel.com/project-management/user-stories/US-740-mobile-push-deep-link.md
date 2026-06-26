---
id: US-740
title: "Deep Link Into App From Mobile Push Notification"
slug: mobile-push-deep-link
personas: [P-003]
epic: "Notifications"
priority: must-have
complexity: medium
tags: [push-notifications, deep-link, mobile, navigation]
---

# US-740: Deep Link Into App From Mobile Push Notification

## User Story

**As a** Social Connector
**I want to** be taken directly to the relevant screen when I tap a mobile push notification
**So that** I do not have to navigate manually to find the conversation, post, or profile the notification is about

## Acceptance Criteria

- **Given** I receive a push notification for a new DM
  **When** I tap the notification
  **Then** the app opens directly to the DM thread with the message in view

- **Given** I receive a push notification for a channel mention
  **When** I tap it
  **Then** the app opens to the channel and scrolls to the mentioned message, with the mention highlighted

## Notes
If the app is not installed (web user), the deep link should open the mobile web equivalent of that screen.
