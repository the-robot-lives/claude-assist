---
id: US-996
title: "Lane-Specific Engagement Analytics"
slug: lane-specific-engagement-analytics
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: medium
tags: [analytics, lanes, engagement, posts]
---

# US-996: Lane-Specific Engagement Analytics

## User Story

**As a** Creator
**I want to** compare engagement rates my posts receive across each distribution lane (Mutuals, Discovery, Swipe-to-Match)
**So that** I can optimize my posting strategy for the lanes where my content performs best

## Acceptance Criteria

- **Given** an account with posts distributed across at least 2 lanes
  **When** I open Lane Engagement Analytics
  **Then** I see a comparison chart with avg engagement rate per lane for the past 30 days

- **Given** the lane comparison chart
  **When** I drill into a specific lane
  **Then** I see a list of my posts that appeared in that lane with their individual engagement rates

## Notes
Swipe-to-Match engagement counts only reactions and profile visits, not replies, as the lane format does not support direct replies.
