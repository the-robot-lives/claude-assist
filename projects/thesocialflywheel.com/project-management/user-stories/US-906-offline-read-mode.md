---
id: US-906
title: "Offline Read Mode for Recently Viewed Content"
slug: offline-read-mode
personas: [P-006]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: medium
tags: [offline, service-worker, cache, pwa]
---

# US-906: Offline Read Mode for Recently Viewed Content

## User Story

**As a** quiet consumer who commutes through areas with no signal
**I want to** be able to read recently loaded feed posts and channel messages while offline
**So that** I have something to browse even when connectivity drops

## Acceptance Criteria

- **Given** I previously loaded the Mutuals feed while online
  **When** I go offline and open the feed
  **Then** up to 50 of the most recently viewed posts are readable from the service-worker cache

- **Given** I am offline and try to like or reply to a post
  **When** I perform the action
  **Then** a toast informs me the action will be sent when I reconnect, and it is queued

## Notes
Use Cache API + Background Sync API. Cached content must be clearly labelled with its timestamp to prevent confusion with live content.
