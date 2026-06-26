---
id: US-464
title: "Infinite scroll through the feed"
slug: infinite-scroll-feed
personas: [P-006, P-002]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [infinite-scroll, pagination, feed, performance]
---

# US-464: Infinite Scroll Through the Feed

## User Story

**As a** quiet consumer (P-006)
**I want to** scroll continuously without manually tapping a "load more" button
**So that** my browsing experience feels seamless and uninterrupted

## Acceptance Criteria

- **Given** I reach the bottom of the currently loaded feed page
  **When** the next page of posts is available
  **Then** it loads automatically and appends below the current content within 500 ms

- **Given** I am on a slow connection
  **When** the next page is loading
  **Then** a skeleton loader appears at the bottom rather than a blank area

- **Given** I have scrolled through all available posts within my 4th-degree graph
  **When** no further posts exist
  **Then** the end-of-feed state (see US-469) is shown

## Notes
Page size is 20 posts; prefetch triggers at 80% scroll depth.
