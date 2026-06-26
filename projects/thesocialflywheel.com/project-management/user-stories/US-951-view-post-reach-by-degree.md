---
id: US-951
title: "View Post Reach by Degree"
slug: view-post-reach-by-degree
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: medium
tags: [analytics, posts, reach]
---

# US-951: View Post Reach by Degree

## User Story

**As a** Creator
**I want to** see how many unique accounts my post reached at each degree (1st through 4th) of my mutuals web
**So that** I understand how far my content propagated beyond my direct connections.

## Acceptance Criteria

- **Given** a published post
  **When** I open its analytics panel
  **Then** I see impression counts broken out by 1st, 2nd, 3rd, and 4th degree separately.

- **Given** a post with zero 3rd-degree reach
  **When** viewing degree breakdown
  **Then** the 3rd-degree row shows 0 and is not hidden.

## Notes
Counts are unique accounts per degree; an account that appears at multiple degrees is counted at the closest degree only.
