---
id: US-448
title: "See estimated reach before publishing"
slug: audience-reach-estimate
personas: [P-009]
epic: "Posting & Content Creation"
priority: could-have
complexity: high
tags: [reach, analytics, audience, preview]
---

# US-448: See Estimated Reach Before Publishing

## User Story

**As a** Creator
**I want to** see an estimated reach count broken down by degree and channel before I publish
**So that** I can make an informed decision about whether to adjust my tags or audience settings

## Acceptance Criteria

- **Given** I have composed a post with tags and an audience setting
  **When** I tap "Estimate Reach"
  **Then** I see a breakdown: direct mutuals (exact count), 2nd-degree estimate, channel subscribers

- **Given** the reach estimate is displayed
  **When** I change the audience setting or tags
  **Then** the estimate refreshes to reflect the new configuration

## Notes
Counts at outer degrees are ranges, not exact numbers, to preserve privacy of non-mutual users.
