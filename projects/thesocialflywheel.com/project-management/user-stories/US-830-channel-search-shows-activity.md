---
id: US-830
title: "Channel Search Shows Member Count and Activity"
slug: channel-search-shows-activity
personas: [P-002]
epic: "Search & Find"
priority: should-have
complexity: low
tags: [search, channels, metadata, activity]
---

# US-830: Channel Search Shows Member Count and Activity

## User Story

**As a** niche enthusiast
**I want to** see member count and last-activity date in channel search results
**So that** I can gauge whether a channel is active before joining

## Acceptance Criteria

- **Given** I view channel search results
  **When** a channel card renders
  **Then** it shows member count and last-activity ("Active today", "Last active X days ago")

- **Given** a channel has had no posts in over 60 days
  **When** its card renders
  **Then** it displays a "Quiet" badge to signal low activity

## Notes
Activity data reflects only posts visible to the searching user.
