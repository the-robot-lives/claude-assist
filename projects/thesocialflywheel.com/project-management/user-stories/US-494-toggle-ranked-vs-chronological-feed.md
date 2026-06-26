---
id: US-494
title: "Toggle between ranked and chronological feed views"
slug: toggle-ranked-vs-chronological-feed
personas: [P-003, P-009]
epic: "Feed & Ranking"
priority: should-have
complexity: low
tags: [sort, ranked, chronological, toggle, feed-control]
---

# US-494: Toggle Between Ranked and Chronological Feed Views

## User Story

**As a** creator (P-009)
**I want to** switch between the ranked (algorithm) feed and a pure chronological feed with a single tap
**So that** I can quickly check what's newest without reconfiguring sort settings

## Acceptance Criteria

- **Given** I am on the home feed in ranked mode
  **When** I tap the clock icon in the feed header
  **Then** the feed immediately re-sorts to reverse-chronological order and the icon highlights to indicate the active mode

- **Given** chronological mode is active
  **When** I tap the icon again
  **Then** the feed returns to ranked mode

- **Given** I switch modes
  **When** the feed re-renders
  **Then** my current scroll position resets to the top of the newly sorted list

## Notes
This toggle is a shortcut to the same "Newest first" option in the full sort menu (US-459).
