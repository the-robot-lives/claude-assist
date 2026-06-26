---
id: US-152
title: "Search Channels by Keyword"
slug: search-channels-by-keyword
personas: [P-002]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, search, discovery]
---

# US-152: Search Channels by Keyword

## User Story

**As a** Niche Enthusiast
**I want to** search channels by name or keyword
**So that** I can quickly locate communities around a very specific topic without browsing every category

## Acceptance Criteria

- **Given** I am on the Channels discovery page
  **When** I type a keyword into the search field
  **Then** the results update in real time (debounced) showing channels whose name, description, or interest tags match the keyword

- **Given** my search returns no results
  **When** I view the empty state
  **Then** I am offered a link to create a new channel with my search term pre-filled as the channel name

## Notes
Search should be case-insensitive and support partial matching. Minimum query length is 2 characters before results fire.
