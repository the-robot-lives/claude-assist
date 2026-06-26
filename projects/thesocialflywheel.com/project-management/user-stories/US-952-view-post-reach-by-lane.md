---
id: US-952
title: "View Post Reach by Lane"
slug: view-post-reach-by-lane
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: medium
tags: [analytics, posts, lanes]
---

# US-952: View Post Reach by Lane

## User Story

**As a** Creator
**I want to** see which distribution lanes (Mutuals, Discovery, Swipe-to-Match) drove impressions for each of my posts
**So that** I can tailor content strategy per lane.

## Acceptance Criteria

- **Given** a published post that appeared in multiple lanes
  **When** I open its analytics
  **Then** impressions are broken out per lane with percentages.

- **Given** a post that only appeared in the Mutuals lane
  **When** viewing lane breakdown
  **Then** only the Mutuals lane is shown with 100%.

## Notes
Lane attribution uses the lane through which the impression was first delivered.
