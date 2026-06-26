---
id: US-936
title: "Prefetch Next Feed Page on Idle"
slug: prefetch-next-feed-page
personas: [P-006]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: low
tags: [prefetch, feed, idle, performance, perceived-speed]
---

# US-936: Prefetch Next Feed Page on Idle

## User Story

**As a** quiet consumer who reads every post in the feed
**I want to** have the next page of posts already loaded when I reach the bottom of the current page
**So that** there is no perceptible loading pause between pages

## Acceptance Criteria

- **Given** I am viewing a feed page with items loaded
  **When** I have read 70% of the currently loaded items and the device is idle
  **Then** the next page fetch begins in the background using `requestIdleCallback`

- **Given** the prefetch is complete
  **When** I reach the bottom of the loaded content
  **Then** the prefetched items are appended instantly with no visible loader

## Notes
Cancel prefetch if Data Saver mode is active or battery is below 15%. Prefetch only 1 page ahead to limit speculative data usage.
