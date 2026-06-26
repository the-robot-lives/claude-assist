---
id: US-991
title: "Compare Performance Across Posts"
slug: compare-performance-across-posts
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: medium
tags: [analytics, posts, comparison, performance]
---

# US-991: Compare Performance Across Posts

## User Story

**As a** Creator
**I want to** select up to 5 of my posts and view their key metrics side by side
**So that** I can directly compare what worked and what did not across different content formats or topics

## Acceptance Criteria

- **Given** the Posts analytics list
  **When** I select 2–5 posts and click "Compare"
  **Then** I see a comparison table with columns per post and rows for: impressions, engagement rate, max degree reached, and reaction breakdown

- **Given** a comparison table with 5 posts selected
  **When** I try to add a 6th post
  **Then** a tooltip explains the 5-post maximum and the checkbox is disabled

## Notes
Comparison view is exportable as CSV. Each column header links to the individual post's full analytics detail.
