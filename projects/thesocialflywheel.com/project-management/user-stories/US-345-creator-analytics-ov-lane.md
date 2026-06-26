---
id: US-345
title: "Creator Analytics: Opposing-View Lane Reach"
slug: creator-analytics-ov-lane
personas: [P-009]
epic: "Opposing-Views Lane"
priority: could-have
complexity: high
tags: [opposing-views, creator, analytics, reach]
---

# US-345: Creator Analytics: Opposing-View Lane Reach

## User Story

**As a** creator
**I want to** see how many users encountered my post through the Opposing-Views Lane versus other sources
**So that** I can understand whether my content is reaching people who hold different views and calibrate my posting strategy accordingly

## Acceptance Criteria

- **Given** my post has appeared in other users' Opposing-Views Lanes
  **When** I view post analytics
  **Then** I see an "Opposing-Views Lane" reach metric showing impressions from that context

- **Given** the metric is shown
  **When** I view the breakdown
  **Then** the count reflects unique users reached via the lane, not total impressions, and is not attributed to specific individuals

## Notes
Privacy: user-level attribution must never be exposed to creators. Only aggregate counts are shown. Minimum threshold (e.g. k-anonymity of 5) before the metric is surfaced.
