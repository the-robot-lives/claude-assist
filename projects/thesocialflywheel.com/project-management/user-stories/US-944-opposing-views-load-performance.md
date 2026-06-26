---
id: US-944
title: "Fast Loading of Opposing-Views Feed Lane"
slug: opposing-views-load-performance
personas: [P-005]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: high
tags: [opposing-views, feed, performance, graph, ranking]
---

# US-944: Fast Loading of Opposing-Views Feed Lane

## User Story

**As a** debate seeker who relies on the Opposing-Views lane for constructive disagreement
**I want to** have the Opposing-Views feed load as quickly as the Mutuals feed
**So that** the extra computation required for opinion-divergence ranking doesn't make this lane feel broken

## Acceptance Criteria

- **Given** I switch to the Opposing-Views lane
  **When** the lane renders
  **Then** the first 20 items appear within 3 seconds even if full divergence-score computation takes longer

- **Given** full divergence scores are still computing
  **When** preliminary results are available
  **Then** a provisional set of posts is shown immediately and silently updated as scores finalize in the background

## Notes
Pre-warm Opposing-Views candidates in background on session start so they are ready when the user switches lanes. Use probabilistic divergence scoring for speed; exact scoring only on demand.
