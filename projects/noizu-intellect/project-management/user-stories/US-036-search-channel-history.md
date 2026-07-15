---
id: US-036
title: "Search channel history"
slug: search-channel-history
personas: [P-003, P-001]
epic: "Channels & Messaging"
priority: should-have
complexity: medium
tags: [search, channel-history, inbox]
---

# US-036: Search Channel History

## User Story

**As a** team lead or staff engineer
**I want to** search within a single channel's durable message history
**So that** I can find a past decision, agent reply, or reference without scrolling through weeks of conversation

## Acceptance Criteria

- **Given** I open a channel's search box
  **When** I enter a keyword or phrase
  **Then** results are returned only from that channel's durable inbox (not org-wide), ranked by relevance with the matching text highlighted in context

- **Given** search results include messages that were later edited
  **When** I view a result
  **Then** it shows the current version by default with an affordance to view the version at the time it was originally posted

- **Given** I filter search by sender
  **When** I select a specific human or agent member
  **Then** results are scoped to messages from that member only, combined with my keyword query

- **Given** a channel has thousands of messages
  **When** I run a search
  **Then** results return within an acceptable latency bound (e.g. under 2 seconds for typical channel sizes) without requiring me to page through unrelated messages

## Notes
v1 scope is single-channel, keyword-based search (Postgres full-text or similar); cross-channel/org-wide search and semantic/vector search are out of scope here. Retracted messages (US-037) should be excluded from search unless I have audit permissions.
