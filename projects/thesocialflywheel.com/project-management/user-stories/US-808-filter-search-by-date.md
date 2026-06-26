---
id: US-808
title: "Filter Search Results by Date Range"
slug: filter-search-by-date
personas: [P-006]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, filters, date, posts]
---

# US-808: Filter Search Results by Date Range

## User Story

**As a** quiet consumer
**I want to** filter search results to a date range
**So that** I can resurface timely discussions without wading through older content

## Acceptance Criteria

- **Given** I open date filter controls
  **When** I set a start and end date
  **Then** only content created within that range appears

- **Given** I set only a start date
  **When** I apply the filter
  **Then** content from that date through today appears in results

## Notes
The date picker must be fully keyboard-accessible and announce the selected range to screen readers.
