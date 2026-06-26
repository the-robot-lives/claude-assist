---
id: US-198
title: "Search Posts Within a Channel"
slug: search-posts-within-channel
personas: [P-006]
epic: "Interest Channels"
priority: should-have
complexity: medium
tags: [channels, search, posts, feed]
---

# US-198: Search Posts Within a Channel

## User Story

**As a** Quiet Consumer
**I want to** search the post history of a channel I belong to
**So that** I can find specific discussions or reference content without scrolling through the entire feed

## Acceptance Criteria

- **Given** I am inside a channel
  **When** I tap the search icon and enter a query
  **Then** results show posts from that channel whose content matches the query, sorted by relevance with a recency toggle

- **Given** search results are returned
  **When** I tap a result
  **Then** I am taken to that post in context within the channel feed, with the matching terms highlighted

- **Given** I filter the search by subtopic
  **When** the filter is applied
  **Then** only posts assigned to the selected subtopic appear in the results

## Notes
Search scope is limited to the channel the user is currently in. Cross-channel search is a separate feature. Minimum query length: 2 characters. Posts from blocked users are excluded from results.
