---
id: US-071
title: "Related-Article Suggestions While Reading"
slug: related-article-suggestions
personas: [P-002, P-005]
epic: "Search & Discovery"
priority: could-have
complexity: medium
tags: [recommendations, related-content]
---

# US-071: Related-Article Suggestions While Reading

## User Story

**As a** mid-level developer reading through a KB article
**I want to** see suggestions for related articles while I'm reading
**So that** I can naturally follow my curiosity into connected topics without stopping to search

## Acceptance Criteria

- **Given** I open an article that shares tags or topic overlap with other articles
  **When** the article is displayed
  **Then** a short list of related articles is shown alongside it, ranked by relevance

- **Given** an article has no meaningfully related content elsewhere in the KB
  **When** it's displayed
  **Then** the related-articles section is omitted rather than showing weak or unrelated matches

- **Given** I'm a career-switcher junior dev following related links across several articles
  **When** I navigate from suggestion to suggestion
  **Then** each new article shows its own related suggestions, letting me chain exploration naturally

- **Given** a related article was archived or pruned since the suggestion was cached
  **When** it would otherwise be suggested
  **Then** it's excluded from the list rather than pointing to a missing file

## Notes
Related-article logic can share underlying similarity scoring with duplicate detection ([[US-058]]), tuned for looser relatedness rather than near-duplication.
