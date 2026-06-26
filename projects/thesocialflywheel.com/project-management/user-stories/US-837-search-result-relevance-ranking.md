---
id: US-837
title: "Search Results Ranked by Relevance"
slug: search-result-relevance-ranking
personas: [P-002]
epic: "Search & Find"
priority: should-have
complexity: high
tags: [search, ranking, relevance, algorithm]
---

# US-837: Search Results Ranked by Relevance

## User Story

**As a** niche enthusiast
**I want to** have search results ranked by relevance to my interests and network
**So that** the most useful results appear at the top

## Acceptance Criteria

- **Given** I search for a topic
  **When** results appear
  **Then** channels I actively engage with (commented, reacted) rank higher than channels I have never visited

- **Given** two equally relevant posts exist
  **When** ranking is applied
  **Then** the post from a closer-degree author ranks higher than one from a more distant connection

## Notes
Ranking signals include: engagement history, degree proximity, post recency, and channel membership.
