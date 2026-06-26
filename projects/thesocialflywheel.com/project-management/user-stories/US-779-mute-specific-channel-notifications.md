---
id: US-779
title: "Mute Channel Notifications"
slug: mute-channel-notifications
personas: [P-007]
epic: "Settings & Preferences"
priority: should-have
complexity: medium
tags: [notifications, channels, mute, moderation]
---

# US-779: Mute Channel Notifications

## User Story

**As a** channel moderator
**I want to** mute push notifications for specific channels
**So that** routine activity in low-priority channels does not distract me while I am moderating another channel

## Acceptance Criteria

- **Given** I navigate to Notification Settings > Channels
  **When** I mute a channel
  **Then** push notifications from that channel are silenced while in-app notification badges still accumulate.

- **Given** I have muted a channel
  **When** I view the muted channels list
  **Then** I can unmute any channel and push notifications resume within 60 seconds.

## Notes
