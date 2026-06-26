---
id: US-225
title: "Visualize Mutuals Graph"
slug: visualize-mutuals-graph
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: could-have
complexity: high
tags: [graph, visualization]
---

# US-225: Visualize Mutuals Graph

## User Story

**As a** Bridge-Builder (P-001)
**I want to** view an interactive visual map of my mutuals graph with nodes for each user and edges for connections
**So that** I can intuitively explore my network topology and identify bridge connections

## Acceptance Criteria

- **Given** I open the "Graph" view from my network page
  **When** the visualization loads
  **Then** I see my profile at the center, 1st-degree mutuals on the inner ring, and 2nd–4th degree mutuals on outer rings, connected by edges

- **Given** I tap a node in the graph
  **When** a node is selected
  **Then** a mini profile card appears showing the user's name, degree, and an "Add Mutual" or "View Profile" action

- **Given** the graph has more than 200 nodes
  **When** the visualization renders
  **Then** outer-degree nodes are clustered or summarized to maintain performance (max render time 3 s on mid-range device)

## Notes
Must have an accessible non-visual alternative — see US-226. Graph view is decorative/exploratory, not the primary navigation surface.
