---
id: US-812
title: "Save a Search for Later"
slug: save-a-search
personas: [P-002]
epic: "Search & Find"
priority: could-have
complexity: medium
tags: [search, saved, bookmarks]
---

# US-812: Save a Search for Later

## User Story

**As a** niche enthusiast
**I want to** save a search query with its current filters
**So that** I can revisit the same filtered view without reconfiguring it each time

## Acceptance Criteria

- **Given** I have active search results with filters applied
  **When** I click "Save Search"
  **Then** the search is stored in My Saved Searches with an auto-generated label I can edit

- **Given** I open Saved Searches
  **When** I click a saved entry
  **Then** the search bar and filters restore to the saved state and results reload

## Notes
Saved searches should be accessible from the search bar landing state and from a dedicated Settings page.
