---
id: US-531
title: "Pin a Message in Channel"
slug: pin-a-message-in-channel
personas: [P-007]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: low
tags: [pin, channel-chat, moderation, organization]
---

# US-531: Pin a Message in Channel

## User Story

**As a** Channel Moderator (P-007)
**I want to** pin important messages at the top of a channel's chat
**So that** members can quickly find key announcements without scrolling through history

## Acceptance Criteria

- **Given** I am a moderator and right-click or long-press a channel message
  **When** I select "Pin message"
  **Then** the message appears in a pinned-messages banner at the top of the channel chat, and a system message confirms it was pinned

- **Given** there are multiple pinned messages
  **When** a member taps the pinned banner
  **Then** a panel opens listing all pinned messages in reverse-pin order, with a jump-to link for each

- **Given** I pin a message that was already pinned by another moderator
  **When** I select "Unpin message"
  **Then** it is removed from the pinned list and a system message notes it was unpinned

## Notes
Maximum 10 pinned messages per channel. Exceeding the limit prompts the moderator to unpin an existing one.
