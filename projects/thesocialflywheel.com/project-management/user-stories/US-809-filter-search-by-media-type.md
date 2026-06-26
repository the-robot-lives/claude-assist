---
id: US-809
title: "Filter Search by Media Type"
slug: filter-search-by-media-type
personas: [P-006]
epic: "Search & Find"
priority: could-have
complexity: low
tags: [search, filters, media, images, video]
---

# US-809: Filter Search by Media Type

## User Story

**As a** quiet consumer
**I want to** filter post results to image-only or video-only posts
**So that** I can browse visual content without reading text threads

## Acceptance Criteria

- **Given** I open the media filter
  **When** I select "Images"
  **Then** only posts containing at least one image appear in results

- **Given** I select "Video"
  **When** results reload
  **Then** text-only posts are excluded and the result count updates

## Notes
"Images" and "Video" filters are mutually exclusive toggles; selecting one clears the other.
