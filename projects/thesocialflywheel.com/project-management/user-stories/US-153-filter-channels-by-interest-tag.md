---
id: US-153
title: "Filter Channels by Interest Tag"
slug: filter-channels-by-interest-tag
personas: [P-002]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, filter, interest-tags, discovery]
---

# US-153: Filter Channels by Interest Tag

## User Story

**As a** Niche Enthusiast
**I want to** filter the channel directory by one or more interest tags
**So that** I can narrow results to the exact topic intersection I care about

## Acceptance Criteria

- **Given** I am viewing the channel directory
  **When** I select one or more interest tags from the filter panel
  **Then** only channels tagged with all selected tags are displayed

- **Given** I have active tag filters applied
  **When** I remove a tag from the filter
  **Then** the directory refreshes immediately to reflect the updated filter set

## Notes
Tags should be presented as a multi-select chip list. Combining this filter with keyword search (US-152) should apply both constraints simultaneously (AND logic).
