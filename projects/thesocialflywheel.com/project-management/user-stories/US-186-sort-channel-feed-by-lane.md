---
id: US-186
title: "Sort Channel Feed by Lane Type"
slug: sort-channel-feed-by-lane
personas: [P-006]
epic: "Interest Channels"
priority: should-have
complexity: low
tags: [channels, feed, lanes, filter, ux]
---

# US-186: Sort Channel Feed by Lane Type

## User Story

**As a** Quiet Consumer
**I want to** switch the channel feed view between Mutuals, Swipe-to-Match, and Opposing-Views lanes using a simple tab or toggle
**So that** I can control which type of content I consume without having to navigate to separate pages

## Acceptance Criteria

- **Given** I am inside a channel
  **When** I tap the lane selector tab (Mutuals / Swipe / Opposing)
  **Then** the feed immediately refreshes to show only posts from the selected lane type

- **Given** I switch lanes
  **When** I return to the channel later in the same session
  **Then** the feed remembers which lane I last selected for that channel

## Notes
The default lane when first entering a channel (or after a fresh session) is Mutuals. Lane tab labels should include a post count badge or "new" dot to signal unread content in each lane.
