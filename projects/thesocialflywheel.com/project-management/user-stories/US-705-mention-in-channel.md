---
id: US-705
title: "Notify User of Channel Mention"
slug: mention-in-channel
personas: [P-003]
epic: "Notifications"
priority: must-have
complexity: low
tags: [mentions, channel, notifications]
---

# US-705: Notify User of Channel Mention

## User Story

**As a** Social Connector
**I want to** be notified whenever someone @mentions me in a channel
**So that** I can respond to conversations directed at me without constantly monitoring every channel

## Acceptance Criteria

- **Given** I am a member of a channel and have mention notifications enabled
  **When** another member posts a message containing @my-handle
  **Then** I receive a high-priority notification showing the mentioner's name, the channel name, and a truncated preview of the message

- **Given** the mention notification arrives while my app is in the foreground
  **When** the notification toast appears
  **Then** I can reply inline from the toast without leaving my current screen

## Notes
Mentions in channels I have muted are still delivered as high-priority unless the user has explicitly overridden mention alerts for that channel.
