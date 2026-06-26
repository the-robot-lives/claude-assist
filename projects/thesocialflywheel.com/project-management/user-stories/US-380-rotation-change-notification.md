---
id: US-380
title: "Rotation Change Notification"
slug: rotation-change-notification
personas: [P-002]
epic: "Discovery Engine"
priority: could-have
complexity: low
tags: [discovery, rotation, notifications]
---

# US-380: Rotation Change Notification

## User Story

**As a** Niche Enthusiast
**I want to** receive a notification when my monthly discovery rotation changes
**So that** I know to revisit my settings or engage with new topics being introduced

## Acceptance Criteria

- **Given** the monthly rotation event fires and my active topic set changes
  **When** I next open the app
  **Then** an in-app notification informs me that discovery has rotated and lists the new topic clusters briefly

- **Given** I have disabled all in-app notifications
  **When** the rotation changes
  **Then** no notification is sent and the rotation change is only discoverable via the Upcoming Rotation page

## Notes
This notification should be in-app only (no push) to avoid notification fatigue for a routine scheduled event.
