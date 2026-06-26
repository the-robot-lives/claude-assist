---
id: US-964
title: "Discover Rising Interest Trends"
slug: discover-rising-interest-trends
personas: [P-001]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: high
tags: [analytics, trends, interests, discovery]
---

# US-964: Discover Rising Interest Trends

## User Story

**As a** Bridge-Builder
**I want to** see which interest channels are gaining traction within my degree graph
**So that** I can discover emerging conversations and join them early to build bridges across communities

## Acceptance Criteria

- **Given** my mutuals graph
  **When** I open Interest Trends
  **Then** I see a ranked list of interest channels with the highest week-over-week growth in engagement among my 1st–3rd degree connections

- **Given** an interest channel I already subscribe to
  **When** it appears in the Trending list
  **Then** it is visually marked as "already following" so I can focus on new discoveries

## Notes
Trend scoring weights recency (last 7 days) more heavily than older spikes. Channels with fewer than 100 total posts are excluded to reduce noise.
