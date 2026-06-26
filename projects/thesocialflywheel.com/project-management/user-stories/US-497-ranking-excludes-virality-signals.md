---
id: US-497
title: "Confirm the ranking algorithm excludes virality signals"
slug: ranking-excludes-virality-signals
personas: [P-010, P-001]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [transparency, virality, algorithm, trust]
---

# US-497: Confirm the Ranking Algorithm Excludes Virality Signals

## User Story

**As a** skeptical switcher (P-010)
**I want to** verify through the app's transparency tools that likes, shares, and repost counts do not influence my feed ranking
**So that** I can trust that popular content doesn't crowd out posts from people I actually follow

## Acceptance Criteria

- **Given** a post has 10,000 reactions from outside my graph
  **When** the ranking algorithm scores it
  **Then** its score is identical to an equivalent post with 0 reactions from outside my graph

- **Given** I open the "Why am I seeing this" badge on a high-engagement post
  **When** I read the explanation
  **Then** no engagement metrics (likes, shares, reposts) are listed as ranking signals

- **Given** the ranking transparency page (US-470) is open
  **When** I search for "likes" or "viral"
  **Then** the page explicitly states these signals are not used

## Notes
This is a product integrity requirement, not just a UX requirement; it must be verified via code audit in addition to UI testing.
