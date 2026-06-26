---
id: US-389
title: "Discovery Items Hide Viral Engagement Counts"
slug: discovery-items-hide-viral-engagement-counts
personas: [P-006]
epic: "Discovery Engine"
priority: could-have
complexity: low
tags: [discovery, ux, wellbeing]
---

# US-389: Discovery Items Hide Viral Engagement Counts

## User Story

**As a** Quiet Consumer
**I want to** have engagement counts (likes, reposts, view counts) hidden on discovery items by default
**So that** I evaluate content on its merit rather than its viral status

## Acceptance Criteria

- **Given** a discovery item is rendered in my feed
  **When** I view the card in its default state
  **Then** like counts, repost counts, and view counts are not displayed

- **Given** I want to see engagement counts on a discovery item
  **When** I tap the "Show counts" option on the card
  **Then** the engagement counts are revealed for that individual card only

## Notes
This setting applies only to discovery items; regular feed posts follow the user's normal engagement count visibility preference.
