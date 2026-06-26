---
id: US-506
title: "Typing Indicator in Channel"
slug: typing-indicator-in-channel
personas: [P-007]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: low
tags: [channel-chat, typing-indicator, presence]
---

# US-506: Typing Indicator in Channel

## User Story

**As a** Channel Moderator (P-007)
**I want to** see a condensed typing indicator when one or more members are composing messages in the channel
**So that** I can gauge activity level and avoid posting conflicting moderation messages

## Acceptance Criteria

- **Given** one member is typing in a channel
  **When** other members view the chat
  **Then** "[Name] is typing…" appears at the bottom of the message list

- **Given** three or more members are typing simultaneously
  **When** other members view the chat
  **Then** the indicator collapses to "Several people are typing…" to avoid clutter

## Notes
Do not show the full list of typists when there are more than two to protect privacy in large channels.
