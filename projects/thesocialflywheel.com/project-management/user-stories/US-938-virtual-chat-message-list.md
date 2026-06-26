---
id: US-938
title: "Virtualized Chat Message List for High-Volume Channels"
slug: virtual-chat-message-list
personas: [P-007]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: high
tags: [virtualization, chat, dom, performance, channels]
---

# US-938: Virtualized Chat Message List for High-Volume Channels

## User Story

**As a** channel moderator in a channel that receives thousands of messages per day
**I want to** scroll through the message history smoothly without the browser slowing down
**So that** I can review past messages and moderate effectively even in very active channels

## Acceptance Criteria

- **Given** I open a channel with more than 500 messages in the current session
  **When** I scroll through the message list
  **Then** scrolling remains at 60 fps and no more than 80 message DOM nodes are rendered at once

- **Given** I scroll to the top of the visible window
  **When** more historical messages need to be loaded
  **Then** older messages are fetched and prepended without jumping my scroll position

## Notes
Use a reversed virtual list to pin scroll to bottom. Maintain scroll anchor on prepend via `overflow-anchor`. Test on low-end devices with CPU throttle 4x.
