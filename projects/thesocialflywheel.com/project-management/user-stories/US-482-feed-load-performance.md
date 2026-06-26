---
id: US-482
title: "Load the feed within 2 seconds on average connections"
slug: feed-load-performance
personas: [P-006, P-003]
epic: "Feed & Ranking"
priority: must-have
complexity: high
tags: [performance, loading, feed, speed]
---

# US-482: Load the Feed Within 2 Seconds on Average Connections

## User Story

**As a** quiet consumer (P-006)
**I want to** see the first page of my feed within 2 seconds on a typical 4G connection
**So that** the app feels responsive and doesn't frustrate me on mobile

## Acceptance Criteria

- **Given** I open the app on a 4G connection (simulated 20 Mbps, 50 ms RTT)
  **When** the home feed view loads
  **Then** the first 10 posts are visible within 2 seconds of navigation

- **Given** the feed is loading
  **When** data is in flight
  **Then** skeleton loaders render within 100 ms so the layout doesn't jump when posts arrive

## Notes
Performance targets are measured at p75 (75th percentile) in CI synthetic tests.
