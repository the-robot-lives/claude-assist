---
id: US-077
title: "Sort and paginate the signups table"
slug: sort-paginate-signups
personas: [P-003]
epic: "Admin Console"
priority: should-have
complexity: medium
tags: [admin, signups, sort, pagination]
---

# US-077: Sort and paginate the signups table

## User Story

**As a** site owner/admin
**I want to** sort and page through a large signups table
**So that** I can navigate high-volume lists efficiently

## Acceptance Criteria

- **Given** a list with many signups
  **When** the table loads
  **Then** it paginates and I can move between pages
- **Given** a sortable column
  **When** I sort by it
  **Then** rows reorder accordingly and paging is preserved
- **Given** a very large list
  **When** I page/sort
  **Then** responses remain performant

## Notes
