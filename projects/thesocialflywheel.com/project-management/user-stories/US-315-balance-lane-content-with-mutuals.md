---
id: US-315
title: "Balance Opposing-View Content with Mutual Feed"
slug: balance-lane-content-with-mutuals
personas: [P-005]
epic: "Opposing-Views Lane"
priority: should-have
complexity: medium
tags: [opposing-views, ratio, mutuals, feed-balance]
---

# US-315: Balance Opposing-View Content with Mutual Feed

## User Story

**As a** debate seeker
**I want to** see opposing-view content integrated at a bounded ratio relative to my mutuals content
**So that** my feed remains primarily familiar and does not feel overtaken by disagreement

## Acceptance Criteria

- **Given** my feed is rendering
  **When** the system selects posts for the Opposing-Views Lane
  **Then** the lane never exceeds the system-defined maximum ratio of total feed content

- **Given** insufficient opposing-view content exists to fill the ratio
  **When** the lane is rendered
  **Then** the remaining slots are left empty rather than recycling the same opposing posts

## Notes
The ratio cap is enforced server-side. The front-end should not attempt to pad or re-rank opposing posts to hit a minimum.
