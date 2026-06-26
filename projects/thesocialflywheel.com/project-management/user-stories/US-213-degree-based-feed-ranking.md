---
id: US-213
title: "Degree-Based Feed Ranking"
slug: degree-based-feed-ranking
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: high
tags: [feed, degrees, ranking]
---

# US-213: Degree-Based Feed Ranking

## User Story

**As a** Social Connector (P-003)
**I want to** see posts from closer degree mutuals ranked higher in my feed
**So that** the content most relevant to my immediate circle surfaces before distant connections

## Acceptance Criteria

- **Given** my feed contains posts from 1st, 2nd, and 3rd-degree mutuals
  **When** the feed is rendered
  **Then** 1st-degree posts are weighted highest, 2nd-degree next, and 3rd-degree lower, all else being equal (recency, engagement)

- **Given** two posts have equal recency and engagement
  **When** they are ranked
  **Then** the post from the closer-degree mutual always ranks above the farther-degree one

- **Given** I reach the end of 1st-degree content
  **When** the feed continues
  **Then** 2nd-degree interest-filtered content begins, clearly delineated if the user has degree grouping enabled

## Notes
Degree weighting is a multiplier applied before recency and engagement signals, not a hard partition. Algorithm details are owned by the feed ranking service.
