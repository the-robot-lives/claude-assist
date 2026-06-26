---
id: US-362
title: "Discover New Topics via Degree Graph"
slug: discover-new-topics-via-degree-graph
personas: [P-001]
epic: "Discovery Engine"
priority: should-have
complexity: medium
tags: [discovery, topics, graph]
---

# US-362: Discover New Topics via Degree Graph

## User Story

**As a** Bridge-Builder
**I want to** have the engine surface topics that my 2nd or 3rd-degree mutuals engage with heavily
**So that** I can expand my interest set through the trusted network rather than algorithmic guessing

## Acceptance Criteria

- **Given** my 2nd-degree mutuals are active across a topic I have never engaged with
  **When** that topic reaches a relevance threshold relative to my existing interests
  **Then** the engine introduces one post from that topic into my discovery feed labeled with the degree connection

- **Given** a new topic is surfaced via degree graph
  **When** I provide no signal (no like, no dislike, no dismiss) on repeated exposures
  **Then** the engine reduces frequency of that topic after three unsignaled exposures

## Notes
Topic discovery via graph degree is complementary to adjacency-based topic discovery; both can operate simultaneously.
