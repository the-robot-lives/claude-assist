---
id: US-335
title: "Opposing-View Posts Stay Out of the Main Feed"
slug: opposing-posts-not-in-main-feed
personas: [P-006]
epic: "Opposing-Views Lane"
priority: must-have
complexity: low
tags: [opposing-views, main-feed, isolation, feed-design]
---

# US-335: Opposing-View Posts Stay Out of the Main Feed

## User Story

**As a** quiet consumer
**I want to** be certain that opposing-view posts only appear inside the designated lane and never in my main feed or Mutuals lane
**So that** my main feed remains a comfortable space with content from people whose views I have chosen to follow

## Acceptance Criteria

- **Given** a post qualifies for the Opposing-Views Lane
  **When** the main feed and Mutuals lane are rendered
  **Then** that post does not appear in either of those contexts

- **Given** I disable the Opposing-Views Lane
  **When** the main feed renders
  **Then** no opposing-view posts surface anywhere in my feed

## Notes
Isolation is enforced at the query layer, not the render layer, to prevent race conditions where a post briefly appears in both contexts.
