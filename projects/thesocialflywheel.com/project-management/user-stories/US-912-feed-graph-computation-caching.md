---
id: US-912
title: "Cached Feed Ranking Scores for Graph Traversal"
slug: feed-graph-computation-caching
personas: [P-006]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: high
tags: [graph, caching, feed-ranking, scale, mutuals]
---

# US-912: Cached Feed Ranking Scores for Graph Traversal

## User Story

**As a** quiet consumer with a large mutuals network
**I want to** have my personalized feed load quickly even when my graph has thousands of connections
**So that** the app remains fast regardless of how many mutuals I accumulate over time

## Acceptance Criteria

- **Given** my account has 1,000+ mutual connections
  **When** I open the Mutuals feed
  **Then** the feed loads within 3 seconds by using pre-computed ranking scores rather than live graph traversal

- **Given** my ranking cache is stale (> 5 minutes old)
  **When** the feed is served from cache
  **Then** a background job recomputes scores and the feed refreshes silently within the same session

## Notes
Pre-compute per-user feed ranking in an async worker. Cache ranking vectors in Redis with 5-minute TTL. Serve stale-while-revalidate pattern.
