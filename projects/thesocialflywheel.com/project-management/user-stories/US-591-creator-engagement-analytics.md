---
id: US-591
title: "View Engagement Analytics on My Posts"
slug: creator-engagement-analytics
personas: [P-009]
epic: "Reactions & Engagement"
priority: should-have
complexity: high
tags: [creator, analytics, engagement]
---

# US-591: View Engagement Analytics on My Posts

## User Story

**As a** Creator
**I want to** see engagement analytics broken down by reaction type, replies, and reposts over time
**So that** I can understand which content resonates and plan future posts accordingly

## Acceptance Criteria

- **Given** I open My Content dashboard and select a post
  **Then** I see a chart with reaction counts by type, reply count, and repost count over selectable 7 / 30-day windows

- **Given** I filter by a specific reaction type
  **When** I select "Heart"
  **Then** the chart highlights only heart reactions over the selected time period

## Notes
Analytics are visible only to the post author. Not exposed via public API in v1. Data is updated with up to 1-hour latency.
