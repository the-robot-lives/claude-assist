---
id: US-842
title: "Search Performance on Slow Network"
slug: search-performance-slow-network
personas: [P-008]
epic: "Search & Find"
priority: should-have
complexity: high
tags: [search, performance, low-bandwidth, UX]
---

# US-842: Search Performance on Slow Network

## User Story

**As a** accessibility-first user on a slow connection
**I want to** receive fast feedback that my search query was received
**So that** I'm not left wondering whether anything is happening

## Acceptance Criteria

- **Given** I submit a search on a slow connection
  **When** the request is in flight
  **Then** a visible and screen-reader-announced loading indicator appears within 100 ms of submission

- **Given** results take more than 5 seconds
  **When** the timeout occurs
  **Then** a message says "Results are taking longer than expected" with a Retry button and the query preserved

## Notes
The loading indicator must not rely on color alone to convey state; use animation plus text label.
