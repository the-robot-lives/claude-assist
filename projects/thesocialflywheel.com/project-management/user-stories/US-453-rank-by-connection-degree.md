---
id: US-453
title: "Rank feed posts by connection degree"
slug: rank-by-connection-degree
personas: [P-001, P-003]
epic: "Feed & Ranking"
priority: must-have
complexity: high
tags: [ranking, degree, algorithm]
---

# US-453: Rank Feed Posts by Connection Degree

## User Story

**As a** social connector (P-003)
**I want to** see posts from closer connections ranked higher by default
**So that** my most trusted network's content rises to the top naturally

## Acceptance Criteria

- **Given** the home feed is loaded
  **When** two posts have identical interest relevance and recency
  **Then** the post from the lower-degree connection (e.g., 1st) appears above the post from the higher-degree connection (e.g., 3rd)

- **Given** a post from a 4th-degree connection is highly relevant to my top interest
  **When** it is ranked
  **Then** the interest boost can elevate it above a 3rd-degree post with low relevance, but never above a mutual's post of equal relevance

## Notes
Degree is the primary ranking signal; interest and recency are secondary multipliers.
