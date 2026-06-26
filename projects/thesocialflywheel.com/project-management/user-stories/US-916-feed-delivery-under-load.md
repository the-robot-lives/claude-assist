---
id: US-916
title: "Feed Update Push Under Sustained Write Load"
slug: feed-delivery-under-load
personas: [P-006]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: high
tags: [feed, real-time, push, scale, fanout]
---

# US-916: Feed Update Push Under Sustained Write Load

## User Story

**As a** quiet consumer following several high-volume channels
**I want to** receive feed updates with acceptable latency even when the platform is busy
**So that** I see new content without having to manually refresh the page

## Acceptance Criteria

- **Given** a post is published to a channel I follow
  **When** the platform is handling 10,000 concurrent write operations per second
  **Then** my feed update is pushed within 10 seconds of the post going live

- **Given** feed push is backlogged
  **When** my client reconnects or pulls
  **Then** I receive a catch-up batch of missed updates rather than missing them silently

## Notes
Use a fanout-on-read strategy for users with very large follower-set channels. Fanout-on-write for smaller channels. Switch threshold configurable.
