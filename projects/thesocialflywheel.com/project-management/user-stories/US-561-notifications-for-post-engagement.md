---
id: US-561
title: "Receive Notifications When Someone Engages My Post"
slug: notifications-for-post-engagement
personas: [P-009]
epic: "Reactions & Engagement"
priority: must-have
complexity: medium
tags: [notifications, engagement, creator]
---

# US-561: Receive Notifications When Someone Engages My Post

## User Story

**As a** Creator
**I want to** be notified when someone reacts to or replies to my post
**So that** I can follow up and build community around my content

## Acceptance Criteria

- **Given** someone within my web reacts to my post
  **Then** I receive an in-app notification within 5 seconds

- **Given** someone replies to my post
  **When** I tap the notification
  **Then** I am taken directly to that reply in context with the parent post visible above

- **Given** a post receives more than 50 engagements within one hour
  **Then** notifications are batched into a digest to avoid flooding my notification tray

## Notes
Notification preferences are configurable per engagement type in Settings → Notifications.
