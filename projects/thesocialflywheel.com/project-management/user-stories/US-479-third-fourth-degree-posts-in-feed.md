---
id: US-479
title: "See limited posts from 3rd and 4th-degree connections"
slug: third-fourth-degree-posts-in-feed
personas: [P-001, P-002]
epic: "Feed & Ranking"
priority: should-have
complexity: medium
tags: [degree, 3rd-degree, 4th-degree, feed, network]
---

# US-479: See Limited Posts from 3rd and 4th-Degree Connections

## User Story

**As a** bridge-builder (P-001)
**I want to** occasionally see posts from 3rd and 4th-degree connections when they are highly relevant to my channels
**So that** the feed has breadth while the 4th-degree limit keeps content within a trusted graph

## Acceptance Criteria

- **Given** a 3rd-degree user posts in my top-interest channel
  **When** the post's combined degree+interest score exceeds a threshold
  **Then** it appears in the feed with a "3rd degree" label and a heavier degree discount than 2nd-degree posts

- **Given** a user is beyond 4th degree
  **When** the ranking algorithm evaluates their post
  **Then** it is excluded from all feed lanes regardless of interest or recency score

## Notes
4th-degree is the hard cutoff; no exceptions for virality or trending signals.
