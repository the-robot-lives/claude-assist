---
id: US-377
title: "Low Data Mode Prefetches Text Only"
slug: low-data-mode-prefetches-text-only
personas: [P-006]
epic: "Discovery Engine"
priority: should-have
complexity: medium
tags: [discovery, low-bandwidth, offline]
---

# US-377: Low Data Mode Prefetches Text Only

## User Story

**As a** Quiet Consumer
**I want to** have the app prefetch only text content for discovery items when Low Data Mode is enabled
**So that** I can browse discovery content offline or on a weak connection without exhausting my data plan

## Acceptance Criteria

- **Given** I have enabled Low Data Mode in app settings
  **When** the app prefetches discovery items in the background
  **Then** only text and metadata are downloaded; images and video are excluded from the prefetch

- **Given** I am offline and open the feed
  **When** the app displays prefetched discovery items
  **Then** text-only discovery cards are shown with a placeholder indicating media is unavailable offline

## Notes
Prefetch should occur only on Wi-Fi unless the user explicitly opts into cellular prefetching.
