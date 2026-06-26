---
id: US-701
title: "Receive Notification for Incoming Mutual Request"
slug: mutual-request-received
personas: [P-003]
epic: "Notifications"
priority: must-have
complexity: low
tags: [mutuals, notifications, social-graph]
---

# US-701: Receive Notification for Incoming Mutual Request

## User Story

**As a** Social Connector
**I want to** receive an instant notification when someone sends me a mutual (moot) request
**So that** I can respond promptly and grow my network without missing connection opportunities

## Acceptance Criteria

- **Given** I have in-app notifications enabled for moot requests
  **When** another user sends me a mutual request
  **Then** I receive an in-app notification and a push notification (if enabled) identifying the requester by display name and handle

- **Given** I tap the moot-request notification
  **When** the app opens
  **Then** I am taken directly to the requester's profile with accept/decline actions visible

## Notes
Notification must arrive within 5 seconds of request submission under normal network conditions.
