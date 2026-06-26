---
id: US-524
title: "Search Messages Across Conversations"
slug: search-messages-across-conversations
personas: [P-001]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: high
tags: [search, message-history, discovery]
---

# US-524: Search Messages Across Conversations

## User Story

**As a** Bridge-Builder (P-001)
**I want to** search for keywords across all my DMs and channel chats
**So that** I can quickly find specific information or links shared in past conversations

## Acceptance Criteria

- **Given** I open the global search bar and switch to the "Messages" scope
  **When** I type a keyword
  **Then** results appear grouped by conversation, showing the matching message with surrounding context and a timestamp, within 2 seconds

- **Given** search results are displayed
  **When** I tap a result
  **Then** I am taken directly to that message in its conversation with it highlighted

- **Given** I search using a filter (e.g., "from: @username" or "in: #channel-name")
  **When** results are returned
  **Then** only messages matching both the keyword and the filter are shown

## Notes
Messages in conversations with users I have blocked do not appear in search results.
