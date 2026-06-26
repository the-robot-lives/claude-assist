---
id: US-833
title: "Combine Multiple Search Filters Simultaneously"
slug: combine-multiple-search-filters
personas: [P-002]
epic: "Search & Find"
priority: should-have
complexity: high
tags: [search, filters, combined, advanced]
---

# US-833: Combine Multiple Search Filters Simultaneously

## User Story

**As a** niche enthusiast
**I want to** apply several filters at once (degree + channel + date + media type)
**So that** I can narrow searches to exactly the slice of content I need

## Acceptance Criteria

- **Given** I apply degree=2nd, channel=Photography, date=last week
  **When** results update
  **Then** only posts matching all three constraints appear

- **Given** multiple filters are active
  **When** I view the filter bar
  **Then** each active filter appears as a removable chip so I can clear them individually

## Notes
Chips must include an accessible label read by screen readers, e.g., "Remove degree filter: 2nd."
