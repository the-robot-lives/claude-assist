---
id: US-848
title: "Post Search Results Show Content Snippet"
slug: search-results-content-snippet
personas: [P-006]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, posts, snippet, preview, UX]
---

# US-848: Post Search Results Show Content Snippet

## User Story

**As a** quiet consumer
**I want to** see a text snippet with the matched keyword highlighted in each post result
**So that** I can judge relevance before clicking through

## Acceptance Criteria

- **Given** post search results appear
  **When** a result card renders
  **Then** a 2–3 line snippet of the post body appears with the search keyword bolded inline

- **Given** the snippet is rendered
  **When** I navigate to it with a screen reader
  **Then** the highlighted keyword is announced with context (e.g., "Contains: photography")

## Notes
Snippets should be truncated intelligently around the matched term, not simply the first 150 characters.
