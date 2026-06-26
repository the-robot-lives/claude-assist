---
id: US-263
title: "Filter Swipe Candidates by Channel"
slug: filter-swipe-candidates-by-channel
personas: [P-002]
epic: "Swipe-to-Match"
priority: should-have
complexity: medium
tags: [filter, channel, queue-management]
---

# US-263: Filter Swipe Candidates by Channel

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** filter my swipe queue to candidates who are active in a specific channel I follow
**So that** I can find people who participate in the same community spaces I care about

## Acceptance Criteria

- **Given** I follow at least one channel
  **When** I open the filter panel in the swipe lane
  **Then** I can select a channel and the queue shows only candidates active in that channel

- **Given** I apply a channel filter
  **When** a candidate card is shown
  **Then** the card highlights the filtered channel as the primary shared context
