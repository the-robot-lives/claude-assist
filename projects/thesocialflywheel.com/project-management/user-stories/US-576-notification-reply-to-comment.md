---
id: US-576
title: "Get Notified When Someone Replies to My Comment"
slug: notification-reply-to-comment
personas: [P-003]
epic: "Reactions & Engagement"
priority: must-have
complexity: low
tags: [notifications, replies, threading]
---

# US-576: Get Notified When Someone Replies to My Comment

## User Story

**As a** Social Connector
**I want to** be notified when someone replies to my comment
**So that** I can continue conversations I've started

## Acceptance Criteria

- **Given** I have posted a reply
  **When** someone in my web replies to it
  **Then** I receive a push or in-app notification within 10 seconds

- **Given** I tap the notification
  **Then** I am taken to that specific nested reply with the parent thread visible above it

## Notes
Notification can be suppressed by muting the thread (US-563). Batching applies if the same comment receives more than 10 replies in quick succession.
