---
id: US-255
title: "Skip Card Without Deciding"
slug: skip-card-without-deciding
personas: [P-008]
epic: "Swipe-to-Match"
priority: should-have
complexity: low
tags: [swipe-gesture, skip, accessibility]
---

# US-255: Skip Card Without Deciding

## User Story

**As an** Accessibility-First user (P-008)
**I want to** skip a card without committing to a left or right swipe
**So that** I can return to it later without affecting my daily limit or suppression window

## Acceptance Criteria

- **Given** I am viewing a swipe card
  **When** I tap or keyboard-activate the "Skip" action
  **Then** the card moves to the end of my current session queue and my swipe count is not decremented

- **Given** I have skipped a card
  **When** I reach the end of the queue
  **Then** skipped cards are re-presented before the session ends
