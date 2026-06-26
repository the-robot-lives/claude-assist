---
id: US-903
title: "Feed Lazy-Loading and Infinite Pagination"
slug: feed-lazy-loading-pagination
personas: [P-006]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: medium
tags: [lazy-loading, pagination, feed, infinite-scroll]
---

# US-903: Feed Lazy-Loading and Infinite Pagination

## User Story

**As a** quiet consumer who browses the feed for long sessions
**I want to** have new posts loaded automatically as I scroll near the bottom
**So that** I never wait for a manual "load more" action and the page stays responsive

## Acceptance Criteria

- **Given** I am viewing the Mutuals feed with 20 posts loaded
  **When** I scroll to within 3 posts of the bottom
  **Then** the next page of posts begins fetching in the background without a visible loader blocking the viewport

- **Given** a page fetch is in flight
  **When** the data arrives
  **Then** posts are appended to the list without any scroll-position jump

## Notes
Use intersection observer for trigger. Keep DOM node count manageable via virtual list recycling for sessions exceeding 200 posts.
