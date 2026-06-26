---
id: US-852
title: "Keyboard Navigation in Swipe Deck"
slug: keyboard-nav-swipe
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [keyboard-navigation, swipe, wcag-2.2]
---

# US-852: Keyboard Navigation in Swipe Deck

## User Story

**As a** keyboard-only user
**I want to** navigate the Swipe-to-Match deck with arrow keys and keyboard shortcuts
**So that** I can participate in matching without touch gestures

## Acceptance Criteria

- **Given** the swipe deck is active
  **When** I press Right Arrow
  **Then** the card is accepted and the next card receives focus

- **Given** the swipe deck is active
  **When** I press Left Arrow
  **Then** the card is skipped and the next card receives focus

- **Given** the swipe deck is active
  **When** I press Escape
  **Then** I exit the deck and focus returns to the lane switcher

## Notes

Display a visible keyboard shortcut legend (e.g. "← Skip · → Accept · Esc Exit") above the deck. Ensure card dismissal animations do not block focus reassignment.
