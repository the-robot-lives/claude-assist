---
id: US-948
title: "Server-Side Discovery Feed Caching"
slug: discovery-feed-caching
personas: [P-002]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: high
tags: [discovery, feed, caching, server-side, scale]
---

# US-948: Server-Side Discovery Feed Caching

## User Story

**As a** niche enthusiast using the Discovery lane to find new interest channels
**I want to** have the Discovery feed load quickly even during peak usage hours
**So that** platform load spikes don't make finding new content slow or unreliable

## Acceptance Criteria

- **Given** my Discovery feed is requested
  **When** a cached feed snapshot is available and less than 15 minutes old
  **Then** the cached snapshot is returned immediately and a background job refreshes it for the next request

- **Given** no cached snapshot exists for my account segment
  **When** the feed is computed on demand
  **Then** computation completes within 4 seconds or a partial result set is returned with a "load more" cursor

## Notes
Segment users for cache keys by top-3 interest tags to improve cache hit rate without per-user precomputation for all users. Log cache miss rate; target > 80% hit rate during peak hours.
