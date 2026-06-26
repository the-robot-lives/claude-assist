---
id: US-292
title: "Swipe Lane Empty State"
slug: swipe-lane-empty-state
personas: [P-006]
epic: "Swipe-to-Match"
priority: must-have
complexity: low
tags: [empty-state, swipe-ui, discovery]
---

# US-292: Swipe Lane Empty State

## User Story

**As a** Quiet Consumer (P-006)
**I want to** see a helpful message when there are no more swipe candidates
**So that** I know the queue is exhausted rather than assuming the app is broken

## Acceptance Criteria

- **Given** the matching algorithm has no more candidates for me today
  **When** I reach the end of the swipe queue
  **Then** I see an empty-state message explaining why (e.g., "You've seen everyone sharing your interests today") with a suggestion to add more interests

- **Given** the empty state is shown
  **When** I tap "Add interests"
  **Then** I am taken to my interest settings with the swipe lane accessible via the back button
