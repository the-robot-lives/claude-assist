---
id: US-813
title: "Search Hides Blocked Users"
slug: search-respects-blocks
personas: [P-006]
epic: "Search & Find"
priority: must-have
complexity: high
tags: [search, blocks, safety, visibility]
---

# US-813: Search Hides Blocked Users

## User Story

**As a** quiet consumer
**I want to** have blocked users absent from all my search results
**So that** I never encounter accounts I've chosen to avoid

## Acceptance Criteria

- **Given** I have blocked user X
  **When** I search for X by name
  **Then** no result for X appears in any search type (people, posts, channels they own)

- **Given** I search for posts
  **When** a blocked user X authored a matching post
  **Then** that post does not appear in my results

## Notes
Block is bidirectional — if A blocks B, neither sees the other in search.
