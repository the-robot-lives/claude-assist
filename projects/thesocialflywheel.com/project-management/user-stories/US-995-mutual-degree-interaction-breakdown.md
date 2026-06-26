---
id: US-995
title: "Mutual Degree Interaction Breakdown"
slug: mutual-degree-interaction-breakdown
personas: [P-001]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: medium
tags: [analytics, mutuals, degrees, engagement]
---

# US-995: Mutual Degree Interaction Breakdown

## User Story

**As a** Bridge-Builder
**I want to** see how many reactions, replies, and reposts I receive from each degree of my mutuals graph
**So that** I can understand whether I am successfully engaging beyond my immediate circle

## Acceptance Criteria

- **Given** my account
  **When** I open the Degree Interaction Breakdown
  **Then** I see a stacked bar chart showing reactions, replies, and reposts from 1st, 2nd, 3rd, and 4th degree connections over the selected time period

- **Given** the breakdown chart
  **When** I change the date range to the past 90 days
  **Then** the chart updates to reflect interactions across that period with the same degree segmentation

## Notes
Interactions are attributed to the degree of the interacting account at the time of the interaction. An account that moved from 2nd to 1st degree is counted at 1st degree going forward.
