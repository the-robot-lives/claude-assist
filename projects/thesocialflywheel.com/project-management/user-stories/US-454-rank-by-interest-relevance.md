---
id: US-454
title: "Rank feed posts by interest relevance"
slug: rank-by-interest-relevance
personas: [P-002, P-006]
epic: "Feed & Ranking"
priority: must-have
complexity: high
tags: [ranking, interest, algorithm]
---

# US-454: Rank Feed Posts by Interest Relevance

## User Story

**As a** quiet consumer (P-006)
**I want to** see posts matching my subscribed channels ranked higher
**So that** my feed stays focused on topics I actually care about

## Acceptance Criteria

- **Given** I subscribe to channels #lo-fi-music and #urban-gardening
  **When** two 2nd-degree posts appear — one in #lo-fi-music and one in #cooking
  **Then** the #lo-fi-music post ranks higher in my feed

- **Given** I have no channel subscriptions
  **When** the feed loads
  **Then** interest relevance is treated as neutral and degree+recency govern ranking

## Notes
Interest relevance is computed per-channel subscription weight, not keyword matching.
