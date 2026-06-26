---
id: US-913
title: "Degree-Traversal Hard Limits to Prevent Graph Storms"
slug: degree-traversal-limits
personas: [P-001]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: high
tags: [graph, traversal, rate-limiting, scale, degrees]
---

# US-913: Degree-Traversal Hard Limits to Prevent Graph Storms

## User Story

**As a** bridge-builder with connections spanning many communities
**I want to** have Discovery feed results appear quickly
**So that** the server-side graph traversal required for 3rd and 4th-degree discovery does not slow down the entire platform

## Acceptance Criteria

- **Given** a Discovery feed request requires 4th-degree traversal
  **When** the query is issued
  **Then** traversal is hard-capped at 10,000 nodes visited and returns partial results if the cap is hit

- **Given** the traversal cap is reached
  **When** results are returned
  **Then** the response includes a pagination cursor so subsequent requests continue from where traversal stopped

## Notes
Implement traversal cap at the graph query layer, not the application layer. Log cap-hit events to detect users who consistently hit limits (candidates for pre-computation).
