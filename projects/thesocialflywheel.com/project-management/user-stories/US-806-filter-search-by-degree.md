---
id: US-806
title: "Filter People Search by Degree"
slug: filter-search-by-degree
personas: [P-003]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, filters, degree, people]
---

# US-806: Filter People Search by Degree

## User Story

**As a** social connector
**I want to** filter people search results by degree
**So that** I can focus on discovering 2nd or 3rd-degree connections I haven't met yet

## Acceptance Criteria

- **Given** I am viewing people search results
  **When** I select degree filter "2nd"
  **Then** only 2nd-degree connections appear in results

- **Given** I apply a degree filter
  **When** no people match that degree
  **Then** the empty state explains the active filter and offers to widen scope

## Notes
Multi-select degree filter (e.g., 2nd + 3rd) should be supported.
