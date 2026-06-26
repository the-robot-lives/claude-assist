---
id: US-295
title: "Accept or Reject Interest From Notification"
slug: accept-reject-from-notification
personas: [P-003]
epic: "Swipe-to-Match"
priority: should-have
complexity: medium
tags: [notification, inbox, quick-action]
---

# US-295: Accept or Reject Interest From Notification

## User Story

**As a** Social Connector (P-003)
**I want to** accept or reject an incoming interest directly from a push notification
**So that** I can manage my inbox without opening the app

## Acceptance Criteria

- **Given** I receive a push notification for a new incoming interest
  **When** I long-press the notification on iOS or expand it on Android
  **Then** "Accept" and "Decline" action buttons are visible

- **Given** I tap "Accept" from the notification action
  **When** the action is processed
  **Then** we become mutuals and the interest is removed from my inbox, confirmed by a follow-up notification
