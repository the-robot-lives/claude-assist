---
id: US-932
title: "CDN Edge Delivery for All Static and Media Assets"
slug: cdn-static-delivery
personas: [P-009]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: medium
tags: [cdn, edge, media, static-assets, latency]
---

# US-932: CDN Edge Delivery for All Static and Media Assets

## User Story

**As a** creator whose content is viewed by followers across many countries
**I want to** have my uploaded images and videos served from CDN edge nodes close to each viewer
**So that** international viewers get fast media loads without the latency of a single origin server

## Acceptance Criteria

- **Given** a creator uploads an image post
  **When** the image is served to a viewer
  **Then** it is delivered via a CDN edge node with cache headers set (max-age ≥ 365 days for immutable assets)

- **Given** a media asset is deleted
  **When** the deletion is processed
  **Then** the CDN cache for that asset is purged within 60 seconds via cache-invalidation API call

## Notes
Use content-addressed URLs (include hash in path) to make assets immutable. Only mutable resources (profile photo) require active purge. JS/CSS bundles always content-hashed.
