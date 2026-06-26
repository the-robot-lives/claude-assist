---
id: US-914
title: "Mutual Graph Edge Caching Layer"
slug: mutual-graph-edge-cache
personas: [P-003]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: high
tags: [graph, cache, mutuals, edge-cache, redis]
---

# US-914: Mutual Graph Edge Caching Layer

## User Story

**As a** social connector who frequently checks who is in my mutual network
**I want to** have my mutual list load instantly on any screen that queries it
**So that** navigating between profile views and feed doesn't feel sluggish

## Acceptance Criteria

- **Given** I have established mutuals
  **When** any screen requests my 1st-degree mutual list
  **Then** the list is served from an in-memory cache with < 20 ms response time

- **Given** I add or remove a mutual connection
  **When** the relationship change is confirmed
  **Then** the cached edge list is invalidated and refreshed within 1 second

## Notes
Store adjacency lists in Redis sorted sets keyed by user ID. Invalidate lazily on write events via pub/sub. Cache TTL: 10 minutes.
