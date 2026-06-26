---
id: US-709
title: "Notify User of New Direct Message"
slug: new-direct-message
personas: [P-003]
epic: "Notifications"
priority: must-have
complexity: low
tags: [messaging, notifications, dm]
---

# US-709: Notify User of New Direct Message

## User Story

**As a** Social Connector
**I want to** be notified immediately when I receive a direct message from a moot
**So that** I can maintain real-time conversations with my network

## Acceptance Criteria

- **Given** I have DM notifications enabled and the sender is a moot
  **When** a moot sends me a direct message
  **Then** I receive a high-priority push notification with the sender's name and up to 100 characters of message preview

- **Given** I open the message from the notification
  **When** read receipts are enabled
  **Then** the sender sees the message marked as read within 3 seconds

## Notes
DMs from non-moots (if permitted by settings) arrive as low-priority with no message preview.
