---
id: US-547
title: "Channel Announcement Pin Badge"
slug: channel-announcement-pin-badge
personas: [P-007]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: low
tags: [pin, announcement, channel-chat, badge]
---

# US-547: Channel Announcement Pin Badge

## User Story

**As a** Channel Moderator (P-007)
**I want to** designate specific messages as "Announcements" with a distinct pin badge
**So that** members immediately notice important updates when they enter the channel

## Acceptance Criteria

- **Given** I pin a message and toggle the "Mark as Announcement" option
  **When** the pin is saved
  **Then** the message gets a highlighted announcement banner (distinct colour from regular pinned messages) and a megaphone icon

- **Given** a channel has at least one announcement message pinned
  **When** a member opens the channel for the first time that day
  **Then** a "New announcement" banner appears at the top of the chat with a direct jump link

- **Given** an announcement is unpinned by a moderator
  **When** the unpin is confirmed
  **Then** the banner disappears for all members and the message reverts to a normal chat message

## Notes
Announcement badges are separate from the general pinned-messages list (US-531). A channel can have at most 3 active announcements at once.
