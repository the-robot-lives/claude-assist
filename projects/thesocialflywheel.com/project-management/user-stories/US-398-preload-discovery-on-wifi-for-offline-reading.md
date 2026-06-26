---
id: US-398
title: "Preload Discovery on WiFi for Offline Reading"
slug: preload-discovery-on-wifi-for-offline-reading
personas: [P-006]
epic: "Discovery Engine"
priority: could-have
complexity: medium
tags: [discovery, low-bandwidth, offline]
---

# US-398: Preload Discovery on WiFi for Offline Reading

## User Story

**As a** Quiet Consumer
**I want to** have the app preload a batch of discovery items including text and images when I am on Wi-Fi
**So that** I can read discovery content while commuting or in areas with poor connectivity

## Acceptance Criteria

- **Given** my device is connected to Wi-Fi and the app is in the background
  **When** the background prefetch job runs
  **Then** up to 20 discovery items including their text and images are cached for offline access

- **Given** I open the app while offline
  **When** I scroll to the discovery section of the feed
  **Then** preloaded discovery items render from cache with a banner indicating I am viewing cached content

## Notes
Preloaded content should expire after 24 hours to avoid showing very stale discovery items.
