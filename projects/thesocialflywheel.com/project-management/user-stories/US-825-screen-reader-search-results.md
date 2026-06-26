---
id: US-825
title: "Screen Reader Announcements for Search Results"
slug: screen-reader-search-results
personas: [P-008]
epic: "Search & Find"
priority: must-have
complexity: high
tags: [search, screen-reader, ARIA, accessibility]
---

# US-825: Screen Reader Announcements for Search Results

## User Story

**As a** accessibility-first user
**I want to** have screen readers announce the count and type of search results automatically
**So that** I know what was found immediately after submitting a search

## Acceptance Criteria

- **Given** I submit a search
  **When** results load
  **Then** an ARIA live region with `role="status"` announces "Found 12 channels, 3 people, and 7 posts for [query]"

- **Given** results are empty
  **When** the empty state renders
  **Then** the live region announces the empty state message without requiring me to navigate to it

## Notes
Live region must use `aria-live="polite"` to avoid interrupting ongoing announcements.
