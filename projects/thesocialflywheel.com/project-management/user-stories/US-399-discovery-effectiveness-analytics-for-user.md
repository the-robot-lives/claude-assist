---
id: US-399
title: "Discovery Effectiveness Analytics for User"
slug: discovery-effectiveness-analytics-for-user
personas: [P-002]
epic: "Discovery Engine"
priority: could-have
complexity: medium
tags: [discovery, analytics, transparency]
---

# US-399: Discovery Effectiveness Analytics for User

## User Story

**As a** Niche Enthusiast
**I want to** view a personal analytics page showing how discovery has expanded my interest graph over time
**So that** I can see concrete evidence of what the engine has introduced me to and whether it is working for me

## Acceptance Criteria

- **Given** I navigate to Discovery Analytics in my settings
  **When** the page loads
  **Then** I see charts showing: number of new channels joined via discovery, number of new mutuals connected through discovery introductions, and topic engagement rate by rotation period

- **Given** the analytics page is displayed
  **When** I select a specific rotation period
  **Then** the charts filter to show only metrics from that period's active topic clusters

## Notes
Analytics are computed from existing engagement event data and should not require additional tracking instrumentation beyond what is already collected for the discovery engine.
