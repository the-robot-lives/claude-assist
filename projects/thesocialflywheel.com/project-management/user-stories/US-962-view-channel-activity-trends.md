---
id: US-962
title: "View Channel Activity Trends"
slug: view-channel-activity-trends
personas: [P-007]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: medium
tags: [analytics, moderation, channel, trends]
---

# US-962: View Channel Activity Trends

## User Story

**As a** Channel Moderator
**I want to** see a time-series chart of posts, replies, and reactions in my channel
**So that** I can identify peak activity periods and content patterns over time

## Acceptance Criteria

- **Given** a channel with activity history
  **When** I open the Activity Trends view
  **Then** I see stacked area charts for posts, replies, and reactions with a 30-day default window

- **Given** the Activity Trends chart
  **When** I change the date range to the past 90 days
  **Then** the chart updates to show 90 days of data at daily granularity

## Notes
Reactions are broken out by type (agree, heart, laugh, etc.) in a secondary chart below the main activity chart.
