---
id: US-807
title: "Filter Post Search by Channel"
slug: filter-search-by-channel
personas: [P-002]
epic: "Search & Find"
priority: should-have
complexity: low
tags: [search, filters, channel, posts]
---

# US-807: Filter Post Search by Channel

## User Story

**As a** niche enthusiast
**I want to** filter post search results to a specific channel
**So that** I can find discussions on a topic without noise from unrelated channels

## Acceptance Criteria

- **Given** I am on the post search results page
  **When** I pick a channel from the channel filter dropdown
  **Then** results narrow to posts in that channel only

- **Given** I clear the channel filter
  **When** the filter is removed
  **Then** all accessible posts matching the query reappear

## Notes
Channel filter dropdown should support typeahead for users who belong to many channels.
