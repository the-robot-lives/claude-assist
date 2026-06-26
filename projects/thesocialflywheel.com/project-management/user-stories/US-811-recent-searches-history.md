---
id: US-811
title: "View Recent Search History"
slug: recent-searches-history
personas: [P-003]
epic: "Search & Find"
priority: should-have
complexity: low
tags: [search, history, recents]
---

# US-811: View Recent Search History

## User Story

**As a** social connector
**I want to** see my recent searches when I open the search bar
**So that** I can quickly re-run a search I did earlier

## Acceptance Criteria

- **Given** I have performed previous searches
  **When** I click the search bar without typing
  **Then** my last 10 searches appear as a list with a clock icon

- **Given** recent searches are shown
  **When** I click one
  **Then** the search executes immediately with the stored query and last-used filter state

## Notes
Searches are stored per account, not per device, to support sync across sessions.
