---
id: US-862
title: "Focus Restoration After Swipe Card Dismiss"
slug: focus-restoration-swipe
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [focus-management, swipe, wcag-2.2]
---

# US-862: Focus Restoration After Swipe Card Dismiss

## User Story

**As a** keyboard-only user
**I want to** have focus automatically move to the next swipe card after I dismiss the current one
**So that** I can continue swiping without hunting for focus

## Acceptance Criteria

- **Given** I dismiss a swipe card via keyboard
  **When** the next card loads
  **Then** focus moves immediately to that card's primary action button

- **Given** I reach the end of the swipe deck
  **When** the deck is empty
  **Then** focus moves to a "You're all caught up" message with a "Back to feed" link

- **Given** a network delay causes the next card to load slowly
  **When** the card finally renders
  **Then** focus is placed on it and a polite announcement confirms "New card loaded."

## Notes

Use a loading placeholder card with aria-busy="true" during network fetch so screen readers know content is pending. Move focus imperatively once the real card mounts.
