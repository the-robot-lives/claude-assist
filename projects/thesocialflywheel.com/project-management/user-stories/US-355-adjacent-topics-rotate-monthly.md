---
id: US-355
title: "Adjacent Topics Rotate Monthly"
slug: adjacent-topics-rotate-monthly
personas: [P-001]
epic: "Discovery Engine"
priority: must-have
complexity: high
tags: [discovery, rotation]
---

# US-355: Adjacent Topics Rotate Monthly

## User Story

**As a** Bridge-Builder
**I want to** have the set of adjacent topics surfaced in discovery rotate each month
**So that** I am exposed to a progressively broader range of content over time rather than the same cluster indefinitely

## Acceptance Criteria

- **Given** a set of adjacent topics was active during the current calendar month
  **When** the monthly rotation event fires at month end
  **Then** a new set of adjacent topics is selected based on the topology of my interest graph

- **Given** the monthly rotation completes
  **When** I view my discovery feed the next day
  **Then** I see content from the newly activated adjacent topic set, not the previous month's set

- **Given** I have liked topics from the previous rotation
  **When** the next rotation is computed
  **Then** positively signaled topics have a higher probability of returning in a future rotation cycle

## Notes
Rotation scheduling must account for user timezone to avoid mid-day switches disrupting the feed experience.
