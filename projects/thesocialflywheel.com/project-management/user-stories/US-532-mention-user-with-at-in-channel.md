---
id: US-532
title: "Mention a User with @ in Channel"
slug: mention-user-with-at-in-channel
personas: [P-001]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [mention, at-mention, channel-chat, notifications]
---

# US-532: Mention a User with @ in Channel

## User Story

**As a** Bridge-Builder (P-001)
**I want to** @mention specific members in a channel chat
**So that** they receive a targeted notification and I can address them directly in a large thread

## Acceptance Criteria

- **Given** I type "@" in the channel compose field
  **When** I continue typing a username
  **Then** an autocomplete dropdown appears showing matching channel members and I can arrow-key or tap to select one

- **Given** I send a message containing @username
  **When** the message is delivered
  **Then** the mentioned user receives a mention notification regardless of their general channel notification setting

- **Given** I type @channel
  **When** the message is sent
  **Then** all active channel members receive a notification (moderator permission required to use @channel)

## Notes
Mention autocomplete searches display name first, then handle. Non-members of the channel cannot be @mentioned.
