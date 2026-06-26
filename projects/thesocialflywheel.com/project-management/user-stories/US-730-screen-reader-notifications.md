---
id: US-730
title: "Ensure Notifications Are Accessible to Screen Reader Users"
slug: screen-reader-notifications
personas: [P-001]
epic: "Notifications"
priority: must-have
complexity: medium
tags: [accessibility, screen-reader, a11y, notifications]
---

# US-730: Ensure Notifications Are Accessible to Screen Reader Users

## User Story

**As a** Bridge Builder using a screen reader
**I want to** have all notification content properly announced by my assistive technology
**So that** I receive the same timely information as sighted users

## Acceptance Criteria

- **Given** I use a screen reader (VoiceOver / TalkBack)
  **When** a push notification arrives
  **Then** the OS reads aloud the notification's full text including sender name, notification type, and preview content in logical order

- **Given** I navigate to the in-app notification center with a screen reader active
  **When** I focus on a notification item
  **Then** it is announced as: "[Type], [Sender/source], [Preview], [Read/unread status], [Timestamp]"

## Notes
All interactive notification actions (Mark as read, Dismiss, Reply) must have accessible labels and be reachable via swipe navigation.
