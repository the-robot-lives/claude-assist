---
id: US-525
title: "Receive Push Notification for New DM"
slug: receive-push-notification-for-new-dm
personas: [P-003]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [notifications, direct-messages, push]
---

# US-525: Receive Push Notification for New DM

## User Story

**As a** Social Connector (P-003)
**I want to** receive a push notification when a mutual sends me a new direct message
**So that** I can respond promptly even when the app is in the background

## Acceptance Criteria

- **Given** the app is in the background and a mutual sends me a DM
  **When** the message is delivered
  **Then** a push notification appears on my device within 5 seconds showing the sender's name and a message preview (first 80 characters)

- **Given** I have "Do Not Disturb" enabled
  **When** a DM arrives
  **Then** the notification is suppressed but a badge count increments on the app icon

- **Given** I tap the notification
  **When** the app opens
  **Then** I am taken directly to the relevant DM thread

## Notes
Notification content must respect end-to-end encryption; server-side only pushes a minimal envelope and the client decrypts to show the preview.
