---
id: US-368
title: "Adjacent Interest Path Explained in Discovery"
slug: adjacent-interest-path-explained-in-discovery
personas: [P-001]
epic: "Discovery Engine"
priority: should-have
complexity: medium
tags: [discovery, transparency, graph]
---

# US-368: Adjacent Interest Path Explained in Discovery

## User Story

**As a** Bridge-Builder
**I want to** see a brief explanation of which of my stated interests led to a discovery item being surfaced
**So that** I can understand the conceptual path between my current interests and the new content

## Acceptance Criteria

- **Given** a discovery item is surfaced because it is adjacent to one of my declared interests
  **When** I expand the surfacing reason on the card
  **Then** I see a label such as "Because you follow Topology → adjacent to Analysis"

- **Given** the adjacent interest path involves multiple hops between interest clusters
  **When** the explanation is displayed
  **Then** it shows at most two intermediate steps to keep the explanation brief

## Notes
The explanation is shown in an expandable section to avoid cluttering the default card view.
