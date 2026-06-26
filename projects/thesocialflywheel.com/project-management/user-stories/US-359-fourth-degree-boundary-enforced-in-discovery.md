---
id: US-359
title: "Fourth-Degree Boundary Enforced in Discovery"
slug: fourth-degree-boundary-enforced-in-discovery
personas: [P-001]
epic: "Discovery Engine"
priority: must-have
complexity: high
tags: [discovery, graph, safety]
---

# US-359: Fourth-Degree Boundary Enforced in Discovery

## User Story

**As a** Bridge-Builder
**I want to** have discovery content sourced only from within my 4th-degree mutuals network
**So that** I am never exposed to content from complete strangers outside my connected graph

## Acceptance Criteria

- **Given** the discovery engine is selecting content for my feed
  **When** it evaluates a candidate item
  **Then** it verifies the author is reachable within ≤4 mutual hops and rejects the item if not

- **Given** my mutuals network has fewer than a threshold number of reachable accounts at 4th degree
  **When** the engine cannot find enough items within 4 degrees
  **Then** it surfaces fewer items rather than crossing the boundary to unconnected accounts

## Notes
The 4th-degree boundary is a hard constraint, not a soft preference. No fallback to 5th degree or beyond.
