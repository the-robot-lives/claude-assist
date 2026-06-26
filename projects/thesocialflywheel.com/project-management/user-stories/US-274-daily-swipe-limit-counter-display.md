---
id: US-274
title: "Daily Swipe Limit Counter Display"
slug: daily-swipe-limit-counter-display
personas: [P-006]
epic: "Swipe-to-Match"
priority: should-have
complexity: low
tags: [daily-limit, counter, swipe-ui]
---

# US-274: Daily Swipe Limit Counter Display

## User Story

**As a** Quiet Consumer (P-006)
**I want to** see how many swipes I have remaining today at a glance
**So that** I can decide when to use my right-swipes intentionally

## Acceptance Criteria

- **Given** I open the swipe lane
  **When** the lane renders
  **Then** a subtle counter in the corner shows "X / Y swipes used today"

- **Given** I have used all my daily swipes
  **When** I view the counter
  **Then** it shows "0 remaining" in a distinct color and includes the reset time
