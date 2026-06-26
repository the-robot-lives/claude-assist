---
id: US-492
title: "Browse cached feed posts while offline"
slug: browse-cached-feed-offline
personas: [P-006, P-008]
epic: "Feed & Ranking"
priority: could-have
complexity: high
tags: [offline, cache, feed, resilience]
---

# US-492: Browse Cached Feed Posts While Offline

## User Story

**As a** quiet consumer (P-006)
**I want to** continue browsing previously loaded feed posts when I lose internet connectivity
**So that** the app doesn't become completely unusable in low-signal areas

## Acceptance Criteria

- **Given** I loaded the feed while online and then lose connectivity
  **When** I continue scrolling
  **Then** already-loaded posts remain visible without an error screen

- **Given** I am offline and reach the end of cached content
  **When** infinite scroll tries to load more
  **Then** an "You're offline — cached content shown" banner replaces the skeleton loader

- **Given** my connection is restored
  **When** the app detects connectivity
  **Then** the new-post indicator (US-463) fires and I can refresh to load live content

## Notes
Cache stores the last 2 pages (40 posts) per feed session.
