---
id: US-260
title: "Undo Last Swipe"
slug: undo-last-swipe
personas: [P-003]
epic: "Swipe-to-Match"
priority: should-have
complexity: medium
tags: [undo, swipe-gesture, error-recovery]
---

# US-260: Undo Last Swipe

## User Story

**As a** Social Connector (P-003)
**I want to** undo my most recent swipe
**So that** I can correct an accidental left or right swipe before the decision takes effect

## Acceptance Criteria

- **Given** I have just swiped on a card
  **When** I tap the "Undo" button that appears briefly after the swipe
  **Then** the previous card is restored and the swipe action is cancelled

- **Given** the undo window has elapsed (5 seconds)
  **When** I tap "Undo"
  **Then** the button is gone and the swipe stands as recorded

## Notes
Undo is limited to one action per swipe session to prevent abuse.
