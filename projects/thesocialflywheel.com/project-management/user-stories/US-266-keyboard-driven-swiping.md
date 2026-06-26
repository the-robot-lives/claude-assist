---
id: US-266
title: "Keyboard-Driven Swiping"
slug: keyboard-driven-swiping
personas: [P-008]
epic: "Swipe-to-Match"
priority: must-have
complexity: medium
tags: [accessibility, keyboard, a11y, swipe-gesture]
---

# US-266: Keyboard-Driven Swiping

## User Story

**As an** Accessibility-First user (P-008)
**I want to** perform all swipe actions using only my keyboard
**So that** I can fully participate in the Swipe-to-Match lane without needing touch or mouse input

## Acceptance Criteria

- **Given** I am focused on a swipe card via keyboard navigation
  **When** I press the right arrow key or L key
  **Then** a right-swipe (express interest) is registered, equivalent to a touch swipe-right

- **Given** I am focused on a swipe card
  **When** I press the left arrow key or J key
  **Then** a left-swipe (pass) is registered

- **Given** I am focused on a swipe card
  **When** I press S or Enter on the Skip button
  **Then** the card is skipped without affecting my swipe count

## Notes
Key bindings must be documented in the keyboard shortcut legend (see US-291).
