---
id: US-930
title: "Route-Level Code Splitting for Faster Initial Bundle"
slug: code-splitting-route-chunks
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: medium
tags: [code-splitting, bundle-size, javascript, performance]
---

# US-930: Route-Level Code Splitting for Faster Initial Bundle

## User Story

**As a** skeptical switcher who opened the app to check the feed
**I want to** have the initial JavaScript bundle be as small as possible
**So that** the app starts up quickly even on a slow connection without loading code I haven't needed yet

## Acceptance Criteria

- **Given** I open the app for the first time
  **When** the initial JS bundle is downloaded
  **Then** the main bundle is under 150 KB gzipped, with all non-feed routes loaded lazily

- **Given** I navigate to the channel explore page for the first time
  **When** the route chunk is requested
  **Then** it loads in under 1 second on a 4G connection and a loading skeleton is shown during the transition

## Notes
Use dynamic `import()` at route boundaries. Analyze bundle with webpack-bundle-analyzer each release. Enforce budget via CI bundle-size check that fails builds exceeding limits.
