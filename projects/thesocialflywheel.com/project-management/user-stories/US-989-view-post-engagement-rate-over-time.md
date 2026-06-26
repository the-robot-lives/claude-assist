---
id: US-989
title: "View Post Engagement Rate Over Time"
slug: view-post-engagement-rate-over-time
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: medium
tags: [analytics, posts, engagement, trends]
---

# US-989: View Post Engagement Rate Over Time

## User Story

**As a** Creator
**I want to** see a time-series chart of my posts' engagement rate (reactions plus replies divided by impressions)
**So that** I can track whether the quality and resonance of my content is improving or declining over time.

## Acceptance Criteria

- **Given** an account with at least 5 published posts
  **When** I open the Engagement Rate chart
  **Then** I see a line chart plotting engagement rate per post ordered by publish date, with a 7-day rolling average overlay.

- **Given** the engagement rate chart
  **When** I click a data point
  **Then** a popover shows the specific post title, publish date, raw reaction/reply counts, and impression count for that point.

## Notes
Engagement rate = (reactions + replies) / impressions x 100. Posts with zero impressions are excluded from the chart to avoid division by zero.
