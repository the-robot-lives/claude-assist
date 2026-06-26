---
id: US-538
title: "Scroll Back Through Chat History"
slug: scroll-back-through-chat-history
personas: [P-002]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [history, pagination, channel-chat]
---

# US-538: Scroll Back Through Chat History

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** scroll up through a channel's full message history
**So that** I can catch up on discussions that happened while I was away

## Acceptance Criteria

- **Given** I open a channel chat
  **When** I scroll up past the initial load of 50 messages
  **Then** older messages are loaded incrementally in batches of 50 without any visible jump or loss of scroll position

- **Given** I have scrolled far up in history
  **When** I tap a "Jump to latest" button that appears
  **Then** I am taken instantly to the most recent message

- **Given** the channel was created more than a year ago
  **When** I scroll back to the oldest messages
  **Then** a "Beginning of channel history" divider is shown and no further loading is attempted

## Notes
Lazy loading should use virtualized rendering to keep DOM size manageable for channels with thousands of messages.
