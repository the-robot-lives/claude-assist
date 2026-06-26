---
id: US-339
title: "Opposing Posts from 1st-Degree Mutuals Hidden by Default"
slug: opposing-posts-from-1st-degree-hidden
personas: [P-001]
epic: "Opposing-Views Lane"
priority: could-have
complexity: medium
tags: [opposing-views, mutuals, social-graph, defaults]
---

# US-339: Opposing Posts from 1st-Degree Mutuals Hidden by Default

## User Story

**As a** bridge-builder
**I want to** have posts from my direct mutuals (1st-degree) excluded from the Opposing-Views Lane by default
**So that** the lane surfaces perspectives from outside my existing social circle rather than surfacing disagreements with close connections

## Acceptance Criteria

- **Given** a 1st-degree mutual holds an opposing view on a shared interest
  **When** the lane is populated
  **Then** their posts do not appear in the Opposing-Views Lane (they still appear in the Mutuals lane)

- **Given** the default is active
  **When** I manually enable "include mutuals" in lane settings
  **Then** 1st-degree mutuals' posts become eligible for the Opposing-Views Lane

## Notes
2nd–4th degree connections are eligible by default. This default protects close relationships from feeling adversarial.
