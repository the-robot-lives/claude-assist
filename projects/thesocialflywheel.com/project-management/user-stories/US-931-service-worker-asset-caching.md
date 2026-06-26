---
id: US-931
title: "Service Worker Static Asset Caching"
slug: service-worker-asset-caching
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: medium
tags: [service-worker, caching, static-assets, repeat-visit]
---

# US-931: Service Worker Static Asset Caching

## User Story

**As a** skeptical switcher who opens the app daily
**I want to** have static assets (icons, fonts, app shell JS/CSS) served from the service worker cache on repeat visits
**So that** subsequent app loads feel instant even on a slow connection

## Acceptance Criteria

- **Given** I have visited the app at least once
  **When** I open the app again with a slow connection
  **Then** the app shell renders from the service worker cache within 300 ms, before any network requests complete

- **Given** a new app version is deployed
  **When** the service worker detects updated assets
  **Then** it caches the new version in the background and prompts me to reload to get the update

## Notes
Use stale-while-revalidate strategy for the app shell. Cache-bust with content hash in filenames. Show "Update available" toast, not forced reload. Skip waiting only on user confirmation.
