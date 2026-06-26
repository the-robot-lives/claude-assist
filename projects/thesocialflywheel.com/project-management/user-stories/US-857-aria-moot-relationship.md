---
id: US-857
title: "ARIA Description for Moot Relationship Graph Nodes"
slug: aria-moot-relationship
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: high
tags: [screen-reader, aria, moots, graph, wcag-2.2]
---

# US-857: ARIA Description for Moot Relationship Graph Nodes

## User Story

**As a** screen-reader user
**I want to** have graph nodes in the moot-relationship visualisation carry descriptive ARIA labels
**So that** I can understand my social graph without seeing the visual diagram

## Acceptance Criteria

- **Given** the moot graph is open
  **When** the screen reader focuses a node
  **Then** it announces "[Name]: [N]th-degree moot, [M] shared interests"

- **Given** a graph edge is focused
  **When** the screen reader reads it
  **Then** it announces "Connected via [shared channel]"

- **Given** the graph has more than 20 nodes
  **When** the screen reader enters the graph region
  **Then** it first announces "Graph showing [N] connections. Use arrow keys to navigate nodes."

## Notes

Consider providing a text-only table alternative to the SVG graph for screen-reader users, toggled via a visible "Switch to table view" button. This reduces ARIA complexity on SVG elements while offering full data access.
