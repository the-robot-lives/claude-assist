---
id: US-477
title: "Browse the Swipe-to-Match lane"
slug: swipe-to-match-lane
personas: [P-003, P-004]
epic: "Feed & Ranking"
priority: should-have
complexity: high
tags: [swipe-to-match, lane, connections, matching]
---

# US-477: Browse the Swipe-to-Match Lane

## User Story

**As a** social connector (P-003)
**I want to** access the Swipe-to-Match lane to find people with overlapping interests
**So that** I can expand my mutual network intentionally

## Acceptance Criteria

- **Given** I navigate to the Swipe-to-Match lane
  **When** a candidate profile card appears
  **Then** it shows the user's top 3 channels, degree distance, and shared mutual count

- **Given** I swipe right on a profile
  **When** the other user has also swiped right on me
  **Then** we become mutuals and I receive a notification "You and @user are now moots!"

- **Given** I swipe left on a profile
  **When** the action is recorded
  **Then** that user is not shown again in Swipe-to-Match for 30 days

## Notes
Swipe-to-Match candidates are sourced from 2nd and 3rd-degree connections only.
