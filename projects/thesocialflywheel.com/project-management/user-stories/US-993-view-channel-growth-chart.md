---
id: US-993
title: "View Channel Growth Chart"
slug: view-channel-growth-chart
personas: [P-007]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: medium
tags: [analytics, moderation, channel, growth]
---

# US-993: View Channel Growth Chart

## User Story

**As a** Channel Moderator
**I want to** see a time-series chart of member joins, leaves, and net growth for my channel
**So that** I can track whether moderation actions or content changes are affecting membership

## Acceptance Criteria

- **Given** a channel I moderate
  **When** I open the Channel Growth chart
  **Then** I see a line chart with three series: joins, leaves, and net growth — defaulting to a 30-day view at daily granularity

- **Given** a day with unusually high leaves (more than 2 standard deviations above average)
  **When** I hover that date on the chart
  **Then** a tooltip flags it as an anomaly and links to the moderation log for that day so I can investigate

## Notes
Chart date range options: 7 days, 30 days, 90 days, 1 year. Data is available from channel creation date onward.
