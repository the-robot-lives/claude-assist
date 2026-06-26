---
id: US-369
title: "Degree of Connection Shown on Discovery Card"
slug: degree-of-connection-shown-on-discovery-card
personas: [P-001]
epic: "Discovery Engine"
priority: should-have
complexity: low
tags: [discovery, graph, transparency]
---

# US-369: Degree of Connection Shown on Discovery Card

## User Story

**As a** Bridge-Builder
**I want to** see the degree of connection between me and the author of a discovery item
**So that** I can gauge how closely the content is related to my existing trusted network

## Acceptance Criteria

- **Given** a discovery item appears in my feed
  **When** I view the card
  **Then** a degree indicator (e.g., "3rd-degree mutual") is displayed near the author byline

- **Given** the author is a 1st-degree mutual
  **When** the discovery engine surfaces their content as discovery
  **Then** the card still shows the degree label for consistency, displaying "1st-degree mutual"

## Notes
Degree is computed at feed generation time and cached with the card; it does not update in real time if the graph changes.
