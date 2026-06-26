---
id: US-279
title: "Not-Interested Feedback Improves Queue"
slug: not-interested-feedback-improves-queue
personas: [P-005]
epic: "Swipe-to-Match"
priority: could-have
complexity: high
tags: [feedback, ranking, personalization, left-swipe]
---

# US-279: Not-Interested Feedback Improves Queue

## User Story

**As a** Debate Seeker (P-005)
**I want to** have my left-swipe patterns inform the matching algorithm over time
**So that** my swipe queue progressively surfaces candidates I am more likely to connect with

## Acceptance Criteria

- **Given** I have left-swiped at least 20 candidates
  **When** my next session begins
  **Then** the algorithm down-ranks candidates whose interest profiles are similar to my passed candidates

- **Given** I consistently pass on candidates from a specific interest category
  **When** I have passed 10 or more such candidates
  **Then** the system prompts me asking if I want to remove that interest from my match criteria
