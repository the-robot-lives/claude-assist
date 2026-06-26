---
id: US-702
title: "Receive Notification When Moot Request Is Accepted"
slug: mutual-request-accepted
personas: [P-003]
epic: "Notifications"
priority: must-have
complexity: low
tags: [mutuals, notifications, social-graph]
---

# US-702: Receive Notification When Moot Request Is Accepted

## User Story

**As a** Social Connector
**I want to** be notified when someone accepts my moot request
**So that** I can immediately start interacting with my new mutual connection

## Acceptance Criteria

- **Given** I sent a moot request that was pending
  **When** the recipient accepts my request
  **Then** I receive a notification stating "[Name] is now a moot" with a link to their profile

- **Given** I receive the accepted-request notification
  **When** I view the notification center
  **Then** the notification shows the mutual's avatar, display name, and a "Send message" shortcut

## Notes
If the user has quiet hours active, this notification is queued and delivered when quiet hours end.
