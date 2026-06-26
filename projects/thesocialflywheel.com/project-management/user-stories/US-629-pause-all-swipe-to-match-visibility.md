---
id: US-629
title: "Pause All Swipe-to-Match Visibility"
slug: pause-all-swipe-to-match-visibility
personas: [P-006]
epic: "Safety: Blocking & Exclusions"
priority: could-have
complexity: low
tags: [safety, matching, privacy]
---

# US-629: Pause All Swipe-to-Match Visibility

## User Story

**As a** quiet consumer
**I want to** temporarily pause my visibility in the Swipe-to-Match lane
**So that** I can take a break from matching without permanently changing my settings

## Acceptance Criteria

- **Given** I toggle "Pause matching" in Privacy Settings
  **When** any user opens Swipe-to-Match
  **Then** my profile does not appear in any deck regardless of degree

- **Given** matching is paused
  **When** I toggle it back on
  **Then** my profile is immediately eligible to appear again at the degree I had set

## Notes
Pause is indefinite until manually lifted; no expiry timer needed for this story.
