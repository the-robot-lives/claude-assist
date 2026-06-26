---
id: US-224
title: "Graph Stats by Degree"
slug: graph-stats-by-degree
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: could-have
complexity: low
tags: [graph, stats, profile]
---

# US-224: Graph Stats by Degree

## User Story

**As a** Bridge-Builder (P-001)
**I want to** see a breakdown of my total mutuals by degree on my profile or a dedicated stats page
**So that** I can understand the shape of my network at a glance

## Acceptance Criteria

- **Given** I navigate to my profile or "My Network" section
  **When** the page loads
  **Then** I see counts for: 1st-degree mutuals, users reachable at 2nd degree, 3rd degree, and 4th degree

- **Given** counts are displayed
  **When** I tap a degree count
  **Then** I am taken to a filtered list of users at that degree, sorted by recency of connection
