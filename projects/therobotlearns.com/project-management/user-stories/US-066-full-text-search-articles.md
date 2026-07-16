---
id: US-066
title: "Full-Text Search Across KB Articles"
slug: full-text-search-articles
personas: [P-001, P-002, P-003]
epic: "Search & Discovery"
priority: should-have
complexity: medium
tags: [search, full-text, cli]
---

# US-066: Full-Text Search Across KB Articles

## User Story

**As a** staff backend engineer with hundreds of accumulated articles
**I want to** search the full text of my KB articles, not just titles or tags
**So that** I can find something I know I wrote down even if I don't remember which article it's in

## Acceptance Criteria

- **Given** a search term that only appears in the body of one article, not its title or tags
  **When** I run a full-text search for that term
  **Then** that article is returned with the matching passage shown as context

- **Given** a search term matches multiple articles
  **When** search results are returned
  **Then** they're ranked by relevance, not just file order, with the best match first

- **Given** I'm an SRE searching across a KB that spans many unrelated tool domains
  **When** I scope the search to a tag or category
  **Then** only matching articles within that scope are returned

- **Given** no articles match my search term
  **When** the search completes
  **Then** I get a clear "no results" response rather than an empty silent output

## Notes
Should be usable both interactively and as a scriptable command for chaining with other CLI tools.
