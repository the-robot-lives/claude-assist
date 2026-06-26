---
id: US-273
title: "Swipe Card Animation Feedback"
slug: swipe-card-animation-feedback
personas: [P-003]
epic: "Swipe-to-Match"
priority: should-have
complexity: low
tags: [animation, feedback, swipe-ui, reduced-motion]
---

# US-273: Swipe Card Animation Feedback

## User Story

**As a** Social Connector (P-003)
**I want to** see a directional animation when I swipe a card
**So that** I receive immediate visual confirmation that my action was registered

## Acceptance Criteria

- **Given** I drag a card to the right
  **When** I pass the threshold
  **Then** the card tilts right, a green "heart" overlay appears, and the card flies off screen to the right

- **Given** the user's OS has "Reduce Motion" enabled
  **When** a swipe action is performed
  **Then** the card disappears instantly without any fly-off animation while still confirming the action via color change
