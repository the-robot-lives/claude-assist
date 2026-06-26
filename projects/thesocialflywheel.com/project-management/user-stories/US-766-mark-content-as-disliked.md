---
id: US-766
title: "Mark Content as Disliked"
slug: mark-content-as-disliked
personas: [P-006]
epic: "Settings & Preferences"
priority: should-have
complexity: low
tags: [dislikes, feedback, algorithm, content-preferences]
---

# US-766: Mark Content as Disliked

## User Story

**As a** quiet consumer
**I want to** mark a post as disliked directly from the feed
**So that** the algorithm learns what content I want to see less of without requiring me to navigate to settings.

## Acceptance Criteria

- **Given** I am viewing any post
  **When** I long-press and select "Show less like this"
  **Then** the action is logged, a brief confirmation toast appears, and similar posts decrease in frequency.

## Notes
Dislike signals are distinct from block/report actions and do not notify the post author.
