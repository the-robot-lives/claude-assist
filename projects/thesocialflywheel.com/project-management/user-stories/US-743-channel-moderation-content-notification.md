---
id: US-743
title: "Notify User When Their Channel Content Is Moderated"
slug: channel-moderation-content-notification
personas: [P-001]
epic: "Notifications"
priority: must-have
complexity: medium
tags: [moderation, channel, notifications, transparency]
---

# US-743: Notify User When Their Channel Content Is Moderated

## User Story

**As a** Bridge Builder
**I want to** receive a notification when a moderator removes or restricts my post in a channel
**So that** I understand what happened to my content and can choose to appeal if I believe it was in error

## Acceptance Criteria

- **Given** a channel moderator removes my post
  **When** the removal is executed
  **Then** I receive an in-app notification: "A moderator removed your post in #channel-name. Reason: [reason]. You may appeal within 7 days."

- **Given** I tap the moderation notification
  **When** the detail screen opens
  **Then** I see the removed content (read-only), the stated reason, the community guideline cited, and an "Appeal" button

## Notes
If the removal is due to an automated system action, the notification must still be delivered with a note that human review is available.
