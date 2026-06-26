---
id: US-835
title: "Clear All Recent Searches at Once"
slug: clear-all-recent-searches
personas: [P-006]
epic: "Search & Find"
priority: could-have
complexity: low
tags: [search, history, clear-all, privacy]
---

# US-835: Clear All Recent Searches at Once

## User Story

**As a** quiet consumer
**I want to** delete all my recent search history in one action
**So that** I can quickly clear my search activity for privacy

## Acceptance Criteria

- **Given** recent searches are displayed
  **When** I click "Clear all"
  **Then** a confirmation dialog asks me to confirm, and upon confirmation all entries are deleted

- **Given** all recent searches are cleared
  **When** I open the search bar again
  **Then** the recent searches section does not appear

## Notes
"Clear all" should also clear server-side history so it doesn't re-sync from another device.
