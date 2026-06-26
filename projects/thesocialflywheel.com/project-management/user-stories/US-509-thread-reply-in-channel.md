---
id: US-509
title: "Thread a Reply in Channel"
slug: thread-reply-in-channel
personas: [P-002]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [channel-chat, threaded-replies, organization]
---

# US-509: Thread a Reply in Channel

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** reply directly to a specific channel message in a thread
**So that** side discussions do not clutter the main chat timeline

## Acceptance Criteria

- **Given** I long-press or hover a channel message
  **When** I select "Reply in thread"
  **Then** a thread panel opens anchored to that message and my reply is scoped to that thread

- **Given** a message has active thread replies
  **When** I view the main channel timeline
  **Then** the original message shows a thread reply count and avatar stack; clicking it opens the thread panel

- **Given** I post a thread reply
  **When** the reply is sent
  **Then** I can opt to also share it to the main channel with a checkbox ("Also post to channel")

## Notes
Threads should support up to 500 replies. Beyond that, a new thread should be suggested.
