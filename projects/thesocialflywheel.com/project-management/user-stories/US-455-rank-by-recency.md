---
id: US-455
title: "Rank feed posts by recency"
slug: rank-by-recency
personas: [P-006, P-003]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [ranking, recency, algorithm]
---

# US-455: Rank Feed Posts by Recency

## User Story

**As a** quiet consumer (P-006)
**I want to** have post age factor into ranking so stale content doesn't dominate
**So that** my feed feels current even when I haven't visited in a while

## Acceptance Criteria

- **Given** two posts from the same mutual with equal engagement
  **When** one was posted 1 hour ago and the other 48 hours ago
  **Then** the 1-hour post ranks higher

- **Given** I enable the "Recency" sort override (see US-459)
  **When** the feed re-renders
  **Then** recency becomes the primary sort key, overriding degree and interest weights

## Notes
Recency decay is a configurable half-life; default is 24 hours.
