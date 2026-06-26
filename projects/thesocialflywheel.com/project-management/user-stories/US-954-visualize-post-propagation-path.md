---
id: US-954
title: "Visualize Post Propagation Path"
slug: visualize-post-propagation-path
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: high
tags: [analytics, posts, propagation, visualization]
---

# US-954: Visualize Post Propagation Path

## User Story

**As a** Creator
**I want to** see an interactive graph showing how my post hopped through the mutuals web degree by degree
**So that** I can understand the actual social paths my content traveled.

## Acceptance Criteria

- **Given** a post with multi-degree reach
  **When** I open the propagation view
  **Then** I see a node-link diagram with nodes representing degree rings and edges showing share/repost paths.

- **Given** the propagation graph
  **When** I click a degree-ring node
  **Then** I see aggregate stats (impressions, reactions) for that ring without individual user identities.

## Notes
Individual identities are never shown; nodes represent cohorts. Graph is generated asynchronously and may take up to 60 seconds for high-reach posts.
