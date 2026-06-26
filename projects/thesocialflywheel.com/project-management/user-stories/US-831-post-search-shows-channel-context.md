---
id: US-831
title: "Post Search Results Show Channel Context"
slug: post-search-shows-channel-context
personas: [P-006]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, posts, channel, context]
---

# US-831: Post Search Results Show Channel Context

## User Story

**As a** quiet consumer
**I want to** see which channel each post result came from
**So that** I can decide whether to click through based on the source channel

## Acceptance Criteria

- **Given** post search results appear
  **When** I view a result card
  **Then** the originating channel name and icon appear prominently on the card

- **Given** I click the channel name on a post result
  **When** navigation occurs
  **Then** I go to the channel overview, not the individual post

## Notes
Channel icon serves as a secondary navigation target alongside the post link.
