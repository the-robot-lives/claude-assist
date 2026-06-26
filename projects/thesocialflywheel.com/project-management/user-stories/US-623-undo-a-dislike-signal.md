---
id: US-623
title: "Undo a Dislike Signal"
slug: undo-a-dislike-signal
personas: [P-002]
epic: "Safety: Blocking & Exclusions"
priority: could-have
complexity: low
tags: [safety, discovery, dislike]
---

# US-623: Undo a Dislike Signal

## User Story

**As a** niche enthusiast
**I want to** undo a dislike signal I applied to an interest tag
**So that** my Discovery feed returns to surfacing that topic if my interests have changed

## Acceptance Criteria

- **Given** tag #StreetPhotography appears in my Discovery dislikes list
  **When** I select "Remove dislike" next to it
  **Then** the signal is cleared and the recommendation engine re-evaluates that tag

- **Given** the dislike is removed
  **When** Discovery refreshes
  **Then** posts tagged #StreetPhotography may appear again based on graph relevance

## Notes
Undo is instant but feed repopulation may take one refresh cycle.
