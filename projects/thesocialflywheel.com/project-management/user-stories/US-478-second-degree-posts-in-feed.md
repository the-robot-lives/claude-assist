---
id: US-478
title: "See posts from 2nd-degree connections in feed"
slug: second-degree-posts-in-feed
personas: [P-001, P-003]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [degree, 2nd-degree, feed, network]
---

# US-478: See Posts from 2nd-Degree Connections in Feed

## User Story

**As a** bridge-builder (P-001)
**I want to** see interest-relevant posts from friends-of-mutuals (2nd degree)
**So that** I can discover people and content one step beyond my immediate network

## Acceptance Criteria

- **Given** a 2nd-degree user posts in a channel I subscribe to
  **When** the feed loads
  **Then** their post appears with a "2nd degree" label and a degree discount applied to its rank score

- **Given** I tap the "2nd degree" label
  **When** the info sheet opens
  **Then** I can see which mutual connects me to this person (e.g., "Via @casey")

## Notes
2nd-degree posts require at least one shared channel subscription to appear; they never appear in the Mutuals lane.
