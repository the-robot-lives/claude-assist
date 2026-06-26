---
id: US-847
title: "Filter Search to Image or Video Posts"
slug: filter-to-image-video-posts
personas: [P-006]
epic: "Search & Find"
priority: could-have
complexity: low
tags: [search, filters, images, video, media]
---

# US-847: Filter Search to Image or Video Posts

## User Story

**As a** quiet consumer
**I want to** quickly toggle between image-only and video-only post results
**So that** I can browse visual content streams without reading text posts

## Acceptance Criteria

- **Given** I am on post search results
  **When** I toggle "Images only"
  **Then** posts without images disappear and the result count updates

- **Given** I toggle "Video only"
  **When** results update
  **Then** only posts containing an embedded or attached video appear

## Notes
"Images only" and "Video only" are mutually exclusive; selecting one clears the other.
