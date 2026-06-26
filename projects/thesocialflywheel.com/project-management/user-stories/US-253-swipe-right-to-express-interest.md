---
id: US-253
title: "Swipe Right to Express Interest"
slug: swipe-right-to-express-interest
personas: [P-003]
epic: "Swipe-to-Match"
priority: must-have
complexity: medium
tags: [swipe-gesture, interest, core-flow]
---

# US-253: Swipe Right to Express Interest

## User Story

**As a** Social Connector (P-003)
**I want to** swipe right on a candidate's card
**So that** I can express interest and potentially become mutuals if they reciprocate

## Acceptance Criteria

- **Given** I am viewing a swipe card
  **When** I swipe the card to the right (or tap the heart button)
  **Then** an interest signal is recorded and the next card slides into view

- **Given** I have swiped right
  **When** the action completes
  **Then** I am NOT yet able to see the candidate's posts (one-way visibility only activates from their side)

- **Given** I have reached my daily swipe limit
  **When** I attempt to swipe right
  **Then** I see a friendly message showing when my limit resets and no interest is recorded
