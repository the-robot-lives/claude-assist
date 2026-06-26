---
id: US-254
title: "Swipe Left to Pass"
slug: swipe-left-to-pass
personas: [P-001]
epic: "Swipe-to-Match"
priority: must-have
complexity: low
tags: [swipe-gesture, pass, core-flow]
---

# US-254: Swipe Left to Pass

## User Story

**As a** Bridge-Builder (P-001)
**I want to** swipe left on a candidate I am not interested in connecting with
**So that** they are removed from my queue and my signal helps refine future suggestions

## Acceptance Criteria

- **Given** I am viewing a swipe card
  **When** I swipe the card to the left (or tap the X button)
  **Then** the card is dismissed, no interest is recorded, and the next card appears

- **Given** I have swiped left on a candidate
  **When** the same candidate would otherwise re-enter my queue
  **Then** they are suppressed for at least 30 days

## Notes
A left-swipe does not notify the candidate.
