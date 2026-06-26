---
id: US-990
title: "Top Performing Posts Summary"
slug: top-performing-posts-summary
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: medium
tags: [analytics, posts, performance, summary]
---

# US-990: Top Performing Posts Summary

## User Story

**As a** Creator
**I want to** see a ranked list of my top 10 posts by reach, engagement rate, and propagation depth
**So that** I can understand what content resonates most and replicate that success.

## Acceptance Criteria

- **Given** an account with at least 1 published post
  **When** I open the Top Posts view
  **Then** I see the top 10 posts sortable by: total reach, engagement rate, and maximum degree reached — with one-click switching between sort modes.

- **Given** the top posts list
  **When** I click a post entry
  **Then** I am taken directly to that post's detailed analytics panel without leaving the analytics section.

## Notes
Time range defaults to the past 30 days with options for 7 days, 90 days, and all-time. Pinned posts and posts boosted by the platform are labeled to contextualize their performance.
