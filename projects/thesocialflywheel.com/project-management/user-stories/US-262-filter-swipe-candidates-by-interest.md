---
id: US-262
title: "Filter Swipe Candidates by Interest"
slug: filter-swipe-candidates-by-interest
personas: [P-002]
epic: "Swipe-to-Match"
priority: should-have
complexity: medium
tags: [filter, interest-matching, queue-management]
---

# US-262: Filter Swipe Candidates by Interest

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** filter my swipe queue to show only candidates who share a specific interest
**So that** I can focus on the niche that matters most to me in a given session

## Acceptance Criteria

- **Given** I have multiple interests set on my profile
  **When** I open the filter panel in the swipe lane
  **Then** I can select one or more interests to restrict the candidate pool

- **Given** I have applied an interest filter
  **When** the filtered queue is empty
  **Then** I see an empty-state message with a prompt to broaden my filter
