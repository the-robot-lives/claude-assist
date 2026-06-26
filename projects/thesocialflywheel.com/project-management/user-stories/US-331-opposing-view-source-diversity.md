---
id: US-331
title: "Opposing-View Source Diversity"
slug: opposing-view-source-diversity
personas: [P-005]
epic: "Opposing-Views Lane"
priority: should-have
complexity: high
tags: [opposing-views, diversity, algorithm, feed-quality]
---

# US-331: Opposing-View Source Diversity

## User Story

**As a** debate seeker
**I want to** see opposing-view posts from a variety of different people rather than the same person repeatedly
**So that** my exposure to opposing perspectives is genuinely diverse and not dominated by one voice

## Acceptance Criteria

- **Given** the Opposing-Views Lane is populated
  **When** posts are selected for the lane
  **Then** no single author contributes more than one post per lane render

- **Given** sufficient diverse authors are available
  **When** the lane renders over multiple sessions
  **Then** posts come from at least three distinct authors within any seven-day rolling window

## Notes
If fewer than three qualifying authors exist, the system should surface the best available rather than recycling. Author-cap enforcement happens server-side.
