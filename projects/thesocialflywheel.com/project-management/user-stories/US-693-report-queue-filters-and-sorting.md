---
id: US-693
title: "Report Queue Filters and Sorting"
slug: report-queue-filters-and-sorting
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: low
tags: [moderation, queue, ux]
---

# US-693: Report Queue Filters and Sorting

## User Story

**As a** channel moderator with a large backlog of reports
**I want to** filter and sort the report queue by multiple criteria
**So that** I can focus on the cases most relevant to my current moderation session

## Acceptance Criteria

- **Given** I am viewing the report queue
  **When** I apply a filter (Status: New / In Review / Resolved, Reason Category, Content Type: Post / Profile / Comment, Assigned Mod)
  **Then** the queue updates instantly to show only matching cases without a full page reload

- **Given** I apply a sort (Oldest first, Most-reported first, Severity: High to Low)
  **When** the sort is applied
  **Then** all cases in the current filtered set reorder accordingly and the active sort is visually indicated

- **Given** I close and reopen the mod panel within the same session
  **When** the queue loads
  **Then** my last-used filter and sort settings are restored

## Notes
Default sort on first open should be Severity high-to-low to surface the most urgent cases immediately.
